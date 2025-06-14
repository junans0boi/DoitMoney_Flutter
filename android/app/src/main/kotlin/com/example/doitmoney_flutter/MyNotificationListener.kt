package com.example.doitmoney_flutter

import android.annotation.TargetApi
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

@TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
class MyNotificationListener : NotificationListenerService() {
    companion object {
        const val CHANNEL_ID = "doitmoney_notification_listener"
        const val CHANNEL_NAME = "DoitMoney 알림 수집"
        const val FOREGROUND_ID = 1001

        const val DART_CHANNEL = "doitmoney.flutter.dev/notification"
        const val METHOD_ON_NOTIFICATION = "onNotificationPosted"
        const val ENGINE_ID = "doitmoney_engine"
    }

    private lateinit var dartChannel: MethodChannel

    override fun onCreate() {
        super.onCreate()

        // 1) NotificationChannel 생성 (Android O+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "앱이 꺼져도 알림을 지속해서 수집하기 위한 포그라운드 서비스"
            }
            (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                .createNotificationChannel(ch)
        }

        // 2) 캐시된 FlutterEngine 꺼내기
        val engine = FlutterEngineCache
            .getInstance()
            .get(ENGINE_ID)
            ?: throw IllegalStateException("FlutterEngine not found in cache")
        dartChannel = MethodChannel(engine.dartExecutor.binaryMessenger, DART_CHANNEL)

        // 3) 포그라운드 서비스로 시작
        val notif: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("DoitMoney 알림 수집 중")
            .setContentText("앱이 종료되어도 알림을 수집합니다")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .build()
        startForeground(FOREGROUND_ID, notif)
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val notif = sbn.notification

        // 1) TITLE: extras 가 비어 있으면 tickerText 사용
        val title = notif.extras
            .getString(Notification.EXTRA_TITLE)
            ?.takeIf { it.isNotBlank() }
            ?: notif.tickerText?.toString()
            ?: ""

        // 2) TEXT: 먼저 EXTRA_TEXT, 그 다음에 BIG_TEXT, 마지막으로 tickerText
        val text = notif.extras
            .getCharSequence(Notification.EXTRA_TEXT)
            ?.toString()
            ?.takeIf { it.isNotBlank() }
            ?: notif.extras
                .getCharSequence(Notification.EXTRA_BIG_TEXT)
                ?.toString()
            ?: notif.tickerText?.toString()
            ?: ""

        val full = "$title\n$text"

        // Dart 로 전달
        dartChannel.invokeMethod(
            METHOD_ON_NOTIFICATION,
            mapOf(
                "packageName" to sbn.packageName,
                "title" to title,
                "text" to text
            )
        )
    }  // ← onNotificationPosted 닫는 중괄호

}  // ← 클래스 MyNotificationListener 닫는 중괄호