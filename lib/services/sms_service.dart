import 'package:permission_handler/permission_handler.dart';
import 'package:another_telephony/telephony.dart';

import '../utils/txn_parser.dart';
import 'transaction_service.dart';

class SmsService {
  final _telephony = Telephony.instance;

  Future<void> init() async {
    // ① 권한
    final sms = await Permission.sms.request();
    final notif = await Permission.notification.request();
    if (!sms.isGranted) return;

    // ② background isolate 등록
    await _telephony.requestPhonePermissions; // Android 12 대응
    _telephony.listenIncomingSms(
      onNewMessage: _onMessage,
      onBackgroundMessage: _backgroundHandler,
      listenInBackground: true,
    );
  }

  /* ───────── 포그라운드 ───────── */
  void _onMessage(SmsMessage msg) => _handle(msg.body);

  /* ───────── 백그라운드 ───────── */
  static void _backgroundHandler(SmsMessage msg) => _handle(msg.body);

  /* ───────── 공용 처리 ───────── */
  static Future<void> _handle(String? body) async {
    if (body == null) return;
    final parsed = parseMessage(body);
    if (parsed == null) return; // 규칙 미적용
    try {
      await TransactionService.addTransaction(parsed.toModel());
    } catch (_) {
      /* 로그만 */
    }
  }
}
