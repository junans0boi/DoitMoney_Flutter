import 'dart:async';
// navigation_service 에 있는 navigatorKey 는 사용하지 않도록 alias
import 'package:doitmoney_flutter/core/navigation/navigation_service.dart'
    as nav_service;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:doitmoney_flutter/main.dart' show navigatorKey;

import '../../../core/utils/notification_message_parser.dart';
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
    final title = args['title'] as String? ?? '';
    final text = args['text'] as String? ?? '';
    // ← interpolation 문법 수정: 변수값을 제대로 넣어야 text 가 사용됩니다
    final full = '$title\n$text';

    if (kDebugMode) print('📲 Received -> [$packageName] $full');

    final parsed = parseNotificationMessage(full, packageName);
    if (parsed != null) {
      try {
        // 타이틀을 accountName, parser 에서 뽑은 뒤 4자리 계좌번호
        final accountName = title;
        final accountNumber = parsed.accountNumber ?? '9999';
        await TransactionService.addTransaction(
          parsed.toModel(
            accountName: accountName,
            accountNumber: accountNumber,
          ),
        );

        // 1) 백그라운드·포그라운드 상관 없이 로컬 푸시
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

        // 2) 포그라운드일 땐 스낵바도 띄우기
        final ctx = navigatorKey.currentContext;
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
}
