import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import '../../../core/api/dio_client.dart';

enum TransactionType { income, expense, transfer }

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

  Transaction copyWith({
    int? id,
    DateTime? transactionDate,
    TransactionType? transactionType,
    String? category,
    int? amount,
    String? description,
    String? accountName,
    String? accountNumber,
  }) => Transaction(
    id: id ?? this.id,
    transactionDate: transactionDate ?? this.transactionDate,
    transactionType: transactionType ?? this.transactionType,
    category: category ?? this.category,
    amount: amount ?? this.amount,
    description: description ?? this.description,
    accountName: accountName ?? this.accountName,
    accountNumber: accountNumber ?? this.accountNumber,
  );

  factory Transaction.fromJson(Map<String, dynamic> j) => Transaction(
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

class TransactionService {
  static Future<List<Transaction>> fetchTransactions() async {
    try {
      final res = await dio.get('/transactions');
      return (res.data as List)
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioError catch (e) {
      // 로깅
      debugPrint('[FetchTx Error] ${e.response?.statusCode}: ${e.message}');
      // 사용자에게 알림
      throw Exception('거래 내역 로드에 실패했습니다.');
    }
  }

  static Future<Transaction> addTransaction(Transaction tx) async {
    try {
      final res = await dio.post('/transactions', data: tx.toJson());
      return Transaction.fromJson(res.data as Map<String, dynamic>);
    } on DioError catch (e) {
      debugPrint('[AddTx Error] ${e.response?.statusCode}: ${e.message}');
      throw Exception('거래 추가에 실패했습니다.');
    }
  }

  static Future<Transaction> updateTransaction(int id, Transaction tx) async {
    try {
      final res = await dio.put('/transactions/$id', data: tx.toJson());
      return Transaction.fromJson(res.data as Map<String, dynamic>);
    } on DioError catch (e) {
      debugPrint('[UpdateTx Error] ${e.response?.statusCode}: ${e.message}');
      throw Exception('거래 수정에 실패했습니다.');
    }
  }

  static Future<void> deleteTransaction(int id) async {
    try {
      final res = await dio.delete('/transactions/$id');
      if (res.statusCode != 204) {
        throw Exception();
      }
    } on DioError catch (e) {
      debugPrint('[DeleteTx Error] ${e.response?.statusCode}: ${e.message}');
      throw Exception('거래 삭제에 실패했습니다.');
    }
  }

  static Future<List<List<String>>> decryptExcel(
    Uint8List fileBytes,
    String fileName,
    String password,
  ) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: fileName,
        contentType: MediaType(
          'application',
          'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ),
      'password': password,
    });

    final resp = await dio.post(
      '/transactions/decrypt',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );

    if (resp.statusCode == 200) {
      final sheets = resp.data as List;
      final rows = <List<String>>[];
      for (final rawSheet in sheets) {
        for (final rawRow in rawSheet as List) {
          rows.add((rawRow as List).map((c) => c.toString()).toList());
        }
      }
      return rows;
    }

    throw Exception('서버 오류: ${resp.statusMessage ?? resp.statusCode}');
  }
}
