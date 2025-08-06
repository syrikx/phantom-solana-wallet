import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/wallet_provider.dart';
import 'screens/home_screen.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late WalletProvider _walletProvider;
  
  @override
  void initState() {
    super.initState();
    _walletProvider = WalletProvider();
    _initializeDeepLinkHandling();
  }
  
  void _initializeDeepLinkHandling() {
    // Listen for deep link events when app is already running
    _handleIncomingLinks();
    
    // Handle deep link when app is launched from a deep link
    _handleInitialLink();
  }
  
  void _handleIncomingLinks() {
    // This would typically use a package like app_links or receive_sharing_intent
    // For now, we'll set up basic handling
    debugPrint('Deep link handler initialized');
  }
  
  void _handleInitialLink() async {
    try {
      // Check if the app was launched from a deep link
      // This is a simplified version - in production you'd use a proper deep link package
      debugPrint('Checking for initial deep link...');
    } catch (e) {
      debugPrint('Error handling initial link: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _walletProvider,
      child: MaterialApp(
        title: 'Solana Phantom Wallet',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
        // Handle deep link routes
        onGenerateRoute: (settings) {
          debugPrint('Route requested: ${settings.name}');
          
          // Handle Phantom callback
          if (settings.name != null && settings.name!.startsWith('/phantom-callback')) {
            final uri = Uri.parse(settings.name!);
            _walletProvider.handlePhantomResponse(uri);
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          }
          
          return MaterialPageRoute(builder: (_) => const HomeScreen());
        },
      ),
    );
  }
}