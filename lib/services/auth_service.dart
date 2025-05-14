import 'package:dio/dio.dart' show DioException; // ← DioException 용
import '../api/api.dart'; // dio 인스턴스
import '../api/token_storage.dart'; // secureStorage
import 'package:flutter/foundation.dart' show kIsWeb;
import '../api/html_storage_stub.dart'
    if (dart.library.html) 'dart:html'
    as html;

class AuthService {
  // ─── 로그인 ───
  static Future<bool> login(String email, String password) async {
    // 로그인 요청 전, 기존에 남은 만료 토큰 삭제
    await secureStorage.delete(key: 'jwt');
    if (kIsWeb) html.window.localStorage.remove('jwt');
    try {
      final res = await dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (res.data['success'] != true) return false;

      final token = res.data['token'] as String;

      // 1) 토큰 저장
      await secureStorage.write(key: 'jwt', value: token).catchError((_) {});
      if (kIsWeb) {
        html.window.localStorage['jwt'] = token;
      }

      return true;
    } on DioException {
      return false;
    }
  }

  // 이메일 중복 체크
  static Future<bool> checkEmailAvailable(String email) async {
    final res = await dio.get(
      '/user/check-email',
      queryParameters: {'email': email},
    );

    return res.data['available'] as bool;
  }

  static Future<void> sendVerificationCode(String email) async {
    await dio.post(
      '/auth/send-verification', // ← /api 뺀 상대경로
      data: {'email': email},
    );
  }

  // 인증번호 검증
  static Future<bool> verifyCode(String email, String code) async {
    final res = await dio.post(
      '/auth/verify', // ← '/api' 중복 제거
      data: {'email': email, 'code': code},
    );
    return res.data['verified'] as bool;
  }

  // 최종 회원가입
  /// 3) 최종 회원가입
  static Future<void> register({
    required String email,
    required String code,
    required String phone,
    required String password,
    required String username,
  }) async {
    try {
      await dio.post(
        '/auth/register',
        data: {
          'email': email,
          'code': code,
          'phone': phone,
          'password': password,
          'username': username,
        },
      );
    } on DioException catch (e) {
      // 백엔드가 {"message":"..."} 형태로 내려주면 그대로 꺼냄
      final data = e.response?.data;
      final msg =
          (data is Map && data['message'] != null)
              ? data['message'] as String
              : '회원가입 실패 (${e.response?.statusCode ?? ''})';
      throw Exception(msg);
    }
  }

  // ─── 전화번호 중복 체크 ───
  static Future<bool> checkPhoneAvailable(String phone) async {
    try {
      final res = await dio.get(
        '/user/check-phone',
        queryParameters: {'phone': phone},
      );
      return res.data['available'] as bool;
    } on DioException {
      return false;
    }
  }

  // ─── ID(이메일) 찾기 ───
  static Future<String?> findIdByPhone(String phone) async {
    try {
      final res = await dio.get(
        '/recover/find-id',
        queryParameters: {'phone': phone},
      );
      final masked = res.data['email'] as String;
      return masked.isEmpty ? null : masked;
    } on DioException {
      return null;
    }
  }

  // ─── 비밀번호 재설정 메일 발송 ───
  static Future<void> sendResetMail(String email) async {
    try {
      final res = await dio.post('/recover/reset-mail', data: {'email': email});
      if (res.statusCode != 200) {
        throw Exception('재설정 메일 발송 실패 (status ${res.statusCode})');
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception(
        '재설정 메일 발송 실패${status != null ? " (HTTP $status)" : ""}'
        '${data != null ? ": $data" : ""}',
      );
    }
  }

  // ─── 비밀번호 재설정 ───
  static Future<void> resetPassword(String token, String password) async {
    try {
      final res = await dio.post(
        '/recover/reset-password',
        data: {'token': token, 'password': password},
      );
      if (res.statusCode != 200) {
        throw Exception('비밀번호 재설정 실패 (status ${res.statusCode})');
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception(
        '비밀번호 재설정 실패${status != null ? " (HTTP $status)" : ""}'
        '${data != null ? ": $data" : ""}',
      );
    }
  }
}
