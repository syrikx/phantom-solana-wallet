import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';

class WalletInfoCard extends StatelessWidget {
  const WalletInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wallet Connected',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Ready for transactions',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: walletProvider.disconnect,
                      icon: const Icon(Icons.logout),
                      tooltip: 'Disconnect',
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                // Wallet Address
                Text(
                  'Wallet Address:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          walletProvider.walletAddress ?? 'Unknown',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (walletProvider.walletAddress != null) {
                            Clipboard.setData(
                              ClipboardData(text: walletProvider.walletAddress!),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Address copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        tooltip: 'Copy address',
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Balance Info
                if (walletProvider.balance != null)
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Balance: ${walletProvider.balance?.toStringAsFixed(4) ?? '0.0000'} SOL',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: walletProvider.refreshAccountData,
                        icon: const Icon(Icons.refresh, size: 18),
                        tooltip: 'Refresh balance',
                      ),
                    ],
                  ),
                
                const SizedBox(height: 8),
                
                // Network Info
                Row(
                  children: [
                    Icon(
                      Icons.network_check,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Network: Mainnet',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}