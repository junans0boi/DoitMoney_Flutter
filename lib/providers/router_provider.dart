// lib/providers/router_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_provider.dart';
import '../utils/go_router_refresh_stream.dart'; // ✅ util import

// 탭 화면 -----------------------------------------------------------
import '../screens/home/home_tab.dart';
import '../screens/transaction/transaction_page.dart';
import '../screens/account/account_page.dart';

// 인증 -------------------------------------------------------------
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/find_id_screen.dart';
import '../screens/auth/find_pw_screen.dart';
import '../screens/auth/reset_pw_screen.dart';

// 독립 화면 --------------------------------------------------------
import '../screens/account/add_account_page.dart';
import '../widgets/ledger/add_transaction_page.dart';

// Shell -----------------------------------------------------------
import '../widgets/main_shell.dart';
import '../screens/more/more_page.dart';
import '../screens/more/sms_alert_page.dart';

/// ──────────────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final loggedIn = ref.watch(authProvider); // bool
  final authStream = ref.watch(authProvider.notifier).stream; // Stream<bool>

  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authStream),

    // ---------- 로그인 / 비로그인 전환 ----------
    redirect: (_, state) {
      final loc = state.uri.path; // ✅ 변경
      final loggingIn =
          loc.startsWith('/login') ||
          loc.startsWith('/signup') ||
          loc.startsWith('/find');

      if (!loggedIn && !loggingIn) return '/login';
      if (loggedIn && loggingIn) return '/';
      return null;
    },

    // ---------- 라우트 정의 ----------
    routes: [
      // ── 인증 플로우 ──
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupPage()),
      GoRoute(path: '/find-id', builder: (_, __) => const FindIdPage()),
      GoRoute(path: '/find-pw', builder: (_, __) => const FindPwPage()),
      GoRoute(path: '/reset-pw', builder: (_, __) => const ResetPwPage()),

      // ── 하단 탭( Shell ) ──
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (_, __) => const NoTransitionPage(child: HomeTab()),
          ),
          GoRoute(
            path: '/ledger',
            pageBuilder: (_, __) => const NoTransitionPage(child: LedgerPage()),
          ),
          GoRoute(
            path: '/account',
            pageBuilder:
                (_, __) => const NoTransitionPage(child: AccountPage()),
          ),
        ],
      ),

      /* ───────── “더보기” ───────── */
      GoRoute(path: '/more', builder: (_, __) => const MorePage()),
      GoRoute(path: '/sms-alert', builder: (_, __) => const SmsAlertPage()),

      // ── 독립 화면 ──
      GoRoute(path: '/add-account', builder: (_, __) => const AddAccountPage()),
      GoRoute(
        path: '/transaction/add',
        builder: (_, __) => const AddTransactionPage(),
      ),
    ],
  );
});
