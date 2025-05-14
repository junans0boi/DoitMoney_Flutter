// DoitMoney_Flutter/lib/screens/transaction/transaction_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../services/transaction_service.dart';
import '../../services/account_service.dart';

/// --- Providers ---
/// 선택된 월
final selectedMonthProvider = StateProvider<DateTime>((_) => DateTime.now());

/// 마지막 새로고침 시각
final lastRefreshProvider = StateProvider<DateTime>((_) => DateTime.now());

/// 선택된 계정 필터 목록
final selectedAccountsProvider = StateProvider<List<String>>((_) => []);

/// 전체 거래
final allTransactionsProvider = FutureProvider.autoDispose<List<Transaction>>(
  (_) => TransactionService.fetchTransactions(),
);

/// 전체 계정
final accountsProvider = FutureProvider.autoDispose<List<Account>>(
  (_) => AccountService.fetchAccounts(),
);

/// 필터 적용된 거래
final filteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  final txs = ref
      .watch(allTransactionsProvider)
      .maybeWhen(data: (list) => list, orElse: () => <Transaction>[]);
  final month = ref.watch(selectedMonthProvider);
  final sel = ref.watch(selectedAccountsProvider);
  return txs.where((t) {
    final d = t.transactionDate;
    final okMonth = d.year == month.year && d.month == month.month;
    final okAccount = sel.isEmpty || sel.contains(t.accountName);
    return okMonth && okAccount;
  }).toList();
});

/// 주간 탭을 위한 데이터 모델
class _WeekSummary {
  final DateTime start;
  final DateTime end;
  final int income;
  final int expense;

  _WeekSummary({
    required this.start,
    required this.end,
    required this.income,
    required this.expense,
  });
}

class LedgerPage extends ConsumerWidget {
  const LedgerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext c, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: kBackground,
        appBar: AppBar(
          backgroundColor: kBackground,
          elevation: 0,
          title: const _Header(),
          bottom: const TabBar(
            indicatorColor: kPrimaryColor,
            labelColor: kPrimaryColor,
            unselectedLabelColor: Colors.black54,
            tabs: [Tab(text: '일일'), Tab(text: '주간'), Tab(text: '달력')],
          ),
        ),
        body: const TabBarView(
          children: [DailyTab(), WeeklyTab(), CalendarTab()],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: kPrimaryColor,
          onPressed: () async {
            ref.read(lastRefreshProvider.notifier).state = DateTime.now();
            await c.push('/transaction/add');
            ref.refresh(allTransactionsProvider);
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

/// 상단 헤더: 월 선택, 필터, 새로고침 시각, 통계
class _Header extends ConsumerWidget {
  const _Header({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final last = ref.watch(lastRefreshProvider);
    final ago = DateTime.now().difference(last);
    final agoText =
        ago.inHours > 0 ? '${ago.inHours}시간 전' : '${ago.inMinutes}분 전';

    final txs = ref.watch(filteredTransactionsProvider);
    final totalIn = txs
        .where((t) => t.amount > 0)
        .fold(0, (p, t) => p + t.amount);
    final totalOut = txs
        .where((t) => t.amount < 0)
        .fold(0, (p, t) => p + t.amount);

    return Row(
      children: [
        // 월 선택
        const Expanded(child: _MonthSelector()),
        // 필터
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: kInputBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed:
              () => showModalBottomSheet(
                context: c,
                builder: (_) => const _FilterSheet(),
              ),
          icon: const Icon(Icons.filter_alt_outlined),
          label: const Text('필터'),
        ),
        const SizedBox(width: 8),
        // 새로고침 시각
        Text(agoText, style: kBodyText),
        const SizedBox(width: 8),
        // 통계
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('총 수입', style: kBodyText),
            Text(
              '${NumberFormat('#,###').format(totalIn)}원',
              style: kTitleText,
            ),
            const SizedBox(height: 4),
            Text('총 지출', style: kBodyText),
            Text(
              '${NumberFormat('#,###').format(totalOut.abs())}원',
              style: kTitleText.copyWith(color: kError),
            ),
          ],
        ),
      ],
    );
  }
}

/// 월 선택 위젯
class _MonthSelector extends ConsumerWidget {
  const _MonthSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    return InkWell(
      onTap: () async {
        final sel = await showMonthPicker(
          context: c,
          initialDate: month,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (sel != null) {
          ref.read(selectedMonthProvider.notifier).state = sel;
        }
      },
      child: Row(
        children: [
          Text('${month.month}월', style: kTitleText),
          const Icon(Icons.arrow_drop_down, color: kPrimaryColor),
        ],
      ),
    );
  }
}

/// 필터 바텀시트 (계정 선택)
class _FilterSheet extends ConsumerWidget {
  const _FilterSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final selected = Set<String>.from(ref.watch(selectedAccountsProvider));

    return accountsAsync.when(
      data:
          (list) => StatefulBuilder(
            builder:
                (c2, setSt) => SizedBox(
                  height: 400,
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          '자산 선택',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView(
                          children:
                              list.map((a) {
                                return CheckboxListTile(
                                  title: Text(a.institutionName),
                                  value: selected.contains(a.institutionName),
                                  onChanged: (v) {
                                    setSt(() {
                                      if (v == true)
                                        selected.add(a.institutionName);
                                      else
                                        selected.remove(a.institutionName);
                                    });
                                  },
                                );
                              }).toList(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                          ),
                          onPressed: () {
                            ref.read(selectedAccountsProvider.notifier).state =
                                selected.toList();
                            Navigator.pop(c2);
                          },
                          child: const Text(
                            '저장',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
    );
  }
}

/// 일일 탭
class DailyTab extends ConsumerWidget {
  const DailyTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final txs = ref.watch(filteredTransactionsProvider);
    final map = <DateTime, List<Transaction>>{};
    for (var t in txs) {
      final day = DateTime(
        t.transactionDate.year,
        t.transactionDate.month,
        t.transactionDate.day,
      );
      map.putIfAbsent(day, () => []).add(t);
    }
    final days = map.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      itemCount: days.length,
      itemBuilder: (ctx, i) {
        final day = days[i];
        final list = map[day]!;
        final inSum = list
            .where((t) => t.amount > 0)
            .fold(0, (a, t) => a + t.amount);
        final outSum = list
            .where((t) => t.amount < 0)
            .fold(0, (a, t) => a + t.amount);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: kBackground,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '${day.month}월 ${day.day}일 (${_weekday(day)})  '
                '+${NumberFormat('#,###').format(inSum)} | -${NumberFormat('#,###').format(outSum.abs())}',
                style: kBodyText,
              ),
            ),
            ...list.map((t) {
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(
                  t.description,
                  style: kBodyText.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  t.accountName,
                  style: kBodyText.copyWith(color: Colors.black45),
                ),
                trailing: Text(
                  '${NumberFormat('#,###').format(t.amount)}원',
                  style: kBodyText.copyWith(
                    color: t.amount < 0 ? kError : kSuccess,
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  String _weekday(DateTime d) =>
      ['월', '화', '수', '목', '금', '토', '일'][d.weekday - 1];
}

/// 주간 탭
class WeeklyTab extends ConsumerWidget {
  const WeeklyTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final txs = ref.watch(filteredTransactionsProvider);
    final month = ref.watch(selectedMonthProvider);
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);

    // 주차별 합계 계산
    final summaries = <_WeekSummary>[];
    for (
      var start = first;
      start.isBefore(last) || start.isAtSameMomentAs(last);
      start = start.add(const Duration(days: 7))
    ) {
      final end =
          start.add(const Duration(days: 6)).isAfter(last)
              ? last
              : start.add(const Duration(days: 6));
      final list = txs.where(
        (t) =>
            !t.transactionDate.isBefore(start) &&
            !t.transactionDate.isAfter(end),
      );
      final income = list
          .where((t) => t.amount > 0)
          .fold(0, (a, t) => a + t.amount);
      final expense =
          list.where((t) => t.amount < 0).fold(0, (a, t) => a + t.amount).abs();
      summaries.add(
        _WeekSummary(start: start, end: end, income: income, expense: expense),
      );
    }

    final idx = summaries.isEmpty ? -1 : (summaries.length > 2 ? 2 : 0);
    final diff = idx >= 0 ? summaries[idx].expense - summaries[idx].income : 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            idx >= 0
                ? '${idx + 1}주차는 수입보다 지출이 ${NumberFormat('#,###').format(diff)}원 더 많아요'
                : '데이터가 없습니다',
            style: kBodyText,
          ),
        ),
        if (summaries.isNotEmpty) ...[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups:
                      summaries.asMap().entries.map((e) {
                        final s = e.value;
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(toY: s.income.toDouble()),
                            BarChartRodData(toY: s.expense.toDouble()),
                          ],
                        );
                      }).toList(),
                  titlesData: const FlTitlesData(show: false),
                ),
              ),
            ),
          ),
          ...summaries.asMap().entries.map((e) {
            final s = e.value;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(
                '${e.key + 1}주차 [${s.start.month}.${s.start.day}~${s.end.month}.${s.end.day}]',
                style: kBodyText,
              ),
              trailing: Text(
                '+${NumberFormat('#,###').format(s.income)} | -${NumberFormat('#,###').format(s.expense)}',
                style: kBodyText,
              ),
            );
          }).toList(),
        ],
      ],
    );
  }
}

/// 달력 탭
class CalendarTab extends ConsumerStatefulWidget {
  const CalendarTab({Key? key}) : super(key: key);
  @override
  ConsumerState<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends ConsumerState<CalendarTab> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  @override
  Widget build(BuildContext c) {
    final txs = ref.watch(filteredTransactionsProvider);
    final events = <DateTime, List<Transaction>>{};
    for (var t in txs) {
      final d = DateTime(
        t.transactionDate.year,
        t.transactionDate.month,
        t.transactionDate.day,
      );
      events.putIfAbsent(d, () => []).add(t);
    }

    return Column(
      children: [
        TableCalendar<Transaction>(
          firstDay: DateTime(2000),
          lastDay: DateTime(2100),
          focusedDay: _focused,
          selectedDayPredicate: (d) => isSameDay(_selected, d),
          eventLoader: (d) => events[d] ?? [],
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: kPrimaryColor,
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(
              color: kError,
              shape: BoxShape.circle,
            ),
          ),
          headerVisible: false,
          onDaySelected: (sel, foc) {
            setState(() {
              _selected = sel;
              _focused = foc;
            });
          },
        ),
        if (_selected != null) const Expanded(child: DailyTab()),
      ],
    );
  }
}
