// lib/shared/widgets/app_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:dio/dio.dart';

import '../../constants/colors.dart';
import '../../features/auth/providers/user_provider.dart';
import '../../features/transaction/providers/transaction_provider.dart';
import '../../core/api/dio_client.dart'; // ← 추가

/// 메인 Shell 위젯: AppBar와 BottomNavigationBar를 공통으로 관리합니다.
/// - child로 실제 탭 내부 위젯을 전달받습니다.
class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _tabs = ['/', '/ledger', '/account'];

  int _locationToIndex(String location) {
    for (var i = 0; i < _tabs.length; i++) {
      if (location == _tabs[i] || location.startsWith('${_tabs[i]}/')) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(userProvider);
    final routeInfo = GoRouter.of(context).routeInformationProvider.value;
    final idx = _locationToIndex(routeInfo.uri.path);

    // ── 프로필 이미지 URL 조립 (dio.options.baseUrl 에서 "/api" 제거) ──
    String? avatarUrl;
    if (me?.profileImageUrl != null && me!.profileImageUrl.isNotEmpty) {
      // dio.options.baseUrl 예: "http://doitmoney.kro.kr/api"
      final hostOnly = dio.options.baseUrl.replaceAll(RegExp(r'/api/?$'), '');
      avatarUrl =
          me.profileImageUrl.startsWith('http')
              ? me.profileImageUrl
              : '$hostOnly${me.profileImageUrl}';
      // avatarUrl 예시: "http://doitmoney.kro.kr/static/profiles/xxxx.png"
    }
    // ─────────────────────────────────────────────────────────────────────────

    // ── 상단 AppBar ─────────────────────────────────
    final appBar = AppBar(
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      backgroundColor: kBackground,
      foregroundColor: kPrimary,
      elevation: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child:
                  avatarUrl == null
                      ? const Icon(Icons.person, size: 18, color: Colors.grey)
                      : null,
            ),
            const SizedBox(width: 8),
            Text(
              me?.username ?? '로딩중',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () => context.push('/notifications'),
            ),
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => context.push('/more'),
            ),
          ],
        ),
      ),
    );

    // ── 하단 탭 Bar ─────────────────────────────────
    final bottomNav = BottomNavigationBar(
      currentIndex: idx,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: kPrimaryColor,
      unselectedItemColor: Colors.grey,
      onTap: (i) {
        context.go(_tabs[i]);
        if (_tabs[i] == '/ledger') {
          ref.invalidate(allTransactionsProvider);
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: FaIcon(FontAwesomeIcons.house),
          label: '홈',
        ),
        BottomNavigationBarItem(
          icon: FaIcon(FontAwesomeIcons.clipboardList),
          label: '가계부',
        ),
        BottomNavigationBarItem(
          icon: FaIcon(FontAwesomeIcons.wallet),
          label: '자산',
        ),
      ],
    );

    return Scaffold(
      backgroundColor: kBackground,
      appBar: appBar,
      body: widget.child,
      bottomNavigationBar: bottomNav,
    );
  }
}
