// lib/shared/utils/regex_parser_utils.dart

import '../../features/transaction/services/transaction_service.dart';
import '../core/utils/date_utils.dart';

typedef ParsedTxnFactory = ParsedTxn Function(RegExpMatch);

/// 여러 은행/카드 문자 메시지를 파싱하는 규칙 모음
final Map<RegExp, ParsedTxnFactory> defaultTxnParsingRules = {
  // 카카오뱅크 예시
  RegExp(
    r'^\[(.+)\] (?<when>\d{2}/\d{2} \d{2}:\d{2})\n'
    r'(?<desc>.+?)\n(?<sign>[+-])(?<amt>[0-9,]+)원',
  ): (m) {
    final sign = m.namedGroup('sign')!;
    final intAmt =
        int.parse(m.namedGroup('amt')!.replaceAll(',', '')) *
        (sign == '-' ? -1 : 1);
    final date = parseMMddToThisYear(
      m.namedGroup('when')!.substring(0, 5),
    ); // MM/dd
    return ParsedTxn(
      type: sign == '-' ? TransactionType.expense : TransactionType.income,
      date: date,
      amount: intAmt,
      description: m.namedGroup('desc')!.trim(),
      accountName: '카카오뱅크',
      accountNumber: '',
    );
  },
  // KB국민카드 예시
  RegExp(r'^\[KB국민\] (?<when>\d{2}/\d{2}) (?<desc>.+?) (?<amt>[0-9,]+)원 사용'): (
    m,
  ) {
    final date = parseMMddToThisYear(m.namedGroup('when')!);
    final amt = -int.parse(m.namedGroup('amt')!.replaceAll(',', ''));
    return ParsedTxn(
      type: TransactionType.expense,
      date: date,
      amount: amt,
      description: m.namedGroup('desc')!.trim(),
      accountName: 'KB국민카드',
      accountNumber: '',
    );
  },
  // 우리카드 체크승인 예시
  RegExp(
    r'^안내\n' // "안내" 고정
    r'우리카드 이용안내 우리카드\(\d+\)체크승인\n' // "우리카드(숫자)체크승인"
    r'.+\n' // (고객명)
    r'(?<amt>[0-9,]+)원\n' // 금액
    r'(?<when>\d{2}/\d{2}\d{2}:\d{2})\n' // MM/DDHH:MM
    r'(?<desc>.+)$', // 가맹점명
    multiLine: true,
  ): (m) {
    final date = parseMMddHHmmss(m.namedGroup('when')!);
    final amt = -int.parse(m.namedGroup('amt')!.replaceAll(',', ''));
    return ParsedTxn(
      type: TransactionType.expense,
      date: date,
      amount: amt,
      description: m.namedGroup('desc')!.trim(),
      accountName: '우리카드',
      accountNumber: '',
    );
  },
  // 나머지 은행/카드 규칙들...
};

/// 문자/푸시 메시지(body)에서 ParsedTxn을 얻어주는 공통 엔트리 함수
ParsedTxn? parseTxnFromMessage(String body) {
  for (final entry in defaultTxnParsingRules.entries) {
    final match = entry.key.firstMatch(body);
    if (match != null) {
      return entry.value(match);
    }
  }
  return null;
}

/// ParsedTxn 모델 (기존과 동일)
class ParsedTxn {
  final TransactionType type;
  final DateTime date;
  final int amount;
  final String description;
  final String accountName;
  final String accountNumber;

  const ParsedTxn({
    required this.type,
    required this.date,
    required this.amount,
    required this.description,
    required this.accountName,
    required this.accountNumber,
  });

  Transaction toModel() => Transaction(
    id: 0,
    transactionDate: date,
    transactionType: type,
    category: '자동',
    amount: amount,
    description: description,
    accountName: accountName,
    accountNumber: accountNumber,
  );
}
