// lib/screens/main_tabs.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/colors.dart';

class MainTabs extends StatefulWidget {
  const MainTabs({super.key});

  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const Center(child: Text('홈')),
    const Center(child: Text('자산')),
    const Center(child: Text('가계부')),
    const Center(child: Text('차트')),
    const Center(child: Text('더보기')),
  ];

  final List<String> _titles = ['DoitMoney', '자산', '가계부', '차트', '더보기'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            fontFamily: 'GmarketSansBold',
            color: kPrimaryColor,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.house),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.wallet),
            label: '자산',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.clipboardList),
            label: '가계부',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.chartLine),
            label: '차트',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.ellipsis),
            label: '더보기',
          ),
        ],
      ),
    );
  }
}