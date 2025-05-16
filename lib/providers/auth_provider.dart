// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api.dart';
import '../services/auth_service.dart';

/// <로그인 여부>만 관리하는 StateNotifier<bool>
final authProvider = StateNotifierProvider<AuthController, bool>(
  (ref) => AuthController()..bootstrap(),
);

class AuthController extends StateNotifier<bool> {
  AuthController() : super(false); // 초기값: 미로그인(false)

  /* 앱 시작·재시작마다 호출 */
  Future<void> bootstrap() async {
    try {
      // 세션이 살아 있으면 200, 없으면 401
      final res = await dio.get('/user/me');
      state = res.statusCode == 200;
    } catch (_) {
      state = false;
    }
  }

  /* 로그인 */
  Future<bool> signIn(String id, String pw) async {
    final ok = await AuthService.login(id, pw); // 200이면 ok == true
    if (ok) state = true; // ✅ 로그인 상태 저장
    return ok;
  }

  /* 로그아웃 */
  Future<void> signOut() async {
    await AuthService.logout(); // 세션 쿠키 파기
    state = false; // ✅ 로그아웃 상태 저장
  }
}
