// lib/core/utils/sms_message_parser.dart

import 'package:doitmoney_flutter/features/transaction/services/transaction_service.dart';

/// A parsed SMS credit notification.
class ParsedSms {
  final DateTime dateTime;
  final int amount;
  final String fromName;
  final String accountNumber;

  ParsedSms({
    required this.dateTime,
    required this.amount,
    required this.fromName,
    required this.accountNumber,
  });

  Transaction toModel({required String accountName}) {
    return Transaction(
      id: 0,
      transactionDate: dateTime,
      transactionType: TransactionType.income,
      category: fromName,
      amount: amount,
      description: fromName,
      accountName: accountName,
      accountNumber: accountNumber,
    );
  }
}

/// Try to match only 카카오뱅크 credit SMSes:
///
/// <…>입금 3,500원\n김신혁 → 내 입출금통장(2856)
ParsedSms? parseSmsMessage(String smsBody) {
  final now = DateTime.now();
  final exp = RegExp(
    r'입금\s*([\d,]+)원\s*(?:\r?\n|\s+)\s*(.+?)\s*→\s*내\s*입출금통장\((\d+)\)',
  );

  final m = exp.firstMatch(smsBody);
  if (m == null) return null;

  final amt = int.parse(m.group(1)!.replaceAll(',', ''));
  final from = m.group(2)!.trim();
  final acctEnd = m.group(3)!;

  return ParsedSms(
    dateTime: now,
    amount: amt,
    fromName: from,
    accountNumber: acctEnd,
  );
}
