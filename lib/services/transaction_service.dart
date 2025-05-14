//DoitMoney_Flutter/lib/services/transaction_service.dart

import '../api/api.dart';

/// 거래 모델
class Transaction {
  final int id;
  final DateTime transactionDate;
  final int amount;
  final String description;
  final String accountName;

  Transaction({
    required this.id,
    required this.transactionDate,
    required this.amount,
    required this.description,
    required this.accountName,
  });

  // <거래 조회 즉 불러오기 >JSON 데이터를 Dart 객체로 바꾸는 생성자 [서버로부터 json데이터  dart로 받아오기]
  factory Transaction.fromJson(Map<String, dynamic> j) {
    return Transaction(
      id: j['id'] as int,
      transactionDate: DateTime.parse(j['transactionDate'] as String),
      amount: (j['amount'] as num).toInt(),
      description: j['description'] as String? ?? '',
      accountName: j['accountName'] as String? ?? '',
    );
  }
  // <거래 추가> Dart 객체를 JSON 형태로 변환하는 메서드 [dart에서 DB로 보내기 위해 json으로 변환]
  Map<String, dynamic> toJson() => {
    'transactionDate': transactionDate.toIso8601String(),
    'amount': amount,
    'description': description,
    'accountName': accountName,
  };
}

/// Transaction API 서비스
class TransactionService {
  /// 거래 목록 조회
  static Future<List<Transaction>> fetchTransactions() async {
    final res = await dio.get('/transactions');
    return (res.data as List)
        .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 거래 추가
  static Future<Transaction> addTransaction(Transaction tx) async {
    final res = await dio.post('/transactions', data: tx.toJson());
    return Transaction.fromJson(res.data as Map<String, dynamic>);
  }

  /// 거래 수정
  static Future<Transaction> updateTransaction(int id, Transaction tx) async {
    final res = await dio.put('/transactions/$id', data: tx.toJson());
    return Transaction.fromJson(res.data as Map<String, dynamic>);
  }

  /// 거래 삭제
  static Future<void> deleteTransaction(int id) async {
    await dio.delete('/transactions/$id');
  }
}
