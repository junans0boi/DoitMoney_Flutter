// lib/providers/auth_provider.dart
import 'package:doitmoney_flutter/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../api/token_storage.dart';
import '../api/html_storage_stub.dart'
    if (dart.library.html) 'dart:html'
    as html;
import '../api/api.dart';

final authProvider = StateNotifierProvider<AuthController, bool>(
  (ref) => AuthController()..bootstrap(),
);

class AuthController extends StateNotifier<bool> {
  AuthController() : super(false);

  /* 앱 시작·재시작마다 호출 */
  Future<void> bootstrap() async {
    String? tok = await secureStorage.read(key: 'jwt');
    if (tok == null && kIsWeb) tok = html.window.localStorage['jwt'];

    if (tok != null) {
      dio.options.headers['Authorization'] = 'Bearer $tok';
      state = true; // ← 로그인 상태
    }
  }

  /* 로그인 성공 시 호출 */
  Future<bool> signIn(String id, String pw) async {
    final ok = await AuthService.login(id, pw);
    if (ok) state = true;
    return ok;
  }

  /* 로그아웃 */
  Future<void> signOut() async {
    await secureStorage.delete(key: 'jwt');
    if (kIsWeb) html.window.localStorage.remove('jwt');
    dio.options.headers.remove('Authorization');
    state = false;
  }
}
