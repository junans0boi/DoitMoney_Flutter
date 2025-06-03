// lib/features/advisor/services/advisor_service.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../models/advisor_model.dart';

class AdvisorService {
  final Dio _dio = dio;

  /// AI 어드바이저 요청
  Future<AdvisorResponse> fetchAdvisor({
    String? questionKey,
    String? userInput,
  }) async {
    final req = AdvisorRequest(questionKey: questionKey, userInput: userInput);
    final resp = await _dio.post('/ai/advisor', data: req.toJson());
    return AdvisorResponse.fromJson(resp.data as Map<String, dynamic>);
  }

  /// 과거 대화 내역 조회
  Future<List<ChatHistoryItem>> fetchChatHistory() async {
    final resp = await _dio.get('/ai/history');
    final List<dynamic> data = resp.data as List<dynamic>;
    return data
        .map((e) => ChatHistoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
