// lib/features/chart/services/chart_service.dart

import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';

class ChartService {
  final Dio _dio = dio;

  /// 최근 monthsBack 개월 월별 지출 합계
  Future<Map<String, dynamic>> fetchMonthlyExpenses({
    int monthsBack = 3,
  }) async {
    final resp = await _dio.get(
      '/transactions/chart/monthly',
      queryParameters: {'monthsBack': monthsBack},
    );
    return Map<String, dynamic>.from(resp.data as Map);
  }

  /// 특정 연·월(year, month)의 카테고리별 지출 합계
  Future<Map<String, dynamic>> fetchCategoryExpenses({
    required int year,
    required int month,
  }) async {
    final resp = await _dio.get(
      '/transactions/chart/category',
      queryParameters: {'year': year, 'month': month},
    );
    return Map<String, dynamic>.from(resp.data as Map);
  }
}
