import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import '../../constants/colors.dart';
import '../../constants/typography.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  static const _tabIndex = 0; // 홈은 0번

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: [
          // ── 1) 상단 블루 헤더
          Container(
            height: 260,
            color: kPrimaryColor,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              bottom: 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더 텍스트 + 아이콘
                Row(
                  children: [
                    Text(
                      'DoitMoney',
                      style: textTheme.titleMedium
                          ?.copyWith(fontSize: 22, color: Colors.white),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.notifications_none),
                      color: Colors.white,
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_outline),
                      color: Colors.white,
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 검색 바
                Container(
                  decoration: BoxDecoration(
                    color: kBackground,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'WWIT님 어떤 영양제를 찾으세요?',
                      hintStyle: TextStyle(
                          color: Colors.grey.shade400, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      suffixIcon:
                          Icon(Icons.search, color: kPrimaryColor, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 2) 하얀 카드 (리마인더)
          Positioned(
            top: 200,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 카드 헤더
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Text('잊지말고 챙겨드세요 ⏰',
                            style: textTheme.titleMedium),
                        const Spacer(),
                        Text('12/14(수)', style: textTheme.bodyMedium),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, size: 20),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // 타임스탬프
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text('오전 9:40',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ),

                  // 아이템 리스트
                  _InnerReminderItem(
                    title: '메가 스트렝스 베타 시토스테...',
                    count: '1정',
                    done: false,
                  ),
                  const Divider(height: 1),
                  _InnerReminderItem(
                    title: '백세효모',
                    count: '5정',
                    done: true,
                  ),
                  const Divider(height: 1),
                  _InnerReminderItem(
                    title: '킬레이트 마그네슘',
                    count: '2정',
                    done: false,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 카드 외곽 여백 맞춰서 패딩을 준 “내부” 아이템 위젯
class _InnerReminderItem extends StatelessWidget {
  final String title;
  final String count;
  final bool done;

  const _InnerReminderItem({
    Key? key,
    required this.title,
    required this.count,
    required this.done,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = done
        ? Colors.grey.shade100
        : kPrimaryColor.withOpacity(0.1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 텍스트
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(count,
                      style: textTheme.bodyMedium
                          ?.copyWith(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),

            // 완료 여부 아이콘
            if (done)
              Icon(Icons.check_circle, color: kPrimaryColor, size: 24)
            else
              DottedBorder(
                color: kPrimaryColor,
                strokeWidth: 2,
                dashPattern: [4, 4],
                borderType: BorderType.Circle,
                radius: const Radius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.check, color: kPrimaryColor, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}