// lib/services/secure_storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  /// 키-값 저장
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// 키로 읽기 (값이 없으면 null)
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  /// 키 삭제
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// 모든 키·값 삭제 (로그아웃 등)
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
