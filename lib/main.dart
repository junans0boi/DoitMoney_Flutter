// lib/main.dart

import 'package:doitmoney_flutter/core/api/dio_client.dart';
import 'package:doitmoney_flutter/features/notification/services/push_service.dart';
import 'package:doitmoney_flutter/features/more/providers/more_providers.dart';
import 'package:doitmoney_flutter/features/more/services/sms_parser_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'constants/colors.dart';
import 'constants/typography.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('ko');

  // ─── 서비스 객체 생성 & 초기화 ───
  final sms = SmsService();
  final push = PushService();
  await sms.init();
  await push.init();

  // ① Dio 초기화
  await initDio();

  // SMS 리스너 초기화 (한 번만 호출해도 됩니다)
  await SmsService().init();

  // 백그라운드 FCM 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_fcmBackground);

  runApp(const ProviderScope(child: DoitMoneyApp()));
}

@pragma('vm:entry-point')
Future<void> _fcmBackground(RemoteMessage msg) async {
  await Firebase.initializeApp(); // isolate 재초기화
  await handlePush(msg); // PushService의 공개 함수 호출
}

class DoitMoneyApp extends ConsumerWidget {
  const DoitMoneyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // GoRouter 설정 (routerProvider는 기존에 정의된 router를 가리킵니다)
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
        brightness: Brightness.light,
        // 추가적인 라이트 테마 설정이 필요하다면 여기에 작성
      ),
    );
  }
}
