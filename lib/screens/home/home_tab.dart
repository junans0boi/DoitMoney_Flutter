import 'package:doitmoney_flutter/providers/news_provider.dart';
import 'package:doitmoney_flutter/screens/transaction/transaction_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/news/news_banner.dart';

import '../../constants/colors.dart';
import '../../providers/fixed_expense_provider.dart';
import '../../services/transaction_service.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  final int _currentSlide = 0;
  late final PageController _pageController;

  // Dummy ad images - replace with your own
  final List<String> _adImages = [
    'https://via.placeholder.com/343x152.png?text=AD+1',
    'https://via.placeholder.com/343x152.png?text=AD+2',
    'https://via.placeholder.com/343x152.png?text=AD+3',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fixedAsync = ref.watch(fixedExpensesProvider);
    final newsAsync = ref.watch(newsProvider);
    final month = ref.watch(selectedMonthProvider);
    final txs = ref.watch(filteredTransactionsProvider);

    // totals
    final totalIn = txs
        .where((t) => t.amount > 0)
        .fold(0, (s, t) => s + t.amount);
    final totalOut = txs
        .where((t) => t.amount < 0)
        .fold(0, (s, t) => s + t.amount.abs());

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // month selector & report
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picked = await showMonthPicker(
                      context: context,
                      initialDate: month,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      ref.read(selectedMonthProvider.notifier).state = picked;
                    }
                  },
                  child: Row(
                    children: [
                      Text(
                        '${month.month}월',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: kPrimaryColor),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => context.push('/report'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kPrimaryColor),
                    foregroundColor: kPrimaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    '리포트',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── 뉴스 슬라이더
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: NewsBanner(
              height: 152,
              borderRadius: BorderRadius.all(Radius.circular(12)),
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 24),
          // summary cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: '총 수입',
                    amount: totalIn,
                    subtitle: '',
                    background: kPrimaryColor.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: '총 지출',
                    amount: totalOut,
                    subtitle: '지난달 ${NumberFormat('#,###').format(totalOut)}원',
                    background: kPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // fixed expense card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: fixedAsync.when(
              data: (list) {
                final day = DateTime.now().day;
                final upcoming = list
                    .where((e) => e.dayOfMonth > day)
                    .fold(0, (s, e) => s + e.amount);
                final completed = list
                    .where((e) => e.dayOfMonth <= day)
                    .fold(0, (s, e) => s + e.amount);
                return _StatusCard(
                  title: '정기지출',
                  items: [
                    _StatusItem(label: '지출 예정', amount: upcoming),
                    _StatusItem(label: '지출 완료', amount: completed),
                  ],
                  onTap: () => context.push('/fixed-expense'),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const Text('오류: \$e'),
            ),
          ),
          const SizedBox(height: 16),

          // variable expense card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _StatusCard(
              title: '변동지출',
              items: [
                _StatusItem(
                  label: '지출 예산',
                  amount: 0,
                  placeholder: '예산을 계획해보세요',
                ),
                _StatusItem(label: '지출', amount: totalOut),
              ],
              trailing: FloatingActionButton(
                mini: true,
                backgroundColor: kPrimaryColor,
                onPressed: () => context.push('/transaction/add'),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // category chart
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _CategoryChart(txs: txs),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final int amount;
  final String subtitle;
  final Color background;
  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            '${NumberFormat('#,###').format(amount)}원',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.white70)),
          ],
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final List<_StatusItem> items;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _StatusCard({
    required this.title,
    required this.items,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            ...items.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text(e.label), e.buildValue()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusItem {
  final String label;
  final int amount;
  final String? placeholder;
  _StatusItem({required this.label, required this.amount, this.placeholder});

  Widget buildValue() {
    if (amount == 0 && placeholder != null) {
      return Text(placeholder!, style: const TextStyle(color: Colors.black38));
    }
    return Text(
      '${NumberFormat('#,###').format(amount)}원',
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  final List<Transaction> txs;
  const _CategoryChart({required this.txs});

  @override
  Widget build(BuildContext context) {
    final data = <String, int>{};
    for (var t in txs) {
      if (t.amount < 0) {
        data[t.category] = (data[t.category] ?? 0) + t.amount.abs();
      }
    }
    final entries =
        data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<int>(0, (s, e) => s + e.value);
    final colors = [
      kPrimaryColor,
      const Color(0xFF9B51E0),
      const Color(0xFFF2994A),
      const Color(0xFFEB5757),
      const Color(0xFFF2C94C),
      const Color(0xFF2D9CDB),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '카테고리별 지출',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(onPressed: () {}, child: const Text('전체보기')),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 40,
              sections:
                  entries.asMap().entries.map((e) {
                    final idx = e.key;
                    return PieChartSectionData(
                      value: e.value.value.toDouble(),
                      color: colors[idx % colors.length],
                      radius: 60,
                      showTitle: false,
                    );
                  }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...entries.map((e) {
          final idx = entries.indexOf(e);
          final pct = (e.value / total * 100).toStringAsFixed(0);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: colors[idx % colors.length],
                ),
                const SizedBox(width: 8),
                Text('${e.key} $pct%', style: const TextStyle(fontSize: 14)),
                const Spacer(),
                Text('${NumberFormat('#,###').format(e.value)}원'),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Colors.black38,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
