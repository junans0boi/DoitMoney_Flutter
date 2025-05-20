import 'package:dio/dio.dart' show DioException;
import '../api/dio_client.dart';
import 'secure_storage_service.dart';

class UserProfile {
  final int userId;
  final String email;
  final String username;
  final String phone;
  final String profileImageUrl;

  UserProfile({
    required this.userId,
    required this.email,
    required this.username,
    required this.phone,
    required this.profileImageUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    userId: j['userId'] as int,
    email: j['email'] as String,
    username: j['username'] as String,
    phone: j['phone'] as String,
    profileImageUrl: j['profileImageUrl'] as String? ?? '',
  );
}

class AuthService {
  /// 로그인
  static final _secure = SecureStorageService();

  static Future<bool> login(String email, String password) async {
    final res = await dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    if (res.statusCode != 200) return false;

    // only write a token if the body is a JSON map containing accessToken
    if (res.data is Map<String, dynamic> && res.data['accessToken'] is String) {
      await _secure.write('access_token', res.data['accessToken']);
    }

    return true;
  }

  /// 내 프로필 조회
  static Future<UserProfile> fetchProfile() async {
    final res = await dio.get('/user/me');
    if (res.statusCode != 200) throw Exception('프로필 조회 실패');
    return UserProfile.fromJson(res.data as Map<String, dynamic>);
  }

  /// 로그아웃
  static Future<void> logout() async {
    await dio.post('/auth/logout');
    // 로그아웃 땐 secure storage 비우기
    await _secure.deleteAll();
  }

  /// 저장된 토큰 불러오기
  static Future<String?> get accessToken async {
    return await _secure.read('access_token');
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
