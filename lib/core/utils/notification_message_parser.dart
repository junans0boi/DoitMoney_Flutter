// lib/core/utils/notification_message_parser.dart

import 'package:doitmoney_flutter/features/transaction/services/transaction_service.dart';

/// 파싱 결과를 임시로 담는 모델
class ParsedNotification {
  final DateTime dateTime;
  final int amount;
  final String description;
  final bool isExpense;
  final String? accountNumber;

  ParsedNotification({
    required this.dateTime,
    required this.amount,
    required this.description,
    required this.isExpense,
    this.accountNumber,
  });

  Transaction toModel({
    required String accountName,
    required String accountNumber,
  }) {
    return Transaction(
      id: 0,
      transactionDate: dateTime,
      transactionType:
          isExpense ? TransactionType.expense : TransactionType.income,
      category: description,
      amount: isExpense ? -amount : amount,
      description: description,
      accountName: accountName,
      accountNumber: accountNumber,
    );
  }
}

/// 알림(Notification) 메시지를 파싱해서 [ParsedNotification]을 반환합니다.
/// 지원하는 양식에 새로운 카카오뱅크 입금 패턴 추가
ParsedNotification? parseNotificationMessage(
  String fullText,
  String packageName,
) {
  final now = DateTime.now();

  // 1) 카카오뱅크 입금 알림
  //    예시:
  //    카카오뱅크
  //    입금 3,500원
  //    김신혁 → 내 입출금통장(2856)
  final kakaoExp = RegExp(
    r'입금\s*([\d,]+)원\s*(?:\r?\n)\s*(.+?)\s*→\s*내 입출금통장\((\d+)\)',
  );
  final kakaoMatch = kakaoExp.firstMatch(fullText);
  if (kakaoMatch != null) {
    final amtStr = kakaoMatch.group(1)!.replaceAll(',', '');
    final fromName = kakaoMatch.group(2)!.trim();
    final acctEnd = kakaoMatch.group(3)!; // e.g. '2856'
    final amt = int.tryParse(amtStr) ?? 0;
    return ParsedNotification(
      dateTime: now,
      amount: amt,
      description: fromName,
      isExpense: false,
      accountNumber: acctEnd,
    );
  }

  // 2) 기존 패턴: 우리카드 승인내역
  final wcCardExp = RegExp(
    r'\[일시불체크\.승인\(\d+\)\]\s*(\d{2})/(\d{2})\s+(\d{1,2}):(\d{2})\s+([\d,]+)원\s+(.+)',
  );
  final wcMatch = wcCardExp.firstMatch(fullText);
  if (wcMatch != null) {
    final month = int.parse(wcMatch.group(1)!);
    final day = int.parse(wcMatch.group(2)!);
    final hour = int.parse(wcMatch.group(3)!);
    final minute = int.parse(wcMatch.group(4)!);
    final amtStr = wcMatch.group(5)!.replaceAll(',', '');
    final desc = wcMatch.group(6)!.trim().replaceAll('_', ' ');
    final dt = DateTime(now.year, month, day, hour, minute);
    final amt = int.tryParse(amtStr) ?? 0;
    return ParsedNotification(
      dateTime: dt,
      amount: amt,
      description: desc,
      isExpense: true,
    );
  }

  // 3) 기존 패턴: 우리WON뱅킹 출금
  final wbBankExp = RegExp(
    r'\[출금\]\s*(.+?)\s+([\d,]+)원.*?(\d{2})/(\d{2})\s+(\d{1,2}):(\d{2}):(\d{2})',
  );
  final wbMatch = wbBankExp.firstMatch(fullText);
  if (wbMatch != null) {
    final desc = wbMatch.group(1)!.trim();
    final amtStr = wbMatch.group(2)!.replaceAll(',', '');
    final month = int.parse(wbMatch.group(3)!);
    final day = int.parse(wbMatch.group(4)!);
    final hour = int.parse(wbMatch.group(5)!);
    final minute = int.parse(wbMatch.group(6)!);
    final second = int.parse(wbMatch.group(7)!);
    final dt = DateTime(now.year, month, day, hour, minute, second);
    final amt = int.tryParse(amtStr) ?? 0;
    return ParsedNotification(
      dateTime: dt,
      amount: amt,
      description: desc,
      isExpense: true,
    );
  }

  // 4) 일반 입금/출금
  final expWithdraw = RegExp(r'([\d,]+)원\s*(출금|사용|이체)');
  final expDeposit = RegExp(r'([\d,]+)원\s*(입금)');
  if (expWithdraw.hasMatch(fullText)) {
    final m = expWithdraw.firstMatch(fullText)!;
    final amt = int.tryParse(m.group(1)!.replaceAll(',', '')) ?? 0;
    return ParsedNotification(
      dateTime: now,
      amount: amt,
      description: '출금 알림',
      isExpense: true,
    );
  }
  if (expDeposit.hasMatch(fullText)) {
    final m = expDeposit.firstMatch(fullText)!;
    final amt = int.tryParse(m.group(1)!.replaceAll(',', '')) ?? 0;
    return ParsedNotification(
      dateTime: now,
      amount: amt,
      description: '입금 알림',
      isExpense: false,
    );
  }

  return null;
}
