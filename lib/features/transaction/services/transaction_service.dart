// lib/features/transaction/services/transaction_service.dart

// ignore_for_file: unintended_html_in_doc_comment

import 'dart:typed_data';
import 'package:dio/dio.dart';
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
  }) {
    return Transaction(
      id: id ?? this.id,
      transactionDate: transactionDate ?? this.transactionDate,
      transactionType: transactionType ?? this.transactionType,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      accountName: accountName ?? this.accountName,
      accountNumber: accountNumber ?? this.accountNumber,
    );
  }

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

  /// 암호화된 XLSX를 서버로 보내서 복호화·파싱 후 List<List<String>>으로 반환
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
        final sheet = rawSheet as List;
        for (final rawRow in sheet) {
          final row = (rawRow as List).map((c) => c.toString()).toList();
          rows.add(row);
        }
      }
      return rows;
    } else {
      throw Exception('서버 오류: ${resp.statusMessage ?? resp.statusCode}');
    }
  }
}
