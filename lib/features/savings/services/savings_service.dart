// lib/features/savings/services/savings_service.dart
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../models/savings_goal.dart';

class SavingsService {
  static Future<List<SavingsGoal>> fetchGoals() async {
    final res = await dio.get('/savings/goals');
    return (res.data as List)
        .map((j) => SavingsGoal.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<SavingsGoal> createGoal({
    required String title,
    required int targetAmount,
    required int targetAccountId,
  }) async {
    final res = await dio.post(
      '/savings/goals',
      data: {
        'title': title,
        'targetAmount': targetAmount,
        'targetAccountId': targetAccountId,
      },
    );
    return SavingsGoal.fromJson(res.data as Map<String, dynamic>);
  }

  static Future<SavingsGoal> updateGoal({
    required int id,
    required String title,
    required int targetAmount,
    required int targetAccountId,
  }) async {
    final res = await dio.put(
      '/savings/goals/$id',
      data: {
        'title': title,
        'targetAmount': targetAmount,
        'targetAccountId': targetAccountId,
      },
    );
    return SavingsGoal.fromJson(res.data as Map<String, dynamic>);
  }

  static Future<void> deleteGoal(int id) async {
    final res = await dio.delete('/savings/goals/$id');
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception('삭제 실패: ${res.statusCode}');
    }
  }
}
