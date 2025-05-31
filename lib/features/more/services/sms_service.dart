import 'package:permission_handler/permission_handler.dart';
import 'package:another_telephony/telephony.dart';
import '../utils/txn_parser.dart';
import 'transaction_service.dart';

@pragma('vm:entry-point')
void smsBackgroundHandler(SmsMessage msg) {
  // SmsService 의 static helper 로 위임하거나 직접 처리
  SmsService._handleBackground(msg);
}

class SmsService {
  final _telephony = Telephony.instance;

  Future<void> init() async {
    // ① 권한
    // final sms = await Permission.sms.request();
    // final notif = await Permission.notification.request();
    // if (!sms.isGranted) return;

    // // ② background isolate 등록
    // await _telephony.requestPhonePermissions; // Android 12 대응
    // _telephony.listenIncomingSms(
    //   onNewMessage: _onMessage,
    //   onBackgroundMessage: _backgroundHandler,
    //   listenInBackground: true,
    // );

    // 1) 런타임 권한 요청
    // var statusSms = await Permission.sms.status;
    // if (!statusSms.isGranted) {
    //   statusSms = await Permission.sms.request();
    //   if (!statusSms.isGranted) return;
    // }

    // // 2) FCM 백그라운드 메시지처럼 isolate 로 백그라운드 콜백 지정 (void 반환이므로 await 제거)
    // _telephony.listenIncomingSms(
    //   onNewMessage: _onMessage,
    //   onBackgroundMessage: _backgroundHandler,
    //   listenInBackground: true,
    // );

    final bool? smsGranted = await _telephony.requestPhoneAndSmsPermissions;
    if (smsGranted != true) return;

    // 톱레벨 함수로 넘김
    _telephony.listenIncomingSms(
      onNewMessage: _onMessage, // 인스턴스 메서드 OK
      onBackgroundMessage: smsBackgroundHandler,
      listenInBackground: true,
    );
  }

  /* ───────── 포그라운드 ───────── */
  // void _onMessage(SmsMessage msg) => _handle(msg.body);

  /* ───────── 백그라운드 ───────── */
  //static void _backgroundHandler(SmsMessage msg) => _handle(msg.body);

  /// 앱 포그라운드에서 SMS 수신 시 호출
  // void _onMessage(SmsMessage msg) {
  //   _handleBody(msg.body);
  // }

  void _onMessage(SmsMessage msg) {
    print('📱 Foreground SMS: ${msg.body}');
    _handleBody(msg.body);
  }

  /// 앱이 종료된 상태에서도 SMS 수신 시 호출될 최상위 함수
  // @pragma('vm:entry-point')
  // static void _backgroundHandler(SmsMessage msg) {
  //   SmsService()._handleBody(msg.body);
  // }

  /// SMS 본문을 파싱하고, 유효한 거래라면 서버에 등록
  Future<void> _handleBody(String? body) async {
    if (body == null) return;
    final parsed = parseMessage(body);
    if (parsed == null) return;

    try {
      // 서버에 거래 등록 (await 해 주시면 동시 요청이 쌓이지 않습니다)
      await TransactionService.addTransaction(parsed.toModel());
    } catch (e, st) {
      // 로그만 남기고 앱 흐름엔 영향 주지 않습니다.
      print('📱 SMS 파싱 후 가계부 등록 실패: $e\n$st');
    }
  }

  /// 백그라운드에서 호출될 때 사용하는 static helper
  static void _handleBackground(SmsMessage msg) {
    print('📱 Background SMS: ${msg.body}');
    SmsService()._handleBody(msg.body);
  }

  // /* ───────── 공용 처리 ───────── */
  // static Future<void> _handle(String? body) async {
  //   if (body == null) return;
  //   final parsed = parseMessage(body);
  //   if (parsed == null) return; // 규칙 미적용
  //   try {
  //     await TransactionService.addTransaction(parsed.toModel());
  //   } catch (_) {
  //     /* 로그만 */
  //   }
  // }
}
