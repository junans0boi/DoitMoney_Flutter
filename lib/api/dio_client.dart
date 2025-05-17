// lib/api/dio_client.dart
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart' show debugPrint;

final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'http://doitmoney.kro.kr/api',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (s) => s != null && s < 500,
    ),
  )
  ..interceptors.addAll([
    // 앱(모바일·데스크톱) ― 세션 쿠키 로컬 저장
    CookieManager(CookieJar()), // 메모리만 써도 충분 (Persist 쓰시려면 경로 지정)
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (l) => debugPrint('[DIO] $l'),
    ),
  ]);
