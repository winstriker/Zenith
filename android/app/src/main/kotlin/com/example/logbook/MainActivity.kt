package com.example.logbook

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.example.logbook/location_service"
    private val EVENT_CHANNEL = "com.example.logbook/location_events"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    val intent = Intent(this, LocationForegroundService::class.java).apply {
                        action = LocationForegroundService.ACTION_START
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(true)
                }
                "stopService" -> {
                    val intent = Intent(this, LocationForegroundService::class.java).apply {
                        action = LocationForegroundService.ACTION_STOP
                    }
                    startService(intent)
                    result.success(true)
                }
                "getBufferedData" -> {
                    val data = LocationForegroundService.getBufferedPoints(this)
                    result.success(data)
                }
                "clearBuffer" -> {
                    LocationForegroundService.clearBuffer(this)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(
                    arguments: Any?,
                    events: EventChannel.EventSink?
                ) {
                    LocationForegroundService.setEventSink(events)
                }

                override fun onCancel(arguments: Any?) {
                    LocationForegroundService.setEventSink(null)
                }
            }
        )
    }
}
