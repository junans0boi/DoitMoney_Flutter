// lib/services/user_service.dart
import 'package:dio/dio.dart';
import '../api/dio_client.dart';

/// 로그인된 사용자가 "현재 비밀번호 / 새 비밀번호" 로 비밀번호를 변경할 때 호출되는 서비스
class UserService {
  /// "/api/user/me/change-password" 엔드포인트 호출
  static Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final res = await dio.post(
        '/user/me/change-password',
        data: {'oldPassword': oldPassword, 'newPassword': newPassword},
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
              : e.response?.statusMessage ?? '알 수 없는 오류';
      throw Exception(msg);
    }
  }
}
