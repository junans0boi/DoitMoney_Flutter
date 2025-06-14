package com.example.doitmoney_flutter

import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache           // ← 이 줄 추가
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    companion object {
      const val CHANNEL = "doitmoney.flutter.dev/notification"
      const val METHOD_OPEN_SETTINGS = "openNotificationSettings"
      const val ENGINE_ID = "doitmoney_engine"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
      super.configureFlutterEngine(flutterEngine)

      // 1) 메인 FlutterEngine 을 캐시에 저장
      FlutterEngineCache
        .getInstance()
        .put(ENGINE_ID, flutterEngine)

      // 2) Dart ↔ Native 채널 등록
      MethodChannel(
        flutterEngine.dartExecutor.binaryMessenger,
        CHANNEL
      ).setMethodCallHandler { call, result ->
        if (call.method == METHOD_OPEN_SETTINGS) {
          val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
          intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
          startActivity(intent)
          result.success(null)
        } else {
          result.notImplemented()
        }
      }
    }
}