# Solana Phantom Wallet Flutter App

A Flutter application that integrates with Phantom wallet for Solana blockchain interactions.

## Features

- 🔗 Connect to Phantom wallet using multiple methods
- 📝 Sign messages with wallet
- 🔐 Secure wallet state management
- 📱 Mobile-optimized UI
- 🌐 Devnet support for testing

## Wallet Integration Methods

### 1. Phantom Wallet Connector (Recommended)
- Latest package specifically for Phantom wallet (Jan 2025)
- Simple API for connecting and signing
- Supports Android and iOS

### 2. Solana Wallet Adapter
- Official Solana Mobile Wallet Adapter implementation
- Works with multiple wallets (Phantom, Solflare, etc.)
- More comprehensive feature set

## Prerequisites

- Flutter SDK 3.0.0 or higher
- Dart SDK 3.0.0 or higher
- Phantom wallet installed on your device
- Android/iOS development environment

## Installation

1. Clone this repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## Dependencies

- `phantom_wallet_connector: ^0.0.1` - Phantom wallet integration
- `solana_wallet_adapter: ^0.1.5` - Official Solana wallet adapter
- `solana_web3: ^0.1.3` - Solana blockchain interactions
- `provider: ^6.1.1` - State management

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── providers/
│   └── wallet_provider.dart  # Wallet state management
├── screens/
│   └── home_screen.dart      # Main app screen
└── widgets/
    ├── wallet_connection_card.dart  # Connection UI
    ├── wallet_info_card.dart        # Connected wallet info
    └── transaction_section.dart     # Transaction features
```

## Usage

1. **Connect Wallet**: Tap "Connect with Phantom" to establish connection
2. **Sign Messages**: Enter text in the message field and sign with your wallet
3. **View Address**: Copy your wallet address from the info card
4. **Disconnect**: Use the logout button to disconnect your wallet

## Configuration

### Android Setup
The app is configured to handle deep links for wallet callbacks. Make sure your `android/app/src/main/AndroidManifest.xml` includes the necessary permissions and intent filters.

### Network Configuration
Currently configured for Solana Devnet. To switch networks, modify the `cluster` parameter in `WalletProvider`:

```dart
_walletAdapter = SolanaWalletAdapter(
  const AppIdentity(...),
  cluster: Cluster.mainnet, // Change to mainnet for production
);
```

## Future Features

- 💸 Send SOL transfers
- 🪙 SPL token support
- 🔄 Token swapping
- 📊 Transaction history
- 🌍 Multiple network support

## Security Notes

- Never commit private keys or secrets
- Always verify transactions before signing
- Use testnet/devnet for development
- Validate all user inputs

## Troubleshooting

1. **Connection Issues**: Ensure Phantom wallet is installed and updated
2. **Deep Link Problems**: Check AndroidManifest.xml configuration
3. **Network Errors**: Verify internet connection and network settings

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.