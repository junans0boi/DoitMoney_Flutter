// lib/core/api/dio_client.dart

import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path_provider/path_provider.dart';
import '../services/secure_storage_service.dart';

late final Dio dio;
final _secure = SecureStorageService();

/// 앱 시작 시 반드시 initDio()를 호출해야 합니다.
Future<void> initDio() async {
  final dir = await getApplicationDocumentsDirectory();
  final cj = PersistCookieJar(
    storage: FileStorage('${dir.path}/.cookies/'),
    ignoreExpires: false,
  );

  dio = Dio(
      BaseOptions(
        baseUrl: 'http://doitmoney.kro.kr/api',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        headers: {'Content-Type': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    )
    ..interceptors.addAll([
      CookieManager(cj),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (l) => debugPrint('[DIO] $l'),
      ),
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secure.read('access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (e, handler) async {
          // 401 리프레시 로직 등 필요 시 추가
          return handler.next(e);
        },
      ),
    ]);
}
