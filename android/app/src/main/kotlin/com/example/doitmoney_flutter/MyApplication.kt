// android/app/src/main/kotlin/com/example/doitmoney_flutter/MyApplication.kt
package com.example.doitmoney_flutter

import android.app.Application
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.FlutterEngineCache

class MyApplication : Application() {
  companion object {
    const val ENGINE_ID = "doitmoney_engine"
  }

  override fun onCreate() {
    super.onCreate()

    // 1) 새로운 FlutterEngine 생성
    val engine = FlutterEngine(this)

    // 2) Dart 진입점 실행 (main.dart 의 default entrypoint)
    engine.dartExecutor.executeDartEntrypoint(
      DartExecutor.DartEntrypoint.createDefault()
    )

    // 3) 캐시에 저장
    FlutterEngineCache
      .getInstance()
      .put(ENGINE_ID, engine)
  }
}