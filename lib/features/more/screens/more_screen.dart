// lib/features/more/screens/more_page.dart

import 'package:doitmoney_flutter/shared/widgets/common_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(userProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('더보기', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        children: [
          // 프로필 카드
          InkWell(
            onTap: () {
              // 프로필 편집 화면으로 이동 (미구현)
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(me?.profileImageUrl ?? ''),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      me?.username ?? '로딩중...',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: kPrimaryColor),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '내 쿠폰',
                      style: TextStyle(
                        fontSize: 12,
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.black45),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 포인트 카드
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kPrimaryColor.withAlpha((0.08 * 255).round()),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: kPrimaryColor,
                  child: Text(
                    'P',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '0 P',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Spacer(),
                Icon(Icons.chevron_right, color: Colors.black45),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 단축 메뉴 4개
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _QuickMenu(icon: Icons.campaign, label: '공지사항'),
              _QuickMenu(icon: Icons.event_note, label: '이벤트'),
              _QuickMenu(icon: Icons.help_outline, label: '자주묻는질문'),
              _QuickMenu(icon: Icons.chat, label: '1:1문의'),
            ],
          ),
          const SizedBox(height: 40),

          // 자동로그인 토글 (예시로 고정된 값만 사용)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('자동 로그인'),
            value: true,
            onChanged: (v) {
              // 토글에는 로직 추가 가능
            },
            activeTrackColor: kPrimaryColor,
          ),

          // 문자 알림 서비스 진입 버튼
          CommonListItem(
            label: '문자 알림 서비스',
            showArrow: true,
            onTap: () => context.push('/sms-alert'),
          ),

          // 로그아웃 버튼
          CommonListItem(
            label: '로그아웃',
            valueColor: Colors.red,
            onTap: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

class _QuickMenu extends StatelessWidget {
  final IconData icon;
  final String label;
  const _QuickMenu({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: kPrimaryColor.withAlpha((0.08 * 255).round()),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: kPrimaryColor),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
