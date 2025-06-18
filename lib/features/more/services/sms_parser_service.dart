// lib/features/more/services/sms_parser_service.dart

import 'package:another_telephony/telephony.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/utils/sms_message_parser.dart';
import '../../transaction/services/transaction_service.dart';

class SmsService {
  final _telephony = Telephony.instance;

  /// Call this once at app start (e.g. in main.dart)
  Future<void> init() async {
    // 1) Runtime SMS permission
    var status = await Permission.sms.status;
    if (!status.isGranted) {
      status = await Permission.sms.request();
      if (!status.isGranted) return;
    }

    // 2) Start listening (foreground & background)
    _telephony.listenIncomingSms(
      onNewMessage: _onMessage,
      onBackgroundMessage:
          smsBackgroundHandler, // must be a top-level or static fn
      listenInBackground: true,
    );
  }

  void _onMessage(SmsMessage msg) {
    final body = msg.body ?? '';
    _handle(body);
  }

  @pragma('vm:entry-point') // ensure this survives tree-shaking
  static void smsBackgroundHandler(SmsMessage msg) {
    final body = msg.body ?? '';
    SmsService()._handle(body);
  }

  Future<void> _handle(String body) async {
    final parsed = parseSmsMessage(body);
    if (parsed == null) return;

    try {
      // post to your backend
      await TransactionService.addTransaction(
        parsed.toModel(accountName: '카카오뱅크'),
      );
      if (kDebugMode)
        print('✅ SMS등록 성공: ${parsed.amount}원 from ${parsed.fromName}');
    } catch (e, st) {
      if (kDebugMode) print('⚠️ SMS등록 실패: $e\n$st');
    }
  }
}
