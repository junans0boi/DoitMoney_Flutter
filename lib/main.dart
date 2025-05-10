import 'package:flutter/material.dart';
import 'constants/typography.dart';
import 'constants/colors.dart';

// 스플래시, 인증 화면
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/find_id_screen.dart';
import 'screens/auth/find_pw_screen.dart';
import 'screens/auth/reset_pw_screen.dart';

// 메인 탭 화면
import 'screens/home/home_page.dart'; // ← HomePage 를 import
// import 'screens/analysis/analysis_page.dart'; // 나중에 만들 분석 화면
// import 'screens/ledger/ledger_page.dart';     // 가계부 화면
// import 'screens/chart/chart_page.dart';       // 차트 화면
// import 'screens/more/more_page.dart';         // 더보기 화면

void main() => runApp(const PlanaryApp());

class PlanaryApp extends StatelessWidget {
  const PlanaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/find-id': (context) => const FindIdPage(),
        '/find-password': (context) => const FindPwPage(),
        '/reset-password': (context) => const ResetPwPage(),
        '/home': (context) => const HomeScreen(),
        // '/analysis':       (context) => const AnalysisPage(),  // 나중에 구현
        // '/ledger':         (context) => const LedgerPage(),
        // '/chart':          (context) => const ChartPage(),
        // '/more':           (context) => const MorePage(),
      },
    );
  }
}
