// lib/providers/router_provider.dart
import 'package:doitmoney_flutter/features/auth/screens/profile_edit_page.dart';
import 'package:doitmoney_flutter/features/fixed_expense/screens/fixed_expense_list_page.dart';
import 'package:doitmoney_flutter/features/more/screens/customer_service_page.dart';
import 'package:doitmoney_flutter/features/more/screens/notification_alert_page.dart';
import 'package:doitmoney_flutter/features/more/screens/privacy_policy_page.dart';
import 'package:doitmoney_flutter/features/more/screens/terms_of_service_page.dart';
import 'package:doitmoney_flutter/features/savings/screens/add_savings_goal_page.dart';
import 'package:doitmoney_flutter/features/savings/screens/savings_page.dart';
import 'package:doitmoney_flutter/features/transaction/screens/pdf_parsing_page.dart';
import 'package:doitmoney_flutter/features/transaction/screens/upload_complete_page.dart';
import 'package:doitmoney_flutter/features/transaction/screens/xlsx_parsing_page.dart';
import 'package:doitmoney_flutter/features/account/services/account_service.dart';
import 'package:doitmoney_flutter/features/transaction/services/transaction_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:doitmoney_flutter/features/advisor/screens/chat_screen.dart'; //

import 'features/auth/providers/auth_provider.dart';
import 'core/utils/router_refresh_notifier.dart';
import 'shared/widgets/app_shell.dart';

// ── 인증 관련 화면들 ──
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/find_id_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'features/auth/screens/change_password_page.dart';

// ── 탭 화면 ──
import 'features/home/screens/home_screen.dart';
import 'features/transaction/screens/transaction_page.dart';
import 'features/account/screens/account_page.dart';

// ── 기타 독립 화면 ──
import 'features/account/screens/add_account_page.dart';
import 'features/transaction/screens/add_transaction_page.dart';
import 'features/more/screens/more_screen.dart';
import 'features/more/screens/sms_alert_page.dart';
import 'features/transaction/screens/transaction_detail_page.dart';
import 'features/transaction/screens/upload_transactions_page.dart';
import 'main.dart' show navigatorKey; // 전역에 선언된 키 import

final routerProvider = Provider<GoRouter>((ref) {
  final loggedIn = ref.watch(authProvider);
  final authStream = ref.watch(authProvider.notifier).stream;

  return GoRouter(
    debugLogDiagnostics: true,
    navigatorKey: navigatorKey, // ← 여기에 추가
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
      GoRoute(path: '/advisor', builder: (_, __) => const ChatScreen()),
      // ── 메인 Shell ──
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (_, __) => const NoTransitionPage(child: HomeScreen()),
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
      GoRoute(path: '/more', builder: (c, s) => const MorePage()),
      GoRoute(
        path: '/notification_alert',
        builder: (context, state) => const NotificationAlertPage(),
      ),
      GoRoute(
        path: '/sms_alert',
        builder: (context, state) => const SmsAlertPage(),
      ),
      GoRoute(
        path: '/profile-edit',
        builder: (c, s) => const ProfileEditPage(),
      ),
      GoRoute(
        path: '/customer-service',
        builder: (c, s) => const CustomerServicePage(),
      ),
      GoRoute(
        path: '/terms-of-service',
        builder: (c, s) => const TermsOfServicePage(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (c, s) => const PrivacyPolicyPage(),
      ),
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
        builder: (_, __) => ImportTransactionsPage(),
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
          // extra 로 넘겨준 Map<String, dynamic> 에서
          // 'uploadedCount' 와 'duplicateCount' 를 꺼내줍니다
          final args = state.extra as Map<String, dynamic>;
          return UploadCompletePage(
            account: args['account'] as Account,
            uploadedCount: args['uploadedCount'] as int,
            duplicateCount: args['duplicateCount'] as int,
          );
        },
      ),
      GoRoute(
        path: '/savings',
        name: 'savings',
        builder: (context, state) => const SavingsPage(),
        routes: [
          // /savings/new 로 NewGoalPage로 이동
          GoRoute(
            path: 'new',
            name: 'new_savings_goal',
            builder: (context, state) => const AddSavingsGoalPage(),
          ),
        ],
      ),
    ],
  );
});
