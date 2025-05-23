// // lib/services/reminder_service.dart
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;
// import 'fixed_expense_service.dart';

// final _local = FlutterLocalNotificationsPlugin();

// Future<void> initReminderService() async {
//   tz.initializeTimeZones();
//   final loc = tz.getLocation('Asia/Seoul');

//   const init = InitializationSettings(
//     android: AndroidInitializationSettings('@mipmap/ic_launcher'),
//     iOS: DarwinInitializationSettings(),
//   );
//   await _local.initialize(init);

//   await _scheduleRepeatingDailyNineAM(loc);
//   await _checkAndNotify();
// }

// Future<void> _scheduleRepeatingDailyNineAM(tz.Location loc) async {
//   await _local.zonedSchedule(
//     0,
//     '정기지출 점검',
//     '오늘·내일 납부할 고정지출을 확인하세요',
//     _next9AM(loc),
//     const NotificationDetails(
//       android: AndroidNotificationDetails(
//         'fixed_expense_daily',
//         '고정지출 점검',
//         importance: Importance.high,
//         priority: Priority.high,
//         visibility: NotificationVisibility.public,
//       ),
//     ),
//     androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//     matchDateTimeComponents: DateTimeComponents.time,
//     payload: 'check_fixed_expense',
//   );
// }

// tz.TZDateTime _next9AM(tz.Location loc) {
//   final now = tz.TZDateTime.now(loc);
//   final today9 = tz.TZDateTime(loc, now.year, now.month, now.day, 9);
//   return now.isBefore(today9) ? today9 : today9.add(const Duration(days: 1));
// }

// Future<void> _checkAndNotify() async {
//   final today = DateTime.now();
//   final tomorrow = today.add(const Duration(days: 1)).day;
//   final list = await FixedExpenseService.fetchFixedExpenses();
//   final due = list.where((e) => e.dayOfMonth == tomorrow);
//   if (due.isEmpty) return;

//   final body = due.map((e) => '∙ ${e.category}  ${e.amount}원').join('\n');
//   await _local.show(
//     999,
//     '내일 납부할 고정지출 ${due.length}건',
//     body,
//     const NotificationDetails(
//       android: AndroidNotificationDetails(
//         'fixed_expense_due',
//         '고정지출 납부 알림',
//         importance: Importance.high,
//         priority: Priority.high,
//       ),
//     ),
//   );
// }
