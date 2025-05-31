// lib/api/dio_client.dart
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart'; // ← 여기서 PersistCookieJar 가져옴
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path_provider/path_provider.dart';
import '../services/secure_storage_service.dart';

late final Dio dio;
final _secure = SecureStorageService();

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
        validateStatus: (s) => s != null && s < 500,
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
          // (선택) 401 리프레시 로직 등 추가 가능
          return handler.next(e);
        },
      ),
    ]);
}
