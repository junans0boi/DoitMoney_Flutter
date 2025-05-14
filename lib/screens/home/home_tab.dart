import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/colors.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 정보 배너 --------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // ↓ withAlpha 로 교체해 deprecation 제거
                color: kPrimaryColor.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('내 모든 지출을 불러와', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 4),
                  Text(
                    '똑똑하게 지출을 관리 해보세요.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '수입 지출 현황을 분석하고 매월 남는 돈을 늘려보세요.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 정기지출 --------------------------------------------------------
          const _SectionCard(
            title: '정기지출',
            subtitle: '매달 정기적으로 나가는 지출 확인하기',
            children: [
              _IconItem(icon: Icons.smartphone, label: '통신'),
              _IconItem(icon: FontAwesomeIcons.umbrella, label: '보험'),
              _IconItem(icon: FontAwesomeIcons.building, label: '주거·관리'),
              _IconItem(icon: FontAwesomeIcons.solidEnvelope, label: '구독'),
            ],
          ),
          const SizedBox(height: 16),

          // 할부지출 --------------------------------------------------------
          const _SectionCard(
            title: '할부지출',
            subtitle: '앞으로 나갈 카드할부값이 매달 얼마인지 확인하기',
            children: [
              Center(
                child: Icon(
                  FontAwesomeIcons.creditCard,
                  size: 48,
                  color: kPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // TODO: 변동지출 섹션 ------------------------------------------------
        ],
      ),
    );
  }
}

/* ── 재사용 위젯들 ─────────────────────────────────────────────────────── */
class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  const _SectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000), // 0x14 == 8% 불투명
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: children,
            ),
          ],
        ),
      ),
    );
  }
}

class _IconItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _IconItem({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kPrimaryColor.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 28, color: kPrimaryColor),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
