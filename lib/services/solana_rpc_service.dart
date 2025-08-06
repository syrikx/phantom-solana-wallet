import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class SolanaRpcService {
  static const String mainnetRpcUrl = 'https://api.mainnet-beta.solana.com';
  static const String devnetRpcUrl = 'https://api.devnet.solana.com';
  
  final String rpcUrl;
  final http.Client _client = http.Client();
  
  SolanaRpcService({this.rpcUrl = mainnetRpcUrl});
  
  // Generate unique request ID
  String _generateRequestId() {
    final random = Random();
    return random.nextInt(999999).toString();
  }
  
  // Make RPC call with proper error handling
  Future<Map<String, dynamic>> _makeRpcCall({
    required String method,
    List<dynamic>? params,
  }) async {
    final requestId = _generateRequestId();
    
    final body = {
      'jsonrpc': '2.0',
      'id': requestId,
      'method': method,
      if (params != null) 'params': params,
    };
    
    try {
      debugPrint('Making RPC call: $method');
      debugPrint('RPC URL: $rpcUrl');
      debugPrint('Request body: ${jsonEncode(body)}');
      
      final response = await _client.post(
        Uri.parse(rpcUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
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
        
        // Handle specific error codes
        switch (code) {
          case -32603:
            throw Exception('RPC Internal Error: This usually means the transaction or request could not be processed. Please try again with different parameters.');
          case -32602:
            throw Exception('Invalid Parameters: The request parameters are invalid or missing.');
          case -32601:
            throw Exception('Method Not Found: The requested method is not supported.');
          case -32600:
            throw Exception('Invalid Request: The request format is invalid.');
          default:
            throw Exception('RPC Error ($code): $message');
        }
      }
      
      return responseData;
    } catch (e) {
      debugPrint('RPC call failed: $e');
      rethrow;
    }
  }
  
  // Get account balance
  Future<double> getBalance(String publicKey) async {
    try {
      final response = await _makeRpcCall(
        method: 'getBalance',
        params: [publicKey],
      );
      
      final lamports = response['result']['value'] as int;
      return lamports / 1000000000; // Convert lamports to SOL
    } catch (e) {
      debugPrint('Failed to get balance: $e');
      throw Exception('Failed to get account balance: $e');
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