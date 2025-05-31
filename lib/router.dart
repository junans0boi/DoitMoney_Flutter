// lib/providers/router_provider.dart
import 'package:doitmoney_flutter/screens/fixed_expense/fixed_expense_list_page.dart';
import 'package:doitmoney_flutter/screens/transaction/pdf_parsing_page.dart';
import 'package:doitmoney_flutter/screens/transaction/upload_complete_page.dart';
import 'package:doitmoney_flutter/screens/transaction/xlsx_parsing_page.dart';
import 'package:doitmoney_flutter/services/account_service.dart';
import 'package:doitmoney_flutter/services/transaction_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

import 'auth_provider.dart';
import '../utils/go_router_refresh_stream.dart';
import '../widgets/main_shell.dart';

// ── 인증 관련 화면들 ──
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/find_id_screen.dart';
import '../screens/auth/find_pw_screen.dart';
import '../screens/auth/combined_reset_pw_page.dart';
import '../screens/auth/change_password_page.dart';

// ── 탭 화면 ──
import '../screens/home/home_tab.dart';
import '../screens/transaction/transaction_page.dart';
import '../screens/account/account_page.dart';

// ── 기타 독립 화면 ──
import '../screens/account/add_account_page.dart';
import '../screens/transaction/add_transaction_page.dart';
import '../screens/more/more_page.dart';
import '../screens/more/sms_alert_page.dart';
import '../screens/transaction/transaction_detail_page.dart';
import '../screens/transaction/upload_transactions_page.dart.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final loggedIn = ref.watch(authProvider);
  final authStream = ref.watch(authProvider.notifier).stream;

  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authStream),
    redirect: (_, state) {
      final loc = state.uri.path;
      final loggingIn =
          loc.startsWith('/login') ||
          loc.startsWith('/signup') ||
          loc.startsWith('/find-id') ||
          loc.startsWith('/find-pw');
      if (!loggedIn && !loggingIn && !loc.startsWith('/find-pw')) {
        return '/login';
      }
      if (loggedIn && loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupPage()),
      GoRoute(path: '/find-id', builder: (_, __) => const FindIdPage()),

      // “이메일 입력 → 인증번호 → 새 비밀번호”를 한 페이지에서 처리
      GoRoute(
        path: '/find-pw',
        builder: (_, __) => const CombinedResetPwPage(),
      ),

      GoRoute(
        path: '/change-password',
        builder: (_, __) => const ChangePasswordPage(),
      ),

      // ── 메인 Shell ──
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (_, __) => const NoTransitionPage(child: HomeTab()),
          ),
          GoRoute(
            path: '/ledger',
            pageBuilder:
                (_, __) => const NoTransitionPage(child: TransactionPage()),
          ),
          GoRoute(
            path: '/account',
            pageBuilder:
                (_, __) => const NoTransitionPage(child: AccountPage()),
          ),
        ],
      ),

      // ── 기타 독립 화면 ──
      GoRoute(path: '/more', builder: (_, __) => const MorePage()),
      GoRoute(path: '/sms-alert', builder: (_, __) => const SmsAlertPage()),
      GoRoute(path: '/add-account', builder: (_, __) => const AddAccountPage()),
      GoRoute(
        path: '/transaction/add',
        builder: (_, __) => const AddTransactionPage(),
      ),
      GoRoute(
        path: '/transaction/edit',
        builder: (ctx, state) {
          final tx = state.extra as Transaction;
          return AddTransactionPage(existing: tx);
        },
      ),
      GoRoute(
        path: '/transaction/detail',
        builder: (ctx, state) {
          final tx = state.extra as Transaction;
          return TransactionDetailPage(transaction: tx);
        },
      ),
      GoRoute(
        path: '/fixed-expense',
        builder: (_, __) => const FixedExpenseListPage(),
      ),
      GoRoute(
        path: '/transaction/ocr',
        builder: (_, __) => const ImportTransactionsPage(),
      ),
      GoRoute(
        path: '/xlsx-preview',
        builder: (ctx, state) {
          final file = state.extra! as PlatformFile;
          return XlsxParsingPage(file: file);
        },
      ),
      GoRoute(
        path: '/pdf-preview',
        builder: (ctx, state) {
          final pdfPath = state.extra! as String;
          return PdfParsingPage(path: pdfPath);
        },
      ),
      GoRoute(
        path: '/upload-complete',
        builder: (ctx, state) {
          final args = state.extra as Map<String, dynamic>;
          return UploadCompletePage(
            account: args['account'] as Account,
            count: args['count'] as int,
          );
        },
      ),
    ],
  );
});
