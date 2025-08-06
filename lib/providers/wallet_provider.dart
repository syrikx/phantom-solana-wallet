import 'package:flutter/material.dart';

class WalletProvider extends ChangeNotifier {
  String? _walletAddress;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _errorMessage;

  String? get walletAddress => _walletAddress;
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get errorMessage => _errorMessage;

  // Simulate wallet connection for demo purposes
  Future<void> connectWithPhantom() async {
    try {
      _isConnecting = true;
      _errorMessage = null;
      notifyListeners();

      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock wallet address for demo
      _walletAddress = '7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU';
      _isConnected = true;
      _isConnecting = false;
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Failed to connect to Phantom: $error';
      _isConnecting = false;
      notifyListeners();
    }
  }

  // Alternative connection method
  Future<void> connectWithAdapter() async {
    try {
      _isConnecting = true;
      _errorMessage = null;
      notifyListeners();

      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock wallet address for demo
      _walletAddress = '7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU';
      _isConnected = true;
      _isConnecting = false;
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Failed to connect wallet: $error';
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

  // Sign message (mock implementation)
  Future<String?> signMessage(String message) async {
    try {
      if (!_isConnected) {
        throw Exception('Wallet not connected');
      }

      // Simulate signing delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock signature
      return 'mock_signature_${DateTime.now().millisecondsSinceEpoch}';
    } catch (error) {
      _errorMessage = 'Failed to sign message: $error';
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}