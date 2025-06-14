import 'package:doitmoney_flutter/core/api/dio_client.dart';
import 'package:doitmoney_flutter/features/more/services/notification_service.dart';
import 'package:doitmoney_flutter/features/notification/services/push_service.dart';
import 'package:doitmoney_flutter/features/more/services/sms_parser_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'constants/colors.dart';
import 'constants/typography.dart';
import 'router.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('ko');
  await NotificationService().init();

  // ─── SMS, Push 서비스 초기화 ───
  await SmsService().init();
  await PushService().init();

  // ① Dio 초기화
  await initDio();

  // 백그라운드 FCM 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_fcmBackground);

  runApp(
    // navigatorKey 를 받으니 const 제거
    ProviderScope(child: DoitMoneyApp(navigatorKey: navigatorKey)),
  );
}

@pragma('vm:entry-point')
Future<void> _fcmBackground(RemoteMessage msg) async {
  await Firebase.initializeApp(); // isolate 재초기화
  await handlePush(msg); // PushService 전역 함수 호출
}

class DoitMoneyApp extends ConsumerWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  const DoitMoneyApp({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: 'DoitMoney',
      theme: ThemeData(
        fontFamily: 'GmarketSans',
        textTheme: textTheme,
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: kBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: kBackground,
          foregroundColor: kPrimaryColor,
          elevation: 0,
        ),
      ),
    );
  }
}
