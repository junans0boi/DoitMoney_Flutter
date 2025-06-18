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
import io.flutter.plugin.common.MethodChannel
import android.util.Log  

@TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
class MyNotificationListener : NotificationListenerService() {
    companion object {
        const val CHANNEL_ID = "doitmoney_notification_listener"
        const val CHANNEL_NAME = "DoitMoney 알림 수집"
        const val FOREGROUND_ID = 1001
        const val ENGINE_ID = "doitmoney_engine"
        const val DART_CHANNEL = "doitmoney.flutter.dev/notification"
        const val METHOD_ON_NOTIFICATION = "onNotificationPosted"
    }

    private lateinit var dartChannel: MethodChannel

    override fun onCreate() {
        super.onCreate()
        // lockscreenVisibility 공개로
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel(CHANNEL_ID, CHANNEL_NAME, NotificationManager.IMPORTANCE_LOW).apply {
                description = "앱이 꺼져도 알림을 수집"
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }.also { ch ->
                (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                  .createNotificationChannel(ch)
            }
        }
        // FlutterEngine 캐싱 로직은 그대로…
        val engine = FlutterEngineCache.getInstance().get(ENGINE_ID)
            ?: throw IllegalStateException("FlutterEngine not found")
        dartChannel = MethodChannel(engine.dartExecutor.binaryMessenger, DART_CHANNEL)

        // 포그라운드 서비스 알림도 PUBLIC 으로
        startForeground(
            FOREGROUND_ID,
            NotificationCompat.Builder(this, CHANNEL_ID)
              .setContentTitle("DoitMoney 알림 수집 중")
              .setContentText("앱이 종료되어도 수집합니다")
              .setSmallIcon(R.mipmap.ic_launcher)
              .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
              .build()
        )
    }

    // ⚠ 여기서 override fun 키워드를 중복 쓰지 마세요
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val ex = sbn.notification.extras
        val title       = ex.getString(Notification.EXTRA_TITLE) ?: ""
        val textSummary = ex.getCharSequence(Notification.EXTRA_TEXT)?.toString().orEmpty()
        val textBig     = ex.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString().orEmpty()

        // BigTextStyle 의 내용을 우선 쓰도록
        val fullText = listOf(title, textBig.ifBlank { textSummary })
            .filter { it.isNotBlank() }
            .joinToString("\n")

        Log.d("NLS", "📲 raw -> $fullText")
        dartChannel.invokeMethod(
            METHOD_ON_NOTIFICATION,
            mapOf(
                "packageName" to sbn.packageName,
                "fullText"     to fullText
            )
        )
    }
}