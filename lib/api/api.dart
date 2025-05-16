// lib/api/api.dart
import 'package:dio/dio.dart';
import 'package:dio/browser.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// ─────────────────────────────────────────────
final Dio dio =
    Dio(
        BaseOptions(
          baseUrl: 'http://doitmoney.kro.kr/api',
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {'Content-Type': 'application/json'},
          validateStatus: (s) => s != null && s < 500,
        ),
      )
      // 세션 쿠키를 자동으로 붙이도록
      ..httpClientAdapter = (BrowserHttpClientAdapter()..withCredentials = true)
      // 로그만 남겨줄 Interceptor
      ..interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (l) => debugPrint('[DIO] $l'),
        ),
      );
