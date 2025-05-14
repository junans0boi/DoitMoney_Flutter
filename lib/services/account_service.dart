// lib/services/account_service.dart

import '../api/api.dart';

enum AccountType { BANK, CARD, CASH, ETC }

class Account {
  final int id;
  final AccountType accountType;
  final String institutionName;
  final String accountNumber;
  final double balance;
  final String logoPath;

  const Account({
    required this.id,
    required this.accountType,
    required this.institutionName,
    required this.accountNumber,
    required this.balance,
    required this.logoPath,
  });

  factory Account.fromJson(Map<String, dynamic> j) {
    final name = j['institutionName'] as String;
    return Account(
      id: j['id'] as int,
      accountType: AccountType.values.firstWhere(
        (e) => e.name == j['accountType'],
      ),
      institutionName: name,
      accountNumber: j['accountNumber'] as String? ?? '',
      balance: (j['balance'] as num).toDouble(),
      logoPath: AccountService.logos[name] ?? 'assets/images/default_bank.png',
    );
  }

  Map<String, dynamic> toJson() => {
    'accountType': accountType.name,
    'institutionName': institutionName,
    'accountNumber': accountNumber,
    'balance': balance.round(),
  };
}

class AccountService {
  static Future<List<Account>> fetchAccounts() async {
    final res = await dio.get('/accounts');
    if (res.statusCode != 200) throw '네트워크 오류';
    return (res.data as List)
        .map((e) => Account.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Account> addAccount(Account a) async {
    final res = await dio.post('/accounts', data: a.toJson());
    return Account.fromJson(res.data as Map<String, dynamic>);
  }

  static Future<Account> updateAccount(int id, Account a) async {
    final res = await dio.put('/accounts/$id', data: a.toJson());
    return Account.fromJson(res.data as Map<String, dynamic>);
  }

  static Future<void> deleteAccount(int id) async {
    await dio.delete('/accounts/$id');
  }

  /* 은행 로고 */
  static const Map<String, String> bankLogos = {
    'KB국민은행': 'assets/banks/kb.png',
    '우리은행': 'assets/banks/won.png',
    '신한은행': 'assets/banks/sol.png',
    '하나은행': 'assets/banks/keb.png',
    'NH농협은행': 'assets/banks/nh.png',
    'IBK기업은행': 'assets/banks/ibk.png',
    '케이뱅크': 'assets/banks/kbank.png',
    '카카오뱅크': 'assets/banks/kakao.png',
    '토스뱅크': 'assets/banks/toss.png',
    'MG새마을금고': 'assets/banks/mg.png',
    '우체국은행': 'assets/banks/epost.png',
    'KDB산업은행': 'assets/banks/kdb.png',
    'SH수협은행': 'assets/banks/sh.png',
    '한국씨티은행': 'assets/banks/ct.png',
    'SC제일은행': 'assets/banks/sc.png',
    'BNK부산은행': 'assets/banks/bnk.png',
    'BNK경남은행': 'assets/banks/bnk.png',
    'DGK대구은행': 'assets/banks/dgk.png',
    '신협은행': 'assets/banks/cu.png',
    '제주은행': 'assets/banks/sol.png',
    '전북은행': 'assets/banks/jb.png',
    '광주은행': 'assets/banks/jb.png',
  };

  /* 카드 로고 (중복 키가 존재하므로 뒤에서 덮어쓴다) */
  static const Map<String, String> cardLogos = {
    'KB국민카드': 'assets/banks/kb.png',
    '삼성카드': 'assets/banks/samsung.png',
    '신한카드': 'assets/banks/sol.png',
    '우리카드': 'assets/banks/won.png',
    'IBK기업은행': 'assets/banks/ibk.png',
    '하나카드': 'assets/banks/keb.png',
    '롯데카드': 'assets/banks/lotte.png',
    '현대카드': 'assets/banks/hyundai.png',
    '우체국': 'assets/banks/epost.png',
    'NH농협카드': 'assets/banks/nh.png',
    '카카오뱅크': 'assets/banks/kakao.png',
    '토스뱅크': 'assets/banks/toss.png',
  };

  /* 은행 + 카드 통합 (중복은 카드 우선) – const → final 로 수정하여 컴파일 오류 제거 */
  static final Map<String, String> logos = {...bankLogos, ...cardLogos};
}
