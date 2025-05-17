import 'package:dio/dio.dart' show DioException; // ← DioException 용
import '../api/dio_client.dart';

class AuthService {
  /// 로그인 : 200 OK 만 확인하면 쿠키가 세션을 관리합니다
  static Future<bool> login(String email, String password) async {
    try {
      final res = await dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return res.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  /// 로그아웃
  static Future<void> logout() async {
    await dio.post('/auth/logout'); // SecurityConfig 의 logoutUrl
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
