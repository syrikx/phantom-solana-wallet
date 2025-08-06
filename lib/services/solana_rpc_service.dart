import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class SolanaRpcService {
  static const String mainnetRpcUrl = 'https://api.mainnet-beta.solana.com';
  static const String devnetRpcUrl = 'https://api.devnet.solana.com';
  
  // Alternative RPC endpoints for fallback
  static const List<String> fallbackRpcUrls = [
    'https://solana-api.projectserum.com',
    'https://rpc.ankr.com/solana',
    'https://solana.public-rpc.com',
  ];
  
  String rpcUrl;
  final http.Client _client = http.Client();
  int _currentFallbackIndex = 0;
  
  SolanaRpcService({this.rpcUrl = mainnetRpcUrl});
  
  // Generate unique request ID
  String _generateRequestId() {
    final random = Random();
    return random.nextInt(999999).toString();
  }
  
  // Validate Solana public key format
  bool _isValidPublicKey(String publicKey) {
    if (publicKey.length < 32 || publicKey.length > 44) {
      return false;
    }
    
    // Check for valid base58 characters
    final base58Chars = RegExp(r'^[1-9A-HJ-NP-Za-km-z]+$');
    return base58Chars.hasMatch(publicKey);
  }
  
  // Try fallback RPC endpoint
  Future<void> _tryFallbackRpc() async {
    if (_currentFallbackIndex < fallbackRpcUrls.length) {
      rpcUrl = fallbackRpcUrls[_currentFallbackIndex];
      _currentFallbackIndex++;
      debugPrint('Switching to fallback RPC: $rpcUrl');
    }
  }
  
  // Make RPC call with proper error handling and retry logic
  Future<Map<String, dynamic>> _makeRpcCall({
    required String method,
    List<dynamic>? params,
    int maxRetries = 2,
  }) async {
    Exception? lastException;
    
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      final requestId = _generateRequestId();
      
      final body = {
        'jsonrpc': '2.0',
        'id': requestId,
        'method': method,
        if (params != null) 'params': params,
      };
      
      try {
        debugPrint('Making RPC call (attempt ${attempt + 1}/${maxRetries + 1}): $method');
        debugPrint('RPC URL: $rpcUrl');
        if (attempt == 0) {
          debugPrint('Request body: ${jsonEncode(body)}');
        }
        
        final response = await _client.post(
          Uri.parse(rpcUrl),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 10));
        
        debugPrint('Response status: ${response.statusCode}');
        if (attempt == 0 || response.statusCode != 200) {
          debugPrint('Response body: ${response.body}');
        }
        
        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
        
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Check for JSON-RPC errors
        if (responseData.containsKey('error')) {
          final error = responseData['error'] as Map<String, dynamic>;
          final code = error['code'] as int;
          final message = error['message'] as String;
          final data = error['data'];
          
          debugPrint('RPC Error - Code: $code, Message: $message, Data: $data');
          
          // For -32603, try fallback RPC on first retry
          if (code == -32603 && attempt == 0 && _currentFallbackIndex < fallbackRpcUrls.length) {
            await _tryFallbackRpc();
            continue; // Retry with fallback RPC
          }
          
          // Handle specific error codes
          switch (code) {
            case -32603:
              throw Exception('Solana network is experiencing issues. Please try again in a few moments.');
            case -32602:
              throw Exception('Invalid request parameters. Please check your input.');
            case -32601:
              throw Exception('This operation is not supported by the current network.');
            case -32600:
              throw Exception('Invalid request format.');
            default:
              throw Exception('Network Error ($code): $message');
          }
        }
        
        // Success - return the response
        return responseData;
        
      } catch (e) {
        lastException = e is Exception ? e : Exception('Unexpected error: $e');
        debugPrint('RPC call attempt ${attempt + 1} failed: $e');
        
        // If this isn't the last attempt, wait before retrying
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: (attempt + 1) * 2)); // Exponential backoff
          
          // Try fallback RPC if available
          if (attempt == 0 && _currentFallbackIndex < fallbackRpcUrls.length) {
            await _tryFallbackRpc();
          }
        }
      }
    }
    
    // All attempts failed
    throw lastException ?? Exception('RPC call failed after $maxRetries retries');
  }
  
  // Get account balance
  Future<double> getBalance(String publicKey) async {
    try {
      // Validate public key format first
      if (!_isValidPublicKey(publicKey)) {
        throw Exception('Invalid wallet address format. Please check your wallet connection.');
      }
      
      final response = await _makeRpcCall(
        method: 'getBalance',
        params: [publicKey, {'commitment': 'confirmed'}],
      );
      
      final result = response['result'];
      if (result == null) {
        throw Exception('No balance data received from network.');
      }
      
      final lamports = result['value'] as int? ?? 0;
      return lamports / 1000000000; // Convert lamports to SOL
    } catch (e) {
      debugPrint('Failed to get balance for $publicKey: $e');
      if (e.toString().contains('Invalid wallet address')) {
        rethrow;
      }
      throw Exception('Unable to fetch balance. Network may be busy - please try again.');
    }
  }
  
  // Get account info
  Future<Map<String, dynamic>?> getAccountInfo(String publicKey) async {
    try {
      final response = await _makeRpcCall(
        method: 'getAccountInfo',
        params: [
          publicKey,
          {'encoding': 'base64'}
        ],
      );
      
      return response['result']['value'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Failed to get account info: $e');
      throw Exception('Failed to get account info: $e');
    }
  }
  
  // Get recent blockhash
  Future<String> getRecentBlockhash() async {
    try {
      final response = await _makeRpcCall(
        method: 'getRecentBlockhash',
        params: [{'commitment': 'finalized'}],
      );
      
      return response['result']['value']['blockhash'] as String;
    } catch (e) {
      debugPrint('Failed to get recent blockhash: $e');
      throw Exception('Failed to get recent blockhash: $e');
    }
  }
  
  // Send transaction
  Future<String> sendTransaction(String signedTransaction) async {
    try {
      final response = await _makeRpcCall(
        method: 'sendTransaction',
        params: [
          signedTransaction,
          {'encoding': 'base64'}
        ],
      );
      
      return response['result'] as String;
    } catch (e) {
      debugPrint('Failed to send transaction: $e');
      throw Exception('Failed to send transaction: $e');
    }
  }
  
  // Health check
  Future<bool> isHealthy() async {
    try {
      await _makeRpcCall(method: 'getHealth');
      return true;
    } catch (e) {
      debugPrint('RPC health check failed: $e');
      return false;
    }
  }
  
  void dispose() {
    _client.close();
  }
}