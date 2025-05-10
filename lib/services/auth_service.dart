// lib/services/auth_service.dart

import 'package:dio/dio.dart';
import '../api/api.dart';

class AuthService {
  // ─── 로그인 ───
  static Future<bool> login(String email, String password) async {
    try {
      final res = await dio.post(
        '/user/login', // ← 수정: /login → /user/login
        data: {'email': email, 'password': password},
      );

      // 상태 코드가 200 이면 body에서 success 필드를 꺼내고,
      // 그렇지 않으면 false 리턴
      if (res.statusCode == 200) {
        return (res.data['success'] ?? false) as bool;
      } else {
        return false;
      }
    } catch (e) {
      // 네트워크 에러 등
      return false;
    }
  }

  // 이메일 중복 체크
  static Future<bool> checkEmailAvailable(String email) async {
    final res = await dio.get(
      '/check-email', // ← /api 뺀 상대경로
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
    await dio.post(
      '/auth/register', // ← 반드시 '/' 로 시작해야 baseUrl+'/auth/register'이 됩니다.
      data: {
        'email': email,
        'code': code,
        'phone': phone,
        'password': password,
        'username': username,
      },
    );
  }

  // ─── 전화번호 중복 체크 ───
  static Future<bool> checkPhoneAvailable(String phone) async {
    try {
      final res = await dio.get(
        '/check-phone',
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
