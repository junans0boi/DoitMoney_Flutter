// lib/features/home/screens/home_screen.dart

import 'package:doitmoney_flutter/features/transaction/providers/transaction_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

import '../../../constants/colors.dart';
import '../../../shared/widgets/news_banner.dart';
import '../../fixed_expense/providers/fixed_expense_provider.dart';
import '../../transaction/services/transaction_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // 시작 위치 (화면 우측 하단)
  Offset _fabOffset = const Offset(300, 600);

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(selectedMonthProvider);
    final txs = ref.watch(filteredTransactionsProvider);
    final fixedAsync = ref.watch(fixedExpensesProvider);

    // 수입/지출 합계 계산
    final totalIn = txs
        .where((t) => t.amount > 0)
        .fold<int>(0, (sum, t) => sum + t.amount);
    final totalOut = txs
        .where((t) => t.amount < 0)
        .fold<int>(0, (sum, t) => sum + t.amount.abs());

    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(filteredTransactionsProvider);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  const SizedBox(height: 8),

                  // ─── 요약 카드 ───
                  // (int → double) 캐스팅 추가
                  _buildSummaryCard(
                    (totalIn + totalOut).toDouble(),
                    txs.length,
                  ),

                  const SizedBox(height: 16),

                  // ─── 뉴스 배너 ───
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: NewsBanner(
                      height: 120,
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─── 월 선택 & 리포트 버튼 ───
                  _buildMonthSelector(context, ref, month),

                  const SizedBox(height: 24),

                  // ─── 요약 카드들 (총 수입 / 총 지출) ───
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: '총 수입',
                          amount: totalIn,
                          subtitle: '',
                          // withOpacity 대신 withAlpha 사용
                          backgroundColor: kPrimaryColor.withAlpha(
                            (0.6 * 255).round(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: '총 지출',
                          amount: totalOut,
                          subtitle: '지난달 ${_formatCurrency(totalOut)}',
                          backgroundColor: kPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                  // --------------------------------------------------------------------------------
                  const SizedBox(height: 24),

                  // ─── 정기지출 현황 카드 ───
                  fixedAsync.when(
                    data: (list) {
                      final today = DateTime.now().day;
                      final upcoming = list
                          .where((e) => e.dayOfMonth > today)
                          .fold<int>(0, (s, e) => s + e.amount);
                      final completed = list
                          .where((e) => e.dayOfMonth <= today)
                          .fold<int>(0, (s, e) => s + e.amount);

                      return _StatusCard(
                        title: '정기지출',
                        items: [
                          _StatusItem(label: '지출 예정', amount: upcoming),
                          _StatusItem(label: '지출 완료', amount: completed),
                        ],
                        onTap: () => context.push('/fixed-expense'),
                      );
                    },
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error:
                        (e, _) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            '오류: $e',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                  ),

                  const SizedBox(height: 16),

                  // ─── 변동지출 카드 ───
                  _StatusCard(
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

                  const SizedBox(height: 24),

                  // ─── 카테고리별 지출 차트 ───
                  _CategoryChart(txs: txs),
                ],
              ),
            ),
          ),
          // 드래그 가능한 채팅 플로팅 버튼
          // ── 드래그 가능한 채팅 플로팅 버튼 ──
          Positioned(
            left: _fabOffset.dx,
            top: _fabOffset.dy,
            child: GestureDetector(
              onPanUpdate:
                  (details) => setState(() {
                    _fabOffset += details.delta;
                  }),
              child: SizedBox(
                width: 72, // 원하는 크기로 조정
                height: 72, // 원하는 크기로 조정
                child: FloatingActionButton(
                  onPressed: () => context.push('/advisor'),
                  backgroundColor: Colors.white,
                  shape: const CircleBorder(), // 원형 모양 강제 지정
                  child: const Icon(
                    Icons.chat_bubble,
                    size: 32,
                    color: kPrimaryColor,
                  ), // 아이콘 크기도 키움
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double total, int count) {
    return Container(
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('총자산', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(
            _formatCurrency(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.list_alt, size: 16),
            label: Text('$count개 자산 합계', style: const TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withAlpha((0.2 * 255).round()),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(
    BuildContext context,
    WidgetRef ref,
    DateTime month,
  ) {
    return Padding(
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
                  '${month.year}년 ${month.month}월',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, color: kPrimaryColor),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => context.push('/report'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: kPrimaryColor),
              foregroundColor: kPrimaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              '리포트',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(num v) {
    return '${v.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}원';
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final int amount;
  final String subtitle;
  final Color backgroundColor;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            '${_formatComma(amount)}원',
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

  String _formatComma(int v) {
    return v.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
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
            _buildStatusHeader(),
            const SizedBox(height: 12),
            _buildStatusItems(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }

  Widget _buildStatusItems() {
    return Column(
      children:
          items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(item.label), item.buildValue()],
                  ),
                ),
              )
              .toList(),
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
      '${_formatComma(amount)}원',
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
  }

  String _formatComma(int v) {
    return v.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
  }
}

class _CategoryChart extends StatelessWidget {
  final List<Transaction> txs;

  const _CategoryChart({required this.txs});

  @override
  Widget build(BuildContext context) {
    final dataMap = <String, int>{};
    for (var t in txs) {
      if (t.amount < 0) {
        dataMap[t.category] = (dataMap[t.category] ?? 0) + t.amount.abs();
      }
    }
    final entries =
        dataMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);

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
        _buildChartHeader(),
        const SizedBox(height: 12),
        _buildPieChart(entries, colors),
        const SizedBox(height: 16),
        _buildLegend(entries, colors, total),
      ],
    );
  }

  Widget _buildChartHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '카테고리별 지출',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton(onPressed: () {}, child: const Text('전체보기')),
      ],
    );
  }

  Widget _buildPieChart(
    List<MapEntry<String, int>> entries,
    List<Color> colors,
  ) {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          centerSpaceRadius: 40.0,
          sections:
              entries.asMap().entries.map((e) {
                final idx = e.key;
                final value = e.value.value.toDouble();
                return PieChartSectionData(
                  value: value,
                  color: colors[idx % colors.length],
                  radius: 60.0, // double 로 수정
                  showTitle: false,
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildLegend(
    List<MapEntry<String, int>> entries,
    List<Color> colors,
    int total,
  ) {
    return Column(
      children:
          entries.map((entry) {
            final idx = entries.indexOf(entry);
            final pct =
                total == 0
                    ? '0'
                    : ((entry.value / total * 100).round()).toString();
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
                  Text(
                    '${entry.key} $pct%',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const Spacer(),
                  Text('${_formatComma(entry.value)}원'),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Colors.black38,
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  String _formatComma(int v) {
    return v.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
  }
}
