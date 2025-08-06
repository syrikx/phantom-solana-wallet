import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';

class TransactionSection extends StatefulWidget {
  const TransactionSection({super.key});

  @override
  State<TransactionSection> createState() => _TransactionSectionState();
}

class _TransactionSectionState extends State<TransactionSection> {
  final _messageController = TextEditingController();
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isProcessing = false;
  bool _isTransferring = false;

  @override
  void dispose() {
    _messageController.dispose();
    _recipientController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _signMessage() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message to sign')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final signature = await walletProvider.signMessage(_messageController.text);

    setState(() => _isProcessing = false);

    if (signature != null) {
      _showSignatureDialog(signature);
    } else if (walletProvider.lastSignature != null) {
      _showSignatureDialog(walletProvider.lastSignature!);
    }
  }
  
  Future<void> _sendSOL() async {
    final recipient = _recipientController.text.trim();
    final amountText = _amountController.text.trim();
    
    if (recipient.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter recipient address')),
      );
      return;
    }
    
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter amount to send')),
      );
      return;
    }
    
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isTransferring = true);

    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final result = await walletProvider.sendSOL(
      recipientAddress: recipient,
      amount: amount,
    );

    setState(() => _isTransferring = false);

    if (result != null) {
      _showTransactionDialog(result);
    } else if (walletProvider.lastSignature != null) {
      _showTransactionDialog(walletProvider.lastSignature!);
    }
  }

  void _showSignatureDialog(String signature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Message Signed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Signature:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                signature,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _showTransactionDialog(String transactionSignature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 8),
            const Text('Transaction Sent'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Transaction Signature:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                transactionSignature,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your SOL has been sent successfully!',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Transactions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Sign Message Section
            Text(
              'Sign Message',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Enter message to sign...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _signMessage,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.edit),
                label: Text(_isProcessing ? 'Signing...' : 'Sign Message'),
              ),
            ),
            
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            
            // Send SOL Section
            Text(
              'Send SOL',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _recipientController,
              decoration: const InputDecoration(
                hintText: 'Recipient address...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            
            const SizedBox(height: 12),
            
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                hintText: 'Amount (SOL)...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
                prefixIcon: Icon(Icons.monetization_on),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isTransferring ? null : _sendSOL,
                icon: _isTransferring
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_isTransferring ? 'Sending...' : 'Send SOL'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            
            // Future Transaction Features
            Text(
              'Coming Soon',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            Column(
              children: [
                _buildFeatureItem(
                  icon: Icons.token,
                  title: 'SPL Tokens',
                  subtitle: 'Send and receive SPL tokens',
                ),
                _buildFeatureItem(
                  icon: Icons.swap_horiz,
                  title: 'Token Swap',
                  subtitle: 'Swap between different tokens',
                ),
                _buildFeatureItem(
                  icon: Icons.nfc,
                  title: 'NFT Transfer',
                  subtitle: 'Send and receive NFTs',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(
        title,
        style: const TextStyle(color: Colors.grey),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.grey),
      ),
      enabled: false,
    );
  }
}