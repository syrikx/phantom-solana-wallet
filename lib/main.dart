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
  static const platform = MethodChannel('phantom_wallet_channel');
  
  @override
  void initState() {
    super.initState();
    _walletProvider = WalletProvider();
    _initializeDeepLinkHandling();
  }
  
  void _initializeDeepLinkHandling() {
    // Set up method channel listener for Android deep links
    platform.setMethodCallHandler(_handleMethodCall);
    debugPrint('Deep link handler initialized with MethodChannel');
  }
  
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'handlePhantomCallback':
        final String uriString = call.arguments;
        debugPrint('Received Phantom callback: $uriString');
        
        try {
          final Uri uri = Uri.parse(uriString);
          await _walletProvider.handlePhantomResponse(uri);
        } catch (e) {
          debugPrint('Error handling Phantom callback: $e');
        }
        break;
      default:
        throw MissingPluginException('Not implemented: ${call.method}');
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