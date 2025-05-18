import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart'; // <-- UserProfile 를 여기서 가져옵니다.

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
