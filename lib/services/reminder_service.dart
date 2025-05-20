// lib/services/reminder_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'fixed_expense_service.dart'; // 상대경로

final _localNotif = FlutterLocalNotificationsPlugin();

Future<void> initReminderService() async {
  // 로컬 알림 세팅
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  await _localNotif.initialize(
    const InitializationSettings(android: androidSettings),
  );

  // 매일 오전 9시 알람 예약 (앱 최초 실행 시점부터)
  await AndroidAlarmManager.periodic(
    const Duration(days: 1),
    0,
    _checkAndNotify,
    startAt: DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      9,
    ),
    exact: true,
    wakeup: true,
  );
}

Future<void> _checkAndNotify() async {
  final today = DateTime.now();
  final tomorrow = today.add(const Duration(days: 1)).day;
  final list = await FixedExpenseService.fetchFixedExpenses();
  final due = list.where((e) => e.dayOfMonth == tomorrow);

  for (final fe in due) {
    await _localNotif.show(
      fe.id,
      '고정지출 납부 알림',
      '내일 ${fe.category} ${fe.amount}원 납부 예정입니다.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fixed_expense',
          '고정지출 알림',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
