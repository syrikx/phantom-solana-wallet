import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/wallet_connection_card.dart';
import '../widgets/wallet_info_card.dart';
import '../widgets/transaction_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Solana Phantom Wallet'),
        centerTitle: true,
      ),
      body: Consumer<WalletProvider>(
        builder: (context, walletProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Connection Status
                if (walletProvider.isConnecting)
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Connecting to Phantom Wallet...',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please complete the connection in Phantom app and return here',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton(
                                onPressed: walletProvider.cancelConnection,
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: walletProvider.retryConnection,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Did you approve the connection in Phantom?',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orange.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: walletProvider.forceConnectionSuccess,
                            icon: const Icon(Icons.check_circle, size: 18),
                            label: const Text('Yes, I Connected'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (!walletProvider.isConnected)
                  const WalletConnectionCard()
                else
                  const WalletInfoCard(),
                
                const SizedBox(height: 20),
                
                // Error Display
                if (walletProvider.errorMessage != null)
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              walletProvider.errorMessage!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                          IconButton(
                            onPressed: walletProvider.clearError,
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                // Transaction Section
                if (walletProvider.isConnected)
                  const TransactionSection(),
              ],
            ),
          );
        },
      ),
    );
  }
}