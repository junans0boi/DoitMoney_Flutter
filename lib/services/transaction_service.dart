// lib/services/transaction_service.dart
import '../api/dio_client.dart';

/// 거래 유형 열거형
enum TransactionType { income, expense, transfer }

/// 거래 모델
class Transaction {
  final int id;
  final DateTime transactionDate;
  final TransactionType transactionType;
  final String category;
  final int amount;
  final String description;
  final String accountName;
  final String accountNumber;

  Transaction({
    required this.id,
    required this.transactionDate,
    required this.transactionType,
    required this.category,
    required this.amount,
    required this.description,
    required this.accountName,
    required this.accountNumber,
  });

  /// 서버로부터 받은 JSON → Dart 객체
  factory Transaction.fromJson(Map<String, dynamic> j) {
    return Transaction(
      id: j['id'] as int,
      transactionDate: DateTime.parse(j['transactionDate'] as String),
      transactionType: TransactionType.values.firstWhere(
        (e) => e.name == (j['transactionType'] as String),
        orElse: () => TransactionType.expense,
      ),
      category: j['category'] as String? ?? '',
      amount: (j['amount'] as num).toInt(),
      description: j['description'] as String? ?? '',
      accountName: j['accountName'] as String? ?? '',
      accountNumber: j['accountNumber'] as String? ?? '',
    );
  }

  /// Dart 객체 → 서버로 보낼 JSON
  Map<String, dynamic> toJson() => {
    'transactionDate': transactionDate.toIso8601String(),
    'transactionType': transactionType.name,
    'category': category,
    'amount': amount,
    'description': description,
    'accountName': accountName,
    'accountNumber': accountNumber,
  };
}

/// Transaction API 서비스
class TransactionService {
  static Future<List<Transaction>> fetchTransactions() async {
    final res = await dio.get('/transactions');
    return (res.data as List)
        .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Transaction> addTransaction(Transaction tx) async {
    final res = await dio.post('/transactions', data: tx.toJson());
    return Transaction.fromJson(res.data as Map<String, dynamic>);
  }

  static Future<Transaction> updateTransaction(int id, Transaction tx) async {
    final res = await dio.put('/transactions/$id', data: tx.toJson());
    return Transaction.fromJson(res.data as Map<String, dynamic>);
  }

  static Future<void> deleteTransaction(int id) async {
    final res = await dio.delete('/transactions/$id');
    if (res.statusCode != 204) {
      throw Exception('삭제 실패: ${res.statusCode}');
    }
  }
}
