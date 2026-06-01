package com.example.logbook

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.os.Build
import android.os.IBinder
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*
import io.flutter.plugin.common.EventChannel
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

class LocationForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "logbook_location_service"
        const val NOTIFICATION_ID = 1
        const val ACTION_START = "ACTION_START"
        const val ACTION_STOP = "ACTION_STOP"
        const val BUFFER_FILE = "location_buffer.json"

        @Volatile
        private var eventSink: EventChannel.EventSink? = null

        fun setEventSink(sink: EventChannel.EventSink?) {
            eventSink = sink
        }

        fun getBufferedPoints(context: Context): List<Map<String, Any?>> {
            val file = File(context.filesDir, BUFFER_FILE)
            if (!file.exists()) return emptyList()
            return try {
                val text = file.readText()
                val arr = JSONArray(text)
                (0 until arr.length()).map { i ->
                    val obj = arr.getJSONObject(i)
                    mapOf(
                        "latitude" to obj.getDouble("latitude"),
                        "longitude" to obj.getDouble("longitude"),
                        "altitude" to obj.getDouble("altitude"),
                        "speed" to obj.getDouble("speed"),
                        "heading" to obj.optDouble("bearing", 0.0),
                        "timestamp" to obj.getLong("timestamp")
                    )
                }
            } catch (_: Exception) {
                emptyList()
            }
        }

        fun clearBuffer(context: Context) {
            File(context.filesDir, BUFFER_FILE).delete()
        }
    }

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationRequest: LocationRequest
    private lateinit var locationCallback: LocationCallback

    override fun onCreate() {
        super.onCreate()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        createNotificationChannel()

        locationRequest = LocationRequest.create().apply {
            interval = 2000
            fastestInterval = 1000
            priority = LocationRequest.PRIORITY_HIGH_ACCURACY
        }

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                for (location in locationResult.locations) {
                    val data = mapOf(
                        "latitude" to location.latitude,
                        "longitude" to location.longitude,
                        "altitude" to location.altitude,
                        "speed" to location.speed.toDouble(),
                        "heading" to location.bearing.toDouble()
                    )
                    eventSink?.success(data)
                    saveLocationPoint(location)
                }
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                startForeground(NOTIFICATION_ID, createNotification())
                startLocationUpdates()
            }
            ACTION_STOP -> {
                stopLocationUpdates()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        return START_REDELIVER_INTENT
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Logbook Location",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Used for recording flight GPS data in the background"
                setShowBadge(false)
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Logbook")
            .setContentText("Recording flight...")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun startLocationUpdates() {
        if (ActivityCompat.checkSelfPermission(
                this, android.Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        try {
            fusedLocationClient.requestLocationUpdates(
                locationRequest,
                locationCallback,
                Looper.getMainLooper()
            )
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun stopLocationUpdates() {
        try {
            fusedLocationClient.removeLocationUpdates(locationCallback)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun saveLocationPoint(location: Location) {
        try {
            val file = File(filesDir, BUFFER_FILE)
            val existing = if (file.exists()) {
                JSONArray(file.readText())
            } else {
                JSONArray()
            }
            val point = JSONObject().apply {
                put("latitude", location.latitude)
                put("longitude", location.longitude)
                put("altitude", location.altitude)
                put("speed", location.speed.toDouble())
                put("bearing", location.bearing.toDouble())
                put("timestamp", location.time)
            }
            if (existing.length() >= 20000) {
                val trimmed = JSONArray()
                for (i in existing.length() - 19999 until existing.length()) {
                    trimmed.put(existing.getJSONObject(i))
                }
                trimmed.put(point)
                file.writeBytes(trimmed.toString().toByteArray())
            } else {
                existing.put(point)
                file.writeBytes(existing.toString().toByteArray())
            }
        } catch (_: Exception) {
        }
    }
}
