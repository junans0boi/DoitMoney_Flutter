import 'package:doitmoney_flutter/features/auth/providers/auth_provider.dart';
import 'package:doitmoney_flutter/features/auth/providers/user_provider.dart';
import 'package:doitmoney_flutter/features/more/providers/more_providers.dart';
import 'package:doitmoney_flutter/shared/widgets/common_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ↓ dio import 필수
import '../../../core/api/dio_client.dart';
import 'package:dio/dio.dart';

import '../../../constants/colors.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(userProvider);
    final points = ref.watch(pointProvider);
    final isDarkMode = ref.watch(darkModeProvider);

    // ─────────────────────────────────────────────────────────
    // 프로필 이미지 URL 조립 (dio.options.baseUrl 에서 "/api" 제거)
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
    // ─────────────────────────────────────────────────────────

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
            onTap: () {
              // 프로필 편집 화면으로 이동
              context.push('/profile-edit');
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
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child:
                        avatarUrl == null
                            ? const Icon(
                              Icons.person,
                              size: 28,
                              color: Colors.grey,
                            )
                            : null,
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
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Colors.black45),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          /* ── 포인트 카드 ──────────────────────────── */
          InkWell(
            onTap: () {
              context.push('/points');
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kPrimaryColor.withAlpha((0.08 * 255).round()),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: kPrimaryColor,
                    child: const Text(
                      'P',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$points P',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.black45),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          /* ── 단축 메뉴 4개 ─────────────────────────── */
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _QuickMenu(
                icon: Icons.campaign,
                label: '공지사항',
                onTap: () => context.push('/notice'),
              ),
              _QuickMenu(
                icon: Icons.event_note,
                label: '이벤트',
                onTap: () => context.push('/event'),
              ),
              _QuickMenu(
                icon: Icons.help_outline,
                label: '자주묻는질문',
                onTap: () => context.push('/faq'),
              ),
              _QuickMenu(
                icon: Icons.chat,
                label: '1:1문의',
                onTap: () => context.push('/support'),
              ),
            ],
          ),
          const SizedBox(height: 40),

          /* ── 자동 로그인 토글 ───────────────────────── */
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('자동 로그인'),
            value: true,
            onChanged: (v) {
              // TODO: 자동 로그인 상태 변경 로직
            },
            activeTrackColor: kPrimaryColor,
          ),

          /* ── 문자 알림 서비스 진입 버튼 ─────────────── */
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: kPrimaryColor,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
              onPressed: () => context.push('/sms_alert'),
              child: const Text('문자 알림 서비스'),
            ),
          ),
          //  알림 서비스 진입 버튼
          CommonListItem(
            label: '알림 수신 서비스',
            showArrow: true,
            onTap: () => context.push('/notification_alert'),
          ),
          const SizedBox(height: 16),

          /* ── 고객센터 / 정책 링크 ───────────────────── */
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('고객센터'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/customer-service'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('이용약관'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/terms-of-service'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('개인정보처리방침'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/privacy-policy'),
          ),
          const SizedBox(height: 24),

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

          const SizedBox(height: 32),

          /* ── 버전 정보 ───────────────────────────────── */
          Center(
            child: Text(
              '버전 1.0.0',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _QuickMenu extends StatelessWidget {
  const _QuickMenu({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
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
      ),
    );
  }
}
