// lib/api/api.dart
import 'package:dio/dio.dart';
import 'package:dio/browser.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../services/navigation_service.dart';

// 조건부 import (웹이면 dart:html, 나머지는 stub)
import 'html_storage_stub.dart' if (dart.library.html) 'dart:html' as html;

import 'token_storage.dart';

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
      ..httpClientAdapter = (BrowserHttpClientAdapter()..withCredentials = true)
      ..interceptors.addAll([
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (l) => debugPrint('[DIO] $l'),
        ),
        InterceptorsWrapper(
          onRequest: (opt, handler) async {
            // 토큰 주입
            String? tok = await secureStorage.read(key: 'jwt');
            if (tok == null && kIsWeb) tok = html.window.localStorage['jwt'];
            if (tok?.isNotEmpty ?? false) {
              opt.headers['Authorization'] = 'Bearer $tok';
            }
            handler.next(opt);
          },
          onError: (e, handler) async {
            // 401 처리
            if (e.response?.statusCode == 401) {
              await secureStorage.delete(key: 'jwt');
              if (kIsWeb) html.window.localStorage.remove('jwt'); // DummyStorage에도 대응
              if (navigatorKey.currentState?.mounted ?? false) {
                navigatorKey.currentState!.pushNamedAndRemoveUntil(
                  '/login',
                  (_) => false,
                );
              }
            }
            handler.next(e);
          },
        ),
      ]);
