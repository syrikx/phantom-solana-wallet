package com.example.solana_phantom_wallet_app

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "phantom_wallet_channel"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Handle intent when app is launched
        handleIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Handle intent when app is already running
        handleIntent(intent)
    }
    
    private fun handleIntent(intent: Intent) {
        val data: Uri? = intent.data
        Log.d("MainActivity", "handleIntent called with data: ${data?.toString()}")
        
        if (data != null) {
            Log.d("MainActivity", "URI scheme: ${data.scheme}")
            Log.d("MainActivity", "URI host: ${data.host}")
            Log.d("MainActivity", "URI path: ${data.path}")
            Log.d("MainActivity", "URI query: ${data.query}")
            
            if (data.scheme == "phantommainnet" || data.scheme == "solana-phantom-wallet") {
                Log.d("MainActivity", "Processing Phantom callback: ${data.toString()}")
                
                // Create method channel to communicate with Flutter
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    MethodChannel(messenger, CHANNEL).invokeMethod("handlePhantomCallback", data.toString())
                } ?: run {
                    Log.e("MainActivity", "Flutter engine not ready")
                }
            } else {
                Log.d("MainActivity", "URI scheme doesn't match known schemes: ${data.scheme}")
            }
        } else {
            Log.d("MainActivity", "No URI data in intent")
        }
    }
}