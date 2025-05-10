// lib/api/api.dart

import 'package:dio/dio.dart';

final dio = Dio(
  BaseOptions(
    baseUrl: 'http://doitmoney.kro.kr/api',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
    headers: {'Content-Type': 'application/json'},
    // ← this prevents Dio from throwing on 403
    validateStatus: (status) => status != null && status < 500,
  ),
)
..interceptors.add(
  LogInterceptor(
    requestBody: true,
    responseBody: true,
    logPrint: (line) => print('[DIO] $line'),
  ),
);