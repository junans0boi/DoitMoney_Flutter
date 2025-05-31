// lib/utils/go_router_refresh_stream.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

/// go_router 의 refreshListenable 인자로 넘길 수 있는 간단 util.
/// 아무 값이든 stream 에 이벤트가 오면 Router 가 rebuild 된다.
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
