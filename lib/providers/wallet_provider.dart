import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:math';
import '../services/solana_rpc_service.dart';

class WalletProvider extends ChangeNotifier {
  String? _walletAddress;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _errorMessage;
  double? _balance;
  String? _lastSignature;
  late SolanaRpcService _rpcService;
  String? _sessionId;
  String? _encryptionPublicKey;
  
  // Mainnet RPC endpoint
  static const String mainnetRpcUrl = 'https://api.mainnet-beta.solana.com';
  
  // App metadata for Phantom
  static const String appName = 'Solana Phantom Wallet';
  static const String appUrl = 'https://phantom-solana-wallet.app';
  static const String redirectScheme = 'solana-phantom-wallet';
  
  // Phantom deep link schemes
  static const String phantomUniversalLink = 'https://phantom.app/ul/';
  static const String phantomDeepLink = 'phantom://';

  String? get walletAddress => _walletAddress;
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get errorMessage => _errorMessage;
  String get networkName => 'Mainnet';
  double? get balance => _balance;
  String? get lastSignature => _lastSignature;
  
  // Constructor
  WalletProvider() {
    _rpcService = SolanaRpcService(rpcUrl: mainnetRpcUrl);
  }
  
  // Generate a unique session ID for this connection attempt
  String _generateSessionId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  // Generate encryption key for secure communication
  String _generateEncryptionKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    _encryptionPublicKey = base64Encode(bytes);
    return _encryptionPublicKey!;
  }

  // Connect to Phantom wallet using simplified deep link approach
  Future<void> connectWithPhantom() async {
    try {
      _isConnecting = true;
      _errorMessage = null;
      _sessionId = _generateSessionId();
      notifyListeners();

      debugPrint('Connecting to Phantom using simplified deep link...');
      
      // Launch Phantom connection
      final success = await _launchPhantomConnect();
      
      if (success) {
        debugPrint('Phantom connection launched successfully');
        _startConnectionTimeout();
      } else {
        throw Exception('Failed to launch Phantom wallet app. Please ensure Phantom is installed.');
      }
      
    } catch (error) {
      debugPrint('Phantom connection error: $error');
      _errorMessage = 'Failed to connect to Phantom: $error';
      _isConnecting = false;
      notifyListeners();
    }
  }
  
  // Start connection timeout
  void _startConnectionTimeout() {
    Future.delayed(const Duration(seconds: 120), () {
      if (_isConnecting) {
        _isConnecting = false;
        _errorMessage = 'Connection timed out. Please try again and make sure to approve the connection in Phantom.';
        notifyListeners();
      }
    });
  }
  
  // Launch Phantom connection
  Future<bool> _launchPhantomConnect() async {
    try {
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
      
      // Try Phantom deep link first
      final deepLinkUrl = '${phantomDeepLink}v1/connect?$queryString';
      final Uri deepLinkUri = Uri.parse(deepLinkUrl);
      
      debugPrint('Launching Phantom deep link: $deepLinkUrl');
      
      bool launched = false;
      try {
        launched = await launchUrl(
          deepLinkUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        debugPrint('Deep link failed: $e');
      }
      
      if (launched) {
        debugPrint('Deep link launched successfully');
        return true;
      } else {
        debugPrint('Deep link failed, trying universal link...');
        
        // Fallback to universal link
        final universalLinkUrl = '${phantomUniversalLink}connect?$queryString';
        final Uri universalUri = Uri.parse(universalLinkUrl);
        
        debugPrint('Universal link URL: $universalLinkUrl');
        
        final universalLaunched = await launchUrl(
          universalUri,
          mode: LaunchMode.externalApplication,
        );
        
        if (universalLaunched) {
          debugPrint('Universal link launched successfully');
          return true;
        } else {
          debugPrint('Both deep link and universal link failed');
          return false;
        }
      }
    } catch (e) {
      debugPrint('Error launching Phantom connection: $e');
      return false;
    }
  }

  // Demo connection for testing
  Future<void> connectWithAdapter() async {
    try {
      _isConnecting = true;
      _errorMessage = null;
      notifyListeners();

      debugPrint('Using demo connection...');
      await Future.delayed(const Duration(seconds: 1));
      
      _walletAddress = '11111111111111111111111111111112'; // Demo address
      _balance = 0.5; // Demo balance
      _isConnected = true;
      _isConnecting = false;
      
      debugPrint('Demo connection successful');
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Demo connection failed: $error';
      _isConnecting = false;
      notifyListeners();
    }
  }
  
  // Connect via web browser as fallback
  Future<void> connectViaBrowser() async {
    try {
      _isConnecting = true;
      _errorMessage = null;
      notifyListeners();

      debugPrint('Attempting web browser connection...');
      
      // Create the connection request parameters for universal link
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
      
      // Use web browser to connect via universal link
      final webUrl = '${phantomUniversalLink}connect?$queryString';
      final Uri webUri = Uri.parse(webUrl);
      
      debugPrint('Launching browser connection: $webUrl');
      
      final launched = await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );
      
      if (launched) {
        debugPrint('Web browser launched successfully');
        _startConnectionTimeout();
      } else {
        throw Exception('Failed to open web browser for Phantom connection');
      }
      
    } catch (error) {
      debugPrint('Browser connection error: $error');
      _errorMessage = 'Failed to connect via browser: $error';
      _isConnecting = false;
      notifyListeners();
    }
  }
  
  // Manual success for testing
  void forceConnectionSuccess() {
    _walletAddress = '11111111111111111111111111111112';
    _isConnected = true;
    _isConnecting = false;
    _errorMessage = null;
    debugPrint('Force connection success - using demo address');
    notifyListeners();
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
      _balance = null;
      _lastSignature = null;
      _sessionId = null;
      _encryptionPublicKey = null;
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Failed to disconnect: $error';
      notifyListeners();
    }
  }

  // Fetch account balance from Solana RPC
  Future<void> _fetchAccountBalance() async {
    if (_walletAddress == null) return;
    
    try {
      debugPrint('Fetching balance for address: $_walletAddress');
      
      // Add a small delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 500));
      
      _balance = await _rpcService.getBalance(_walletAddress!);
      debugPrint('Account balance: $_balance SOL');
      notifyListeners();
    } catch (error) {
      debugPrint('Failed to fetch balance: $error');
      _balance = null;
      
      // Only show error if it's a critical issue
      if (error.toString().contains('Invalid wallet address')) {
        _errorMessage = 'Invalid wallet address. Please reconnect your wallet.';
        _isConnected = false;
        _walletAddress = null;
        notifyListeners();
      }
    }
  }
  
  // Sign message (simplified for demo)
  Future<String?> signMessage(String message) async {
    try {
      if (!_isConnected) {
        throw Exception('Wallet not connected to Mainnet');
      }

      // For demo mode, return a mock signature
      if (_walletAddress == '11111111111111111111111111111112') {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        return 'demo_signature_${timestamp}_${message.hashCode}';
      }

      debugPrint('Message signing would require Phantom deep link integration...');
      _errorMessage = 'Message signing requires full deep link setup. Using demo mode for now.';
      notifyListeners();
      
      // Return demo signature for now
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'demo_signature_${timestamp}_${message.hashCode}';
      
    } catch (error) {
      debugPrint('Sign message error: $error');
      _errorMessage = 'Failed to sign message: $error';
      notifyListeners();
      return null;
    }
  }
  
  // Send SOL (simplified for demo)
  Future<String?> sendSOL({
    required String recipientAddress,
    required double amount,
  }) async {
    try {
      if (!_isConnected) {
        throw Exception('Wallet not connected');
      }

      // For demo mode
      if (_walletAddress == '11111111111111111111111111111112') {
        throw Exception('SOL transfer not available in demo mode. Connect real Phantom wallet for transfers.');
      }

      debugPrint('SOL transfer would require Phantom deep link integration...');
      _errorMessage = 'SOL transfer requires full deep link setup. Connect with real Phantom wallet.';
      notifyListeners();
      return null;
      
    } catch (error) {
      debugPrint('SOL transfer error: $error');
      _errorMessage = 'Failed to send SOL: $error';
      notifyListeners();
      return null;
    }
  }
  
  // Refresh account data
  Future<void> refreshAccountData() async {
    if (!_isConnected || _walletAddress == null) return;
    
    try {
      // Check if this is a demo connection
      if (_walletAddress == '11111111111111111111111111111112') {
        // For demo connection, update with random balance
        final random = Random();
        _balance = 0.1 + random.nextDouble() * 2.0; // Random balance between 0.1 and 2.1
        debugPrint('Demo balance refreshed: $_balance SOL');
        notifyListeners();
        return;
      }
      
      // For real connections, fetch actual balance
      await _fetchAccountBalance();
    } catch (error) {
      debugPrint('Failed to refresh account data: $error');
      _errorMessage = 'Unable to refresh data. Please check your connection and try again.';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _rpcService.dispose();
    super.dispose();
  }
}