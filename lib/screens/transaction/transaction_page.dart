// DoItMoneyAI/DoitMoney_Flutter/lib/screens/transaction/transaction_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../services/transaction_service.dart';
import '../../providers/transaction_providers.dart';

/// Providers
final selectedMonthProvider = StateProvider<DateTime>((_) => DateTime.now());
final lastRefreshProvider = StateProvider<DateTime>((_) => DateTime.now());
final selectedAccountsProvider = StateProvider<List<String>>((_) => []);
final allTransactionsProvider = FutureProvider.autoDispose<List<Transaction>>(
  (_) => TransactionService.fetchTransactions(),
);

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

class TransactionPage extends ConsumerWidget {
  const TransactionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: kBackground,
        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor: kBackground,
          elevation: 0,
          title: const SizedBox.shrink(),
          bottom: const PreferredSize(
            // 실제 높이보다 약간 넉넉히
            preferredSize: Size.fromHeight(180),
            child: Column(
              mainAxisSize: MainAxisSize.min, // ↲ 내용만큼만 차지
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(),
                TabBar(
                  indicatorColor: kPrimaryColor,
                  labelColor: kPrimaryColor,
                  unselectedLabelColor: Colors.black54,
                  tabs: [Tab(text: '일일'), Tab(text: '주간'), Tab(text: '달력')],
                ),
              ],
            ),
          ),
        ),
        body: const TabBarView(
          children: [DailyTab(), WeeklyTab(), CalendarTab()],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: kPrimaryColor,
          onPressed: () async {
            ref.read(lastRefreshProvider.notifier).state = DateTime.now();
            final result = await context.push<bool>('/transaction/add');
            if (result == true) ref.invalidate(allTransactionsProvider);
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final last = ref.watch(lastRefreshProvider);
    final txs = ref.watch(filteredTransactionsProvider);

    final ago = DateTime.now().difference(last);
    final agoText =
        ago.inHours > 0 ? '${ago.inHours}시간 전' : '${ago.inMinutes}분 전';

    final totalIn = txs
        .where((t) => t.amount > 0)
        .fold(0, (a, t) => a + t.amount);
    final totalOut =
        txs.where((t) => t.amount < 0).fold(0, (a, t) => a + t.amount).abs();

    final headerTextStyle = kBodyText.copyWith(fontSize: 14);
    final subHeaderTextStyle = kBodyText.copyWith(fontSize: 12);
    final amountTextStyle = kTitleText.copyWith(fontSize: 18);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1행: 월/년 선택 · 필터 · 새로고침 · 갱신시간
          Row(
            children: [
              // 월/년 선택
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final sel = await showMonthPicker(
                      context: context,
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
                      Text(
                        '${month.year}년 ${month.month}월',
                        style: headerTextStyle,
                      ),
                      const Icon(Icons.arrow_drop_down, color: kPrimaryColor),
                    ],
                  ),
                ),
              ),

              // 필터 버튼
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kInputBorder),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed:
                    () => showModalBottomSheet(
                      context: context,
                      builder: (_) => const _FilterSheet(),
                    ),
                icon: const Icon(Icons.filter_alt_outlined, size: 20),
                label: Text('필터', style: headerTextStyle),
              ),

              const SizedBox(width: 8),

              // 새로고침 버튼
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                color: kPrimaryColor,
                onPressed: () {
                  ref.read(lastRefreshProvider.notifier).state = DateTime.now();
                  ref.invalidate(allTransactionsProvider);
                },
              ),

              const SizedBox(width: 4),

              // 마지막 갱신 시간
              Text(agoText, style: subHeaderTextStyle),
            ],
          ),

          const SizedBox(height: 8),

          // 2행: 총 수입·총 지출
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '총 수입 : ${NumberFormat('#,###').format(totalIn)}원',
                style: amountTextStyle,
              ),
              const SizedBox(width: 16),
              Text(
                '총 지출 : ${NumberFormat('#,###').format(totalOut)}원',
                style: amountTextStyle.copyWith(color: kError),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthSelector extends ConsumerWidget {
  const _MonthSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    return InkWell(
      onTap: () async {
        final sel = await showMonthPicker(
          context: context,
          initialDate: month,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (sel != null) ref.read(selectedMonthProvider.notifier).state = sel;
      },
      child: Row(
        children: [
          Text('${month.year}년 ${month.month}월', style: kTitleText),
          const Icon(Icons.arrow_drop_down, color: kPrimaryColor),
        ],
      ),
    );
  }
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final selected = Set<String>.from(ref.watch(selectedAccountsProvider));

    return accountsAsync.when(
      data:
          (list) => StatefulBuilder(
            builder:
                (context, setState) => SizedBox(
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
                                  onChanged:
                                      (v) => setState(() {
                                        if (v!) {
                                          selected.add(a.institutionName);
                                        } else {
                                          selected.remove(a.institutionName);
                                        }
                                      }),
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
                            Navigator.pop(context);
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
      error: (e, _) => const Center(child: Text('오류: \$e')),
    );
  }
}

class DailyTab extends ConsumerWidget {
  const DailyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txs = ref.watch(filteredTransactionsProvider);

    return ListView.builder(
      itemCount: txs.length,
      itemBuilder: (ctx, i) {
        final t = txs[i];
        return Slidable(
          key: ValueKey(t.id),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            children: [
              SlidableAction(
                onPressed: (slidableContext) async {
                  // 1) dialogContext 로 다이얼로그를 닫게끔 builder 에 context 전달
                  final shouldDelete = await showDialog<bool>(
                    context: slidableContext,
                    builder: (dialogContext) {
                      return AlertDialog(
                        title: const Text('삭제 확인'),
                        content: const Text('정말 이 거래를 삭제하시겠습니까?'),
                        actions: [
                          TextButton(
                            onPressed:
                                () => Navigator.of(dialogContext).pop(false),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed:
                                () => Navigator.of(dialogContext).pop(true),
                            child: const Text('삭제'),
                          ),
                        ],
                      );
                    },
                  );

                  if (shouldDelete == true) {
                    try {
                      await TransactionService.deleteTransaction(t.id);
                      // 2) 슬라이더 닫기
                      Slidable.of(slidableContext)?.close();
                      // 3) 데이터 재요청
                      ref.invalidate(allTransactionsProvider);
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('삭제되었습니다')));
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
                    }
                  } else {
                    // 취소 시에도 슬라이더 닫아 주기
                    Slidable.of(slidableContext)?.close();
                  }
                },
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: '삭제',
              ),
            ],
          ),
          child: ListTile(
            title: Text(t.description),
            subtitle: Text(t.accountName),
            trailing: Text('${t.amount}원'),
            onTap: () async {
              final edited = await context.push<bool>(
                '/transaction/detail',
                extra: t,
              );
              if (edited == true) {
                ref.invalidate(allTransactionsProvider);
              }
            },
          ),
        );
      },
    );
  }
}

class WeeklyTab extends ConsumerWidget {
  const WeeklyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txs = ref.watch(filteredTransactionsProvider);
    final month = ref.watch(selectedMonthProvider);
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);

    final summaries = <Map<String, dynamic>>[];
    for (
      var start = first;
      start.isBefore(last) || start.isAtSameMomentAs(last);
      start = start.add(const Duration(days: 7))
    ) {
      final end =
          start.add(const Duration(days: 6)).isAfter(last)
              ? last
              : start.add(const Duration(days: 6));
      final weekTxs = txs.where(
        (t) =>
            !t.transactionDate.isBefore(start) &&
            !t.transactionDate.isAfter(end),
      );
      final income = weekTxs
          .where((t) => t.amount > 0)
          .fold(0, (sum, t) => sum + t.amount);
      final expense =
          weekTxs
              .where((t) => t.amount < 0)
              .fold(0, (sum, t) => sum + t.amount)
              .abs();
      summaries.add({
        'start': start,
        'end': end,
        'income': income,
        'expense': expense,
      });
    }

    final idx =
        summaries.isEmpty
            ? -1
            : (summaries.length > 2 ? 2 : summaries.length - 1);
    final diff =
        idx >= 0 ? summaries[idx]['expense'] - summaries[idx]['income'] : 0;

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
                  maxY:
                      summaries
                          .expand(
                            (s) => [s['income'] as int, s['expense'] as int],
                          )
                          .reduce((a, b) => a > b ? a : b)
                          .toDouble() *
                      1.2,
                  barGroups:
                      summaries.asMap().entries.map((e) {
                        final s = e.value;
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: (s['income'] as int).toDouble(),
                            ),
                            BarChartRodData(
                              toY: (s['expense'] as int).toDouble(),
                            ),
                          ],
                        );
                      }).toList(),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                ),
              ),
            ),
          ),
          ...summaries.asMap().entries.map((e) {
            final s = e.value;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(
                '${e.key + 1}주차 [${(s['start'] as DateTime).month}.${(s['start'] as DateTime).day}~'
                '${(s['end'] as DateTime).month}.${(s['end'] as DateTime).day}]',
                style: kBodyText,
              ),
              trailing: Text(
                '+${NumberFormat('#,###').format(s['income'])} | '
                '-${NumberFormat('#,###').format(s['expense'])}',
                style: kBodyText,
              ),
            );
          }),
        ],
      ],
    );
  }
}

class CalendarTab extends ConsumerStatefulWidget {
  const CalendarTab({super.key});

  @override
  ConsumerState<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends ConsumerState<CalendarTab> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final txs = ref.watch(filteredTransactionsProvider);

    // 날짜별로 거래 묶기
    final Map<DateTime, List<Transaction>> events = {};
    for (final t in txs) {
      final day = _normalize(t.transactionDate);
      events.putIfAbsent(day, () => []).add(t);
    }

    final selectedDay = _selected != null ? _normalize(_selected!) : null;
    // 이벤트가 없으면 빈 리스트를 반환하도록 수정
    final todayList =
        selectedDay != null
            ? (events[selectedDay] ?? <Transaction>[])
            : <Transaction>[];

    int sumIncome(List<Transaction> list) =>
        list.where((e) => e.amount > 0).fold(0, (a, e) => a + e.amount);
    int sumExpense(List<Transaction> list) =>
        list.where((e) => e.amount < 0).fold(0, (a, e) => a + e.amount).abs();

    return Column(
      children: [
        // ─── 달력 ────────────────────────────────────────────
        TableCalendar<Transaction>(
          firstDay: DateTime(2000),
          lastDay: DateTime(2100),
          focusedDay: _focused,
          selectedDayPredicate: (d) => _normalize(d) == selectedDay,
          eventLoader: (d) => events[_normalize(d)] ?? [],
          headerVisible: false,
          calendarStyle: CalendarStyle(
            // 오늘 표시
            todayDecoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, _) {
              final dayKey = _normalize(day);
              final list = events[dayKey] ?? [];
              final inSum = sumIncome(list);
              final outSum = sumExpense(list);

              return Container(
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                decoration:
                    _normalize(day) == selectedDay
                        ? BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        )
                        : null,
                child: Column(
                  children: [
                    Text(
                      '${day.day}',
                      style: kBodyText.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (inSum > 0)
                      Text(
                        '+${NumberFormat('#,###').format(inSum)}',
                        style: kBodyText.copyWith(
                          fontSize: 10,
                          color: kSuccess,
                        ),
                      ),
                    if (outSum > 0)
                      Text(
                        '-${NumberFormat('#,###').format(outSum)}',
                        style: kBodyText.copyWith(fontSize: 10, color: kError),
                      ),
                  ],
                ),
              );
            },
          ),
          onDaySelected: (sel, foc) {
            setState(() {
              _selected = sel;
              _focused = foc;
            });
          },
        ),

        // ─── 선택된 날짜 헤더 ───────────────────────────────────
        if (_selected != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_selected!.month}월 ${_selected!.day}일 '
                  '(${DateFormat.E('ko').format(_selected!)})',
                  style: kBodyText.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '+${NumberFormat('#,###').format(sumIncome(todayList))}원',
                  style: kBodyText.copyWith(color: kSuccess, fontSize: 14),
                ),
                const SizedBox(width: 12),
                Text(
                  '-${NumberFormat('#,###').format(sumExpense(todayList))}원',
                  style: kBodyText.copyWith(color: kError, fontSize: 14),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ─── 거래 목록 ─────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: todayList.length,
              itemBuilder: (ctx, i) {
                final t = todayList[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 1,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    // 거래 시간 · 수단
                    title: Text(
                      t.description,
                      style: kBodyText.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${DateFormat.Hm().format(t.transactionDate)} · ${t.accountName}',
                      style: kBodyText.copyWith(color: Colors.black54),
                    ),
                    trailing: Text(
                      '${NumberFormat('#,###').format(t.amount)}원',
                      style: kBodyText.copyWith(
                        color: t.amount < 0 ? kError : kSuccess,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () async {
                      final res = await context.push<bool>(
                        '/transaction/edit',
                        extra: t,
                      );
                      if (res == true) ref.invalidate(allTransactionsProvider);
                    },
                  ),
                );
              },
            ),
          ),
        ] else ...[
          const SizedBox(height: 24),
          const Text('날짜를 선택해 보세요.', style: kBodyText),
        ],
      ],
    );
  }
}
