// lib/screens/more/more_page.dart
import 'package:doitmoney_flutter/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          /* ── 프로필 카드 ───────────────────────────── */
          InkWell(
            onTap: () {}, // 프로필 편집 등
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
                  const CircleAvatar(
                    radius: 28,
                    backgroundImage: AssetImage(
                      'assets/images/doitmoney_logo.png',
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '이준환님',
                      style: TextStyle(
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

          /* ── 포인트 카드 ──────────────────────────── */
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

          /* ── 단축 메뉴 4개 ─────────────────────────── */
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _QuickMenu(icon: Icons.campaign, label: '공지사항'),
              _QuickMenu(icon: Icons.event_note, label: '이벤트'),
              _QuickMenu(icon: Icons.help_outline, label: '자주묻는질문'),
              _QuickMenu(icon: Icons.chat, label: '1:1문의'),
            ],
          ),
          const SizedBox(height: 40),

          /* ── 자동로그인 토글 ───────────────────────── */
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('자동 로그인'),
            value: true,
            onChanged: (v) {},
            activeThumbColor: kPrimaryColor, // ✅ 대체 속성
          ),

          /* ── 문자 알림 서비스 진입 버튼 ─────────────── */
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero, // 왼쪽 정렬
                foregroundColor: kPrimaryColor,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
              onPressed: () => context.push('/sms-alert'),
              child: const Text('문자 알림 서비스'),
            ),
          ),
          /* ── 로그아웃 버튼 ───────────────────────────── */
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: Colors.red,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
              onPressed: () async {
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) context.go('/login');
              },
              child: const Text('로그아웃'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickMenu extends StatelessWidget {
  const _QuickMenu({required this.icon, required this.label});
  final IconData icon;
  final String label;

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
