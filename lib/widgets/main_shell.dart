// lib/widgets/main_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../constants/colors.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
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
            const CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage('assets/images/doitmoney_logo.png'),
            ),
            const SizedBox(width: 8),
            const Text(
              '이준환님', // 실제 프로필 Provider로 교체 가능
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
      onTap: (i) => context.go(_tabs[i]),
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
