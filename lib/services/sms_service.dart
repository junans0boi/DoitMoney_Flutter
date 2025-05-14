import 'package:telephony/telephony.dart';
import 'transaction_service.dart'; // ← 가계부 등록 서비스
import 'package:shared_preferences/shared_preferences.dart'; //알림기능 활성화 여부 저장


class SmsService {
  final Telephony telephony = Telephony.instance;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('sms_alert_enabled') ?? false;
    if (!enabled) return;
    
    final granted = await telephony.requestPhonePermissions;

    if (granted ?? false) {
      telephony.listenIncomingSms(
        onNewMessage: _onMessage,
        onBackgroundMessage: _onBackground,
        listenInBackground: true,
      );
    }
  }

  void _onMessage(SmsMessage message) {
    // _parseAndSave(message.body ?? '');
    _parseAndSave(message);
    
  }

  static void _onBackground(SmsMessage message) {
    // _parseAndSave(message.body ?? '');
    _parseAndSave(message);
  }

  static void _parseAndSave(SmsMessage message) {
    final body = message.body ?? '';  //문자내용 파싱용
    final sender = message.address ?? ''; // 발신 번호 또는 이름 확인용

    // 필터링 기준 카드사 목록 (발신자 이름 또는 번호 일부 포함 가능)
    const knownSenders = [
      '국민카드', '신한카드', '우리카드', '하나카드', '롯데카드',
      '삼성카드', '현대카드', 'BC카드', 'NH농협카드',
      '1588', '1566', '1522', 'web발신', 'webkakao'
    ];

    final isFromKnownSender = knownSenders.any(
      (s) => sender.toLowerCase().contains(s.toLowerCase()) ||
             body.toLowerCase().contains(s.toLowerCase()),
    );
    
    if (!isFromKnownSender) return; //무관한 문자 제외


    // 예시: [Web발신] 국민카드 05/13 14:22 승인 12,300원 CU 편의점
    final match = RegExp(r'(승인|출금)\s([\d,]+)원\s(.+)').firstMatch(body);
    
    if (match != null) {
      final amountStr = match.group(2)!.replaceAll(',', '');
      final amount = int.tryParse(amountStr) ?? 0;
      final desc = match.group(3)!;

      final tx = Transaction(
        id: 0,
        transactionDate: DateTime.now(),
        amount: -amount, // 출금 기준으로 음수 처리
        description: desc,
        accountName: sender.isNotEmpty ? sender : '알 수 없음',
      );

      TransactionService.addTransaction(tx);
    }
  }
}