// lib/services/fixed_expense_service.dart

import 'dart:convert';
import '../api/dio_client.dart';

/// 서버 고정지출 모델
enum TransactionType { income, expense, transfer }

class FixedExpense {
  final int id;
  final int amount;
  final String category;
  final String content;
  final int dayOfMonth;
  final TransactionType transactionType;
  final int fromAccountId;
  final int? toAccountId;

  FixedExpense({
    required this.id,
    required this.amount,
    required this.category,
    required this.content,
    required this.dayOfMonth,
    required this.transactionType,
    required this.fromAccountId,
    this.toAccountId,
  });

  factory FixedExpense.fromJson(Map<String, dynamic> j) => FixedExpense(
    id: j['id'] as int,
    amount: (j['amount'] as num).toInt(),
    category: j['category'] as String,
    content: j['content'] as String? ?? '',
    dayOfMonth: j['dayOfMonth'] as int,
    transactionType: TransactionType.values.firstWhere(
      (e) => e.name == j['transactionType'],
    ),
    // API 가 fromAccountId 로 올 때도, nested object 로 올 때도
    fromAccountId:
        (j['fromAccountId'] as int?) ??
        (j['fromAccount'] is Map
            ? (j['fromAccount']['id'] as int)
            : throw StateError('fromAccountId 누락')),
    toAccountId:
        (j['toAccountId'] as int?) ??
        (j['toAccount'] is Map ? (j['toAccount']['id'] as int) : null),
  );

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'category': category,
    'content': content,
    'dayOfMonth': dayOfMonth,
    'transactionType': transactionType.name,
    'fromAccountId': fromAccountId,
    'toAccountId': toAccountId,
  };
}

class FixedExpenseService {
  /// 고정지출 목록 조회
  static Future<List<FixedExpense>> fetchFixedExpenses() async {
    final res = await dio.get('/fixed-expenses');

    // 서버가 plain String 으로 JSON array 를 내려줄 수도 있기 때문에
    // String 이면 decode, 아니면 바로 List 로 캐스트
    final raw = res.data;
    final List<dynamic> arr =
        raw is String ? jsonDecode(raw) as List<dynamic> : raw as List<dynamic>;

    return arr
        .map((e) => FixedExpense.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 신규 고정지출 등록
  static Future<FixedExpense> addFixedExpense(FixedExpense fe) async {
    final res = await dio.post('/fixed-expenses', data: fe.toJson());
    final raw = res.data;
    final Map<String, dynamic> obj =
        raw is String
            ? jsonDecode(raw) as Map<String, dynamic>
            : raw as Map<String, dynamic>;
    return FixedExpense.fromJson(obj);
  }

  /// 고정지출 수정
  static Future<FixedExpense> updateFixedExpense(FixedExpense fe) async {
    final res = await dio.put('/fixed-expenses/${fe.id}', data: fe.toJson());
    final raw = res.data;
    final Map<String, dynamic> obj =
        raw is String
            ? jsonDecode(raw) as Map<String, dynamic>
            : raw as Map<String, dynamic>;
    return FixedExpense.fromJson(obj);
  }

  /// 고정지출 삭제
  static Future<void> deleteFixedExpense(int id) async {
    await dio.delete('/fixed-expenses/$id');
  }
}
