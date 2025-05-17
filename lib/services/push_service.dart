import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../api/dio_client.dart';
import '../utils/txn_parser.dart';
import 'transaction_service.dart';

/// 👉 전역 함수(공개)로 변경 — 다른 파일에서 쓸 수 있도록
Future<void> handlePush(RemoteMessage m) async {
  final body = m.notification?.body ?? m.data['body'] ?? '';
  final parsed = parseMessage(body);
  if (parsed != null) {
    await TransactionService.addTransaction(parsed.toModel());
  }

  // 로컬 알림 표시
  const details = NotificationDetails(
    android: AndroidNotificationDetails('default', '기본 알림'),
  );
  await FlutterLocalNotificationsPlugin().show(
    0,
    m.notification?.title ?? '새 알림',
    body,
    details,
  );
}

class PushService {
  final _fcm = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const ch = AndroidNotificationChannel(
      'default',
      '기본 알림',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(ch);

    const init = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _local.initialize(init);

    // 포그라운드 수신
    FirebaseMessaging.onMessage.listen(handlePush); // ✅ 공개 함수 사용
  }
}
