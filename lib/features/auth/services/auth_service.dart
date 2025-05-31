// lib/services/auth_service.dart
import 'package:dio/dio.dart' show DioException;
import '../api/dio_client.dart';
import 'secure_storage_service.dart';

/// 백엔드로부터 받아오는 사용자 프로필 데이터 구조
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
  static final _secure = SecureStorageService();

  /// 1) 로그인
  static Future<bool> login(String email, String password) async {
    final res = await dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    if (res.statusCode != 200) return false;

    // 만약 accessToken이 body에 있으면 secure storage에 저장
    if (res.data is Map<String, dynamic> && res.data['accessToken'] is String) {
      await _secure.write('access_token', res.data['accessToken']);
    }
    return true;
  }

  /// 2) 내 프로필 조회
  static Future<UserProfile> fetchProfile() async {
    final res = await dio.get('/user/me');
    if (res.statusCode != 200) throw Exception('프로필 조회 실패');
    return UserProfile.fromJson(res.data as Map<String, dynamic>);
  }

  /// 3) 로그아웃
  static Future<void> logout() async {
    await dio.post('/auth/logout');
    await _secure.deleteAll();
  }

  /// 저장된 토큰 가져오기
  static Future<String?> get accessToken async {
    return await _secure.read('access_token');
  }

  /// ─── 회원가입 흐름 ───
  /// 이메일 중복 체크
  static Future<bool> checkEmailAvailable(String email) async {
    final res = await dio.get(
      '/user/check-email',
      queryParameters: {'email': email},
    );
    return res.data['available'] as bool;
  }

  /// 회원가입용 인증번호(코드) 요청
  static Future<void> sendVerificationCode(String email) async {
    final res = await dio.post(
      '/auth/send-verification',
      data: {'email': email},
    );
    if (res.statusCode != 200) {
      throw Exception('인증번호 요청 실패 (${res.statusCode})');
    }
  }

  /// 회원가입용 인증번호(코드) 검증
  static Future<bool> verifyCode(String email, String code) async {
    final res = await dio.post(
      '/auth/verify',
      data: {'email': email, 'code': code},
    );
    return res.data['verified'] as bool;
  }

  /// 회원가입 최종 완료
  static Future<void> register({
    required String email,
    required String code,
    required String phone,
    required String password,
    required String username,
  }) async {
    try {
      final res = await dio.post(
        '/auth/register',
        data: {
          'email': email,
          'code': code,
          'phone': phone,
          'password': password,
          'username': username,
        },
      );
      if (res.statusCode != 200) {
        final data = res.data;
        final m =
            (data is Map && data['message'] != null)
                ? data['message']
                : (data is Map && data['error'] != null)
                ? data['error']
                : '(${res.statusCode})';
        throw Exception(m);
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg =
          (data is Map && data['message'] != null)
              ? data['message']
              : (data is Map && data['error'] != null)
              ? data['error']
              : e.response?.statusMessage ?? '알 수 없는 오류';
      throw Exception(msg);
    }
  }

  /// ─── 전화번호 중복 체크 ───
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

  /// ─── 아이디(이메일) 찾기 ───
  static Future<String?> findIdByPhone(String phone) async {
    try {
      final res = await dio.get(
        '/recover/find-id',
        queryParameters: {'phone': phone},
      );
      // 백엔드에서 { "email": "" } 으로 리턴할 수 있으므로
      final masked = res.data['email'] as String;
      return masked.isEmpty ? null : masked;
    } on DioException {
      return null;
    }
  }

  /// ─── 비밀번호 재설정 흐름 ───

  /// 1) 비밀번호 재설정용 인증번호(코드) 요청
  static Future<void> sendResetMail(String email) async {
    final res = await dio.post('/recover/reset-mail', data: {'email': email});
    if (res.statusCode != 200) {
      throw Exception('인증번호 발송 실패 (${res.statusCode})');
    }
  }

  /// 2) 비밀번호 재설정용 인증번호(코드) 검증
  static Future<bool> verifyResetCode({
    required String email,
    required String code,
  }) async {
    final res = await dio.post(
      '/recover/verify-reset-code',
      data: {'email': email, 'code': code},
    );
    return res.statusCode == 200;
  }

  /// 3) 비밀번호 재설정 (새 비밀번호 저장)
  static Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    final res = await dio.post(
      '/recover/reset-password',
      data: {'email': email, 'code': code, 'password': password},
    );
    if (res.statusCode != 200) {
      throw Exception('비밀번호 재설정 실패 (${res.statusCode})');
    }
  }
}
