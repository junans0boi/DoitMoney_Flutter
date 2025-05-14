import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 유저 모델 예시
class User {
  final String name;
  final String email;

  User({required this.name, required this.email});
}

/// 사용자 상태 관리용 Notifier
class UserNotifier extends StateNotifier<User?> {
  UserNotifier() : super(null);

  void login(User user) {
    state = user;
  }

  void logout() {
    state = null;
  }
}

/// 전역에서 사용할 provider
final userProvider = StateNotifierProvider<UserNotifier, User?>(
  (ref) => UserNotifier(),
);
