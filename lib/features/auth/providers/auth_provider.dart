import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/dio_client.dart';
import '../services/auth_service.dart';
import 'user_provider.dart';

final authProvider = StateNotifierProvider<AuthController, bool>(
  (ref) => AuthController(ref)..bootstrap(),
);

class AuthController extends StateNotifier<bool> {
  final Ref ref;
  AuthController(this.ref) : super(false);

  Future<void> bootstrap() async {
    try {
      final res = await dio.get('/user/me');
      if (res.statusCode == 200) {
        await ref.read(userProvider.notifier).loadProfile();
        state = true;
      } else {
        state = false;
      }
    } catch (_) {
      state = false;
    }
  }

  Future<bool> signIn(String email, String pw) async {
    final ok = await AuthService.login(email, pw);
    if (ok) {
      await ref.read(userProvider.notifier).loadProfile();
      state = true;
    }
    return ok;
  }

  Future<void> signOut() async {
    await AuthService.logout();
    ref.read(userProvider.notifier).clear();
    state = false;
  }
}
