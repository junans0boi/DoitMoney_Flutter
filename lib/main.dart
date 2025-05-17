import 'package:doitmoney_flutter/services/push_service.dart';
import 'package:doitmoney_flutter/services/sms_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'constants/colors.dart';
import 'constants/typography.dart';
import 'providers/router_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('ko');

  // ─── 서비스 객체 생성 & 초기화 ───
  final sms = SmsService();
  final push = PushService();
  await sms.init();
  await push.init();

  // 백그라운드 FCM 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_fcmBackground);

  runApp(const ProviderScope(child: PlanaryApp()));
}

@pragma('vm:entry-point')
Future<void> _fcmBackground(RemoteMessage msg) async {
  await Firebase.initializeApp(); // isolate 재초기화
  await handlePush(msg); // ✅ 공개 함수 호출
}

class PlanaryApp extends ConsumerWidget {
  const PlanaryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: 'Planary',
      theme: ThemeData(
        fontFamily: 'GmarketSans',
        textTheme: textTheme,
        primaryColor: kPrimary,
        scaffoldBackgroundColor: kBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: kBackground,
          foregroundColor: kPrimary,
          elevation: 0,
        ),
      ),
    );
  }
}
