// lib/providers/user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

/// 로그인 상태에서 사용자의 프로필 정보를 관리하는 Provider
class UserNotifier extends StateNotifier<UserProfile?> {
  final Ref ref;
  UserNotifier(this.ref) : super(null) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final profile = await AuthService.fetchProfile();
      state = profile;
    } catch (_) {
      state = null;
    }
  }

  void clear() {
    state = null;
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserProfile?>(
  (ref) => UserNotifier(ref),
);
