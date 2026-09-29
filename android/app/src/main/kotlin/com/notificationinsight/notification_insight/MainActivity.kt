package com.notificationinsight.notification_insight

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.notificationinsight.simulator/native_notification"
    private val NOTIFICATION_CHANNEL_ID = "notification_insight_simulator_channel"
    private var notificationIdCounter = 1000

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        createNotificationChannel()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "postNotification" -> {
                    val title = call.argument<String>("title")
                    val content = call.argument<String>("content")
                    val id = call.argument<Int>("id") ?: notificationIdCounter++
                    
                    try {
                        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                        
                        val builder = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
                            .setSmallIcon(android.R.drawable.ic_dialog_info)
                            .setContentTitle(title)
                            .setContentText(content)
                            .setPriority(NotificationCompat.PRIORITY_HIGH)
                            .setAutoCancel(true)

                        if (content != null && content.length > 50) {
                            builder.setStyle(NotificationCompat.BigTextStyle().bigText(content))
                        }

                        notificationManager.notify(id, builder.build())
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("NOTIFICATION_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Notification Simulator Channel",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Channel for emitting real test notifications via Android OS"
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}
