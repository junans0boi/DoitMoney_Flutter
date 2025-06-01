// lib/features/more/services/customer_service.dart

import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';

class CustomerService {
  /// 사용자 문의를 서버로 전송
  static Future<void> sendInquiry({
    required String userEmail,
    required String subject,
    required String content,
  }) async {
    final data = {
      'userEmail': userEmail,
      'subject': subject,
      'content': content,
    };
    final res = await dio.post('/contact', data: data);
    if (res.statusCode != 200) {
      throw Exception('문의 전송 실패 (${res.statusCode})');
    }
  }
}
