package com.example.mulheres_seguras_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.io.IOException

class EmergencyLocationService : Service() {
    
    companion object {
        private const val NOTIFICATION_ID = 1
        private const val CHANNEL_ID = "emergency_location_service"
        private const val CHANNEL_NAME = "Emergency Location Service"
        private const val BASE_URL = "https://upgraded-sniffle-97qq9w6q7w6gfp64j-5000.app.github.dev"
        private const val UPDATE_LOCATION_ENDPOINT = "/update-location"
        
        var isRunning = false
        private var userToken: String = "tokendouser123"
        private var callId: Int? = null
    }
    
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationCallback: LocationCallback
    private val client = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(10, TimeUnit.SECONDS)
        .writeTimeout(10, TimeUnit.SECONDS)
        .build()
    
    override fun onCreate() {
        super.onCreate()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        createLocationCallback()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
        isRunning = true
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Executar criação de emergência em thread separada
        Executors.newSingleThreadExecutor().execute { 
            postEmergency() 
        }
        
        // Iniciar atualizações de localização
        requestLocationUpdates()
        
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
    
    override fun onDestroy() {
        super.onDestroy()
        fusedLocationClient.removeLocationUpdates(locationCallback)
        isRunning = false
    }
    
    private fun createLocationCallback() {
        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                locationResult.lastLocation?.let { location ->
                    sendLocationUpdate(location.latitude, location.longitude)
                }
            }
        }
    }
    
    private fun requestLocationUpdates() {
        val locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 30000)
            .setWaitForAccurateLocation(false)
            .setMinUpdateIntervalMillis(15000)
            .setMaxUpdateDelayMillis(60000)
            .build()
        
        try {
            fusedLocationClient.requestLocationUpdates(
                locationRequest,
                locationCallback,
                Looper.getMainLooper()
            )
        } catch (e: SecurityException) {
            // Log error
        }
    }
    
    private fun postEmergency() {
        val url = "$BASE_URL/nfc/auto/$userToken"
        
        val request = Request.Builder()
            .url(url)
            .get()
            .build()
        
        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                // Log error
            }
            
            override fun onResponse(call: Call, response: Response) {
                if (response.isSuccessful) {
                    val responseBody = response.body?.string()
                    responseBody?.let {
                        try {
                            val json = JSONObject(it)
                            if (json.has("call_id")) {
                                callId = json.getInt("call_id")
                            }
                        } catch (e: Exception) {
                            // Log error
                        }
                    }
                }
                response.close()
            }
        })
    }
    
    private fun sendLocationUpdate(latitude: Double, longitude: Double) {
        if (callId == null) return
        
        val json = JSONObject().apply {
            put("token_nfc", userToken)
            put("latitude", latitude)
            put("longitude", longitude)
        }
        
        val requestBody = json.toString().toRequestBody("application/json".toMediaType())
        
        val request = Request.Builder()
            .url("$BASE_URL$UPDATE_LOCATION_ENDPOINT")
            .post(requestBody)
            .build()
        
        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                // Log error
            }
            
            override fun onResponse(call: Call, response: Response) {
                if (response.code == 400) {
                    // Parar o serviço se receber 400
                    stopSelf()
                }
                response.close()
            }
        })
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Serviço de localização de emergência"
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Mulheres Seguras")
            .setContentText("Monitorando localização de emergência")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
    }
} 