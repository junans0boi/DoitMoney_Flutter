import 'package:flutter/material.dart';
import '../constants/colors.dart';

typedef OnTabSelected = void Function(int index);

class BottomNav extends StatelessWidget {
  /// 현재 선택된 탭 인덱스
  final int currentIndex;

  /// 탭이 눌렸을 때 호출되는 콜백
  final OnTabSelected onTabSelected;

  const BottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTabSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTabSelected,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: kPrimaryColor,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home),       label: '홈'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart),  label: '분석'),
        BottomNavigationBarItem(icon: Icon(Icons.book),       label: '가계부'),
        BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: '차트'),
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: '더보기'),
      ],
    );
  }
}