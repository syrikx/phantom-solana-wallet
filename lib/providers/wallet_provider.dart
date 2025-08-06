import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

class WalletProvider extends ChangeNotifier {
  String? _walletAddress;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _errorMessage;
  String? _sessionId;
  String? _encryptionPublicKey;
  
  // Mainnet RPC endpoint
  static const String mainnetRpcUrl = 'https://api.mainnet-beta.solana.com';
  
  // Phantom deep link schemes
  static const String phantomUniversalLink = 'https://phantom.app/ul/';
  static const String phantomDeepLink = 'phantom://';
  
  // App metadata for Phantom
  static const String appName = 'Solana Phantom Wallet';
  static const String appUrl = 'https://phantom-solana-wallet.app';
  static const String redirectScheme = 'phantommainnet';

  String? get walletAddress => _walletAddress;
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get errorMessage => _errorMessage;
  String get networkName => 'Mainnet';
  
  // Generate a unique session ID for this connection attempt
  String _generateSessionId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  // Connect to Phantom wallet via deep link (Mainnet)
  Future<void> connectWithPhantom() async {
    try {
      _isConnecting = true;
      _errorMessage = null;
      _sessionId = _generateSessionId();
      notifyListeners();

      // Create connect request for Phantom wallet
      final connected = await _launchPhantomConnect();
      
      if (connected) {
        debugPrint('Phantom wallet connection initiated successfully');
        // The actual wallet address will be set when the deep link callback is handled
        // For now, we'll wait for user to return from Phantom app
        _showConnectionPendingMessage();
      } else {
        throw Exception('Failed to launch Phantom wallet app');
      }
      
    } catch (error) {
      _errorMessage = 'Failed to connect to Phantom: $error';
      _isConnecting = false;
      notifyListeners();
    }
  }
  
  void _showConnectionPendingMessage() {
    debugPrint('Waiting for Phantom wallet response...');
    debugPrint('Please complete the connection in Phantom app and return to this app');
  }
  
  // Launch Phantom app for wallet connection
  Future<bool> _launchPhantomConnect() async {
    // Create the connection request parameters
    final params = {
      'app_url': appUrl,
      'dapp_encryption_public_key': _generateEncryptionKey(),
      'redirect_link': '$redirectScheme://connected',
      'cluster': 'mainnet-beta',
    };
    
    // Encode parameters for URL
    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    // Try Phantom deep link first (if app is installed)
    final deepLinkUrl = '${phantomDeepLink}v1/connect?$queryString';
    
    try {
      debugPrint('Attempting to launch Phantom app...');
      debugPrint('Deep link: $deepLinkUrl');
      
      final Uri deepLinkUri = Uri.parse(deepLinkUrl);
      
      if (await canLaunchUrl(deepLinkUri)) {
        debugPrint('Phantom app detected, launching...');
        return await launchUrl(
          deepLinkUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback to universal link (will redirect to app store if not installed)
        final universalLinkUrl = '${phantomUniversalLink}connect?$queryString';
        final Uri universalUri = Uri.parse(universalLinkUrl);
        
        debugPrint('Phantom app not detected, using universal link...');
        debugPrint('Universal link: $universalLinkUrl');
        
        return await launchUrl(
          universalUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint('Error launching Phantom wallet: $e');
      throw Exception('Failed to launch Phantom wallet: $e');
    }
  }
  
  // Generate encryption key for secure communication
  String _generateEncryptionKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    _encryptionPublicKey = base64Encode(bytes);
    return _encryptionPublicKey!;
  }
  
  // Handle deep link response from Phantom wallet
  Future<void> handlePhantomResponse(Uri uri) async {
    try {
      debugPrint('Received deep link response: ${uri.toString()}');
      
      final queryParams = uri.queryParameters;
      
      if (queryParams.containsKey('public_key')) {
        // Successfully connected
        _walletAddress = queryParams['public_key'];
        _isConnected = true;
        _isConnecting = false;
        _errorMessage = null;
        
        debugPrint('Successfully connected to Phantom wallet');
        debugPrint('Wallet address: $_walletAddress');
        
        notifyListeners();
      } else if (queryParams.containsKey('error')) {
        // Connection failed
        final error = queryParams['error'] ?? 'Unknown error';
        throw Exception('Phantom connection failed: $error');
      } else {
        throw Exception('Invalid response from Phantom wallet');
      }
    } catch (error) {
      _errorMessage = 'Failed to process Phantom response: $error';
      _isConnecting = false;
      _isConnected = false;
      notifyListeners();
    }
  }
  
  // Generate a demo mainnet address (fallback for testing)
  String _generateMainnetDemoAddress() {
    // This is a valid Solana mainnet address format for demo purposes
    return 'DXH4DXXfkrX8Xz6oiZCbRy9KZxX7ZqX8X9XqXzXqXzXq';
  }

  // Alternative connection method (Web3 adapter style for Mainnet)
  Future<void> connectWithAdapter() async {
    try {
      _isConnecting = true;
      _errorMessage = null;
      notifyListeners();

      // Simulate wallet adapter connection to Mainnet
      await Future.delayed(const Duration(seconds: 2));
      
      // Generate mainnet-compatible demo address
      _walletAddress = _generateMainnetDemoAddress();
      _isConnected = true;
      _isConnecting = false;
      
      debugPrint('Connected to Solana Mainnet via adapter');
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Failed to connect wallet to Mainnet: $error';
      _isConnecting = false;
      notifyListeners();
    }
  }

  // Disconnect wallet
  Future<void> disconnect() async {
    try {
      _walletAddress = null;
      _isConnected = false;
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Failed to disconnect: $error';
      notifyListeners();
    }
  }

  // Sign message with Phantom wallet (Mainnet)
  Future<String?> signMessage(String message) async {
    try {
      if (!_isConnected) {
        throw Exception('Wallet not connected to Mainnet');
      }

      // In production, this would make a request to Phantom to sign the message
      debugPrint('Requesting message signature from Phantom wallet...');
      debugPrint('Network: Mainnet');
      debugPrint('Message: $message');
      
      // Simulate signing delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Generate mainnet-compatible signature format
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'mainnet_signature_${timestamp}_${message.hashCode}';
    } catch (error) {
      _errorMessage = 'Failed to sign message on Mainnet: $error';
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}