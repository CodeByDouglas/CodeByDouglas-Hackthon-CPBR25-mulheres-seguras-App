package com.example.mulheres_seguras_app

import android.content.Intent
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "emergency_service_channel"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when(call.method) {
                "startEmergencyService" -> {
                    val serviceIntent = Intent(this, EmergencyLocationService::class.java)
                    ContextCompat.startForegroundService(this, serviceIntent)
                    result.success("Service Started")
                }
                "stopEmergencyService" -> {
                    stopService(Intent(this, EmergencyLocationService::class.java))
                    result.success("Service Stopped")
                }
                "isEmergencyServiceRunning" -> {
                    val isRunning = EmergencyLocationService.isRunning
                    result.success(isRunning)
                }
                else -> result.notImplemented()
            }
        }
    }
}
