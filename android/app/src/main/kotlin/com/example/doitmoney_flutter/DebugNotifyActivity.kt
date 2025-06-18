// android/app/src/main/java/com/example/doitmoney_flutter/DebugNotifyActivity.kt
package com.example.doitmoney_flutter

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import android.widget.Button
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.NotificationCompat

class DebugNotifyActivity : AppCompatActivity() {

    companion object {
        private const val CH_ID = "debug_kakao"
        private const val CH_NAME = "디버그 알림 채널"
        private const val TEST_ID = 2001     // 포그라운드 ID와 겹치지 않게

    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val btn = Button(this).apply { text = "카카오뱅크 입금 알림 보내기" }
        setContentView(btn)

        val nm = getSystemService(NotificationManager::class.java)

        // ── Android O+ 채널 생성: 잠금화면에서 민감한 콘텐츠도 공개하도록 설정 ──
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val existing = nm.getNotificationChannel(CH_ID)
            if (existing == null) {
                val ch = NotificationChannel(
                    CH_ID,
                    CH_NAME,
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "디버그용 카카오뱅크 테스트 채널"
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC  // ★ 핵심
                }
                nm.createNotificationChannel(ch)
            } else if (existing.lockscreenVisibility != Notification.VISIBILITY_PUBLIC) {
                // 이미 채널이 있지만 visibility 가 PRIVATE 라면 재생성
                nm.deleteNotificationChannel(CH_ID)
                NotificationChannel(CH_ID, CH_NAME, NotificationManager.IMPORTANCE_HIGH).apply {
                    description = "디버그용 카카오뱅크 테스트 채널"
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                }.also { nm.createNotificationChannel(it) }
            }
        }

        btn.setOnClickListener {
            val noti = NotificationCompat.Builder(this, CH_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle("카카오뱅크")
                .setContentText("입금 3,500원")               // 한 줄 요약
                .setStyle(
                    NotificationCompat.BigTextStyle().bigText(
                        "입금 3,500원  김신혁 → 내 입출금통장(2856)"
                    )
                )
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .build()

            nm.notify(TEST_ID, noti)
        }
    }
}