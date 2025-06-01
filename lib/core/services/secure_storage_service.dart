// lib/core/services/secure_storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// FlutterSecureStorage를 감싸서 간단한 읽기/쓰기/삭제 API를 제공합니다.
class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  /// 키-값 저장
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// 키로 값 읽기 (없으면 null)
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  /// 키 삭제
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// 모든 키-값 삭제 (로그아웃 등)
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
