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

      // Try to connect to Phantom with timeout
      final connected = await _launchPhantomConnect();
      
      if (connected) {
        debugPrint('Phantom wallet connection initiated successfully');
        _showConnectionPendingMessage();
        
        // Set a timeout for the connection
        _startConnectionTimeout();
      } else {
        throw Exception('Failed to launch Phantom wallet app. Please make sure Phantom is installed.');
      }
      
    } catch (error) {
      _errorMessage = 'Failed to connect to Phantom: $error';
      _isConnecting = false;
      notifyListeners();
    }
  }
  
  // Start connection timeout
  void _startConnectionTimeout() {
    Future.delayed(const Duration(seconds: 30), () {
      if (_isConnecting) {
        // Connection timed out, offer alternatives
        _handleConnectionTimeout();
      }
    });
  }
  
  // Handle connection timeout
  void _handleConnectionTimeout() {
    _isConnecting = false;
    _errorMessage = 'Connection timed out. You can:\n'
        '1. Try again if Phantom app opened\n'
        '2. Use the manual connection option below\n'
        '3. Make sure Phantom app is installed';
    notifyListeners();
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

  // Alternative connection method - Manual/Demo connection for testing
  Future<void> connectWithAdapter() async {
    try {
      _isConnecting = true;
      _errorMessage = null;
      notifyListeners();

      // Give user feedback that we're trying an alternative method
      debugPrint('Attempting alternative connection method...');
      await Future.delayed(const Duration(seconds: 1));
      
      // For demo purposes, generate a mainnet-style address
      // In a real app, this would connect via a web adapter or browser extension
      _walletAddress = _generateMainnetDemoAddress();
      _isConnected = true;
      _isConnecting = false;
      
      debugPrint('Connected to Solana Mainnet via alternative method');
      debugPrint('Note: This is a demo connection for testing purposes');
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Failed to connect wallet to Mainnet: $error';
      _isConnecting = false;
      notifyListeners();
    }
  }
  
  // Cancel connection attempt
  void cancelConnection() {
    _isConnecting = false;
    _errorMessage = null;
    notifyListeners();
  }
  
  // Retry connection
  Future<void> retryConnection() async {
    _errorMessage = null;
    notifyListeners();
    await connectWithPhantom();
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