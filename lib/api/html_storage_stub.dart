// lib/api/html_storage_stub.dart
// ── Non-web 플랫폼에서 dart:html 대체 ──
class DummyStorage {
  final _map = <String, String?>{};

  String? operator [](String key) => _map[key];
  void operator []=(String key, String? value) => _map[key] = value;
  void remove(String key) => _map.remove(key); // ← remove 추가
}

class DummyWindow {
  final DummyStorage localStorage = DummyStorage();
}

final DummyWindow window = DummyWindow();        // 단일 window 정의