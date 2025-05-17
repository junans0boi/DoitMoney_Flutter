// lib/utils/txn_parser.dart
import '../services/transaction_service.dart';

/* ───── 1) 모델 클래스 ───── */
class ParsedTxn {
  final TransactionType type;
  final DateTime date;
  final int amount; // – 지출, + 수입
  final String description; // 거래처
  final String accountName; // 계좌/카드명

  const ParsedTxn({
    required this.type,
    required this.date,
    required this.amount,
    required this.description,
    required this.accountName,
  });

  Transaction toModel() => Transaction(
    id: 0,
    transactionDate: date,
    transactionType: type,
    category: '자동',
    amount: amount,
    description: description,
    accountName: accountName,
  );
}

/* ───── 2) 날짜 헬퍼 ───── */
DateTime _thisYear(String mmdd) {
  final now = DateTime.now();
  final p = mmdd.split('/');
  return DateTime(now.year, int.parse(p[0]), int.parse(p[1]));
}

/// 05/17 16:03:12 → 올해-5-17 16:03:12
DateTime _parseYMDHMS(String ymdHms) {
  final m = RegExp(
    r'(\d{2})/(\d{2}) (\d{2}):(\d{2}):(\d{2})',
  ).firstMatch(ymdHms);
  if (m == null) return DateTime.now();
  final y = DateTime.now().year;
  return DateTime(
    y,
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
    int.parse(m.group(4)!),
    int.parse(m.group(5)!),
  );
}

/* ───── 3) 정규식 룰 ───── */
final _rules = <RegExp, ParsedTxn Function(RegExpMatch)>{
  // ── 카카오뱅크 ─────────────────────────────────────
  RegExp(
        r'^\[(.+)\] (?<when>\d{2}/\d{2} \d{2}:\d{2})\n'
        r'(?<desc>.+?)\n(?<sign>[+-])(?<amt>[0-9,]+)원',
      ):
      (m) => ParsedTxn(
        type:
            m.namedGroup('sign') == '-'
                ? TransactionType.expense
                : TransactionType.income,
        date: _thisYear(m.namedGroup('when')!.substring(0, 5)),
        amount:
            int.parse(m.namedGroup('amt')!.replaceAll(',', '')) *
            (m.namedGroup('sign') == '-' ? -1 : 1),
        description: m.namedGroup('desc')!.trim(),
        accountName: '카카오뱅크',
      ),

  // ── KB국민카드 ────────────────────────────────────
  RegExp(r'^\[KB국민\] (?<when>\d{2}/\d{2}) (?<desc>.+?) (?<amt>[0-9,]+)원 사용'):
      (m) => ParsedTxn(
        type: TransactionType.expense,
        date: _thisYear(m.namedGroup('when')!),
        amount: -int.parse(m.namedGroup('amt')!.replaceAll(',', '')),
        description: m.namedGroup('desc')!.trim(),
        accountName: 'KB국민카드',
      ),

  // 1) “출금 … 체크카드출금” ------------------------------------------
  RegExp(r'출금\s+(?<amt>[0-9,]+)원[\s\S]*?\n(?<desc>.+?)\s+체크카드출금'):
      (m) => ParsedTxn(
        type: TransactionType.expense,
        date: DateTime.now(),
        amount: -int.parse(m.namedGroup('amt')!.replaceAll(',', '')),
        description: m.namedGroup('desc')!.trim(),
        accountName: '체크카드',
      ),

  // 2) 우리WON뱅킹  [입금] --------------------------------------------
  RegExp(r'\[입금\]\s*(?<desc>.+)\n(?<amt>[0-9,]+)원', multiLine: true):
      (m) => ParsedTxn(
        type: TransactionType.income,
        date: DateTime.now(), // 필요하면 마지막 줄 시각을 _parseYMDHMS()로 파싱
        amount: int.parse(m.namedGroup('amt')!.replaceAll(',', '')),
        description: m.namedGroup('desc')!.trim(),
        accountName: '우리은행',
      ),

  // 3) 우리WON뱅킹  [출금] --------------------------------------------
  RegExp(r'\[출금\]\s*(?<desc>.+)\n(?<amt>[0-9,]+)원', multiLine: true):
      (m) => ParsedTxn(
        type: TransactionType.expense,
        date: DateTime.now(),
        amount: -int.parse(m.namedGroup('amt')!.replaceAll(',', '')),
        description: m.namedGroup('desc')!.trim(),
        accountName: '우리은행',
      ),
};

/* ───── 4) 엔트리 함수 ───── */
ParsedTxn? parseMessage(String body) {
  for (final e in _rules.entries) {
    final m = e.key.firstMatch(body);
    if (m != null) return e.value(m);
  }
  return null;
}
