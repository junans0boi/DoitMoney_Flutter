// lib/core/utils/go_router_refresh_stream.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

/// go_router 의 refreshListenable 인자로 넘길 수 있는 간단 util.
/// 내부적으로 Stream을 구독하고, 새 이벤트가 들어오면 notifyListeners()를 호출합니다.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
