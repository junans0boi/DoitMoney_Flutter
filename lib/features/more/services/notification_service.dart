import 'dart:async';
import 'package:doitmoney_flutter/core/utils/notification_message_parser.dart'
    as parser;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:doitmoney_flutter/main.dart' show navigatorKey;

// change to package import so the analyzer definitely sees it
import '../../transaction/services/transaction_service.dart';

const String _kChannel = 'doitmoney.flutter.dev/notification';
const String _kMethodOnNotification = 'onNotificationPosted';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final MethodChannel _channel = const MethodChannel(_kChannel);
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 로컬 알림 초기화
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotif.initialize(
      const InitializationSettings(android: android),
    );

    // 네이티브(NotificationListenerService) 메시지 핸들러 등록
    _channel.setMethodCallHandler(_platformCallHandler);
  }

  Future<void> _platformCallHandler(MethodCall call) async {
    if (call.method != _kMethodOnNotification) return;
    final args = call.arguments as Map;
    final packageName = args['packageName'] as String? ?? '';
    final full = args['fullText'] as String? ?? '';

    if (kDebugMode) {
      print('📲 Received -> [$packageName] $full');
      print('🧩 PARSED: ${parser.parseSmsMessage(full)}');
    }

    final parsed = parser.parseSmsMessage(full);
    if (parsed == null) return;

    // 1) accountName 을 로컬 변수로 꺼냅니다
    final accountName =
        packageName == 'com.example.doitmoney_flutter'
            ? // DebugNotifyActivity 로 보낸 테스트 알림
            '카카오뱅크'
            : packageName;

    final accountNumber = parsed.accountNumber!;

    try {
      // 2) 서버(DB)에 저장
      await TransactionService.addTransaction(
        parsed.toModel(accountName: accountName, accountNumber: accountNumber),
      );

      // 3) 로컬 알림
      await _localNotif.show(
        0,
        '새 거래 등록',
        '${parsed.description} ${parsed.amount}원',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'doitmoney_channel',
            'DoitMoney 알림',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
      );

      // 4) 포그라운드일 때만 SnackBar
      final ctx = navigatorKey.currentContext;
      // ignore: use_build_context_synchronously
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('새 거래: $accountName ${parsed.amount}원')),
        );
      }

      if (kDebugMode) print('✅ 거래 등록 성공');
    } catch (e) {
      if (kDebugMode) print('⚠️ 등록 실패: $e');
    }
  }
}
