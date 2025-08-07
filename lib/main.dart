import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/wallet_provider.dart';
import 'screens/home_screen.dart';

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
      ),
    );
  }
}