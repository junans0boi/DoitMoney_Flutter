// lib/widgets/main_shell.dart
import 'package:doitmoney_flutter/providers/user_provider.dart';
import 'package:doitmoney_flutter/screens/transaction/transaction_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../constants/colors.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  /* ── 탭 <-> 경로 매핑 ─────────────────────────────── */
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
    final idx = _locationToIndex(routeInfo.location ?? '/');

    /* ── 상단 AppBar ───────────────────────────────── */
    final appBar = AppBar(
      // titleSpacing 0 ⇒ 왼쪽 여백 맞추기
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // watch the userProvider
            // now we already have `me` via ref.watch above:
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(me?.profileImageUrl ?? ''),
            ),
            const SizedBox(width: 8),
            Text(
              me?.username ?? '...로딩중',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () => context.go('/notifications'),
            ),
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => context.push('/more'), // ⇢ 더보기
            ),
          ],
        ),
      ),
    );

    /* ── 하단 탭 Bar ───────────────────────────────── */
    final bottomNav = BottomNavigationBar(
      currentIndex: idx,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: kPrimaryColor,
      unselectedItemColor: Colors.grey,
      onTap: (i) {
        // ── 1) GoRouter 이동
        context.go(_tabs[i]);
        // ── 2) '가계부' 탭이면 Provider invalidate
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
