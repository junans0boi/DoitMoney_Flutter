// lib/screens/transaction/transaction_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../services/transaction_service.dart';
import '../../providers/transaction_providers.dart';

const Color kSecondaryBackground = Color(0xFFF5F5F5);

/// Providers (move to a common file if needed)
final selectedMonthProvider = StateProvider<DateTime>((_) => DateTime.now());
final lastRefreshProvider = StateProvider<DateTime>((_) => DateTime.now());
final selectedAccountsProvider = StateProvider<List<String>>((_) => []);
final allTransactionsProvider = FutureProvider.autoDispose<List<Transaction>>(
  (_) => TransactionService.fetchTransactions(),
);
final filteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  final all = ref
      .watch(allTransactionsProvider)
      .maybeWhen<List<Transaction>>(
        data: (list) => list,
        orElse: () => <Transaction>[],
      );
  final month = ref.watch(selectedMonthProvider);
  final filter = ref.watch(selectedAccountsProvider);
  return all.where((t) {
    final d = t.transactionDate;
    final matchMonth = d.year == month.year && d.month == month.month;
    final matchAcc = filter.isEmpty || filter.contains(t.accountName);
    return matchMonth && matchAcc;
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
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(180),
            child: Column(
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
          onPressed: () {
            showModalBottomSheet<void>(
              context: context,
              builder:
                  (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.add),
                          title: const Text('직접 추가'),
                          onTap: () {
                            Navigator.pop(ctx);
                            ref.read(lastRefreshProvider.notifier).state =
                                DateTime.now();
                            context.push<bool>('/transaction/add').then((ok) {
                              if (ok == true)
                                ref.invalidate(allTransactionsProvider);
                            });
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('OCR로 추가'),
                          onTap: () {
                            Navigator.pop(ctx);
                            context.push('/transaction/ocr');
                          },
                        ),
                      ],
                    ),
                  ),
            );
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
        .fold(0, (s, t) => s + t.amount);
    final totalOut = txs
        .where((t) => t.amount < 0)
        .fold(0, (s, t) => s + t.amount.abs());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final pick = await showMonthPicker(
                      context: context,
                      initialDate: month,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (pick != null) {
                      ref.read(selectedMonthProvider.notifier).state = pick;
                    }
                  },
                  child: Row(
                    children: [
                      Text(
                        '${month.year}년 ${month.month}월',
                        style: kBodyText.copyWith(fontSize: 14),
                      ),
                      const Icon(Icons.arrow_drop_down, color: kPrimaryColor),
                    ],
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed:
                    () => showModalBottomSheet(
                      context: context,
                      builder: (_) => const _FilterSheet(),
                    ),
                icon: const Icon(Icons.filter_alt_outlined, size: 20),
                label: Text('필터', style: kBodyText.copyWith(fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kInputBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                color: kPrimaryColor,
                onPressed: () {
                  ref.read(lastRefreshProvider.notifier).state = DateTime.now();
                  ref.invalidate(allTransactionsProvider);
                },
              ),
              Text(agoText, style: kBodyText.copyWith(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '총 수입 : ${NumberFormat('#,###').format(totalIn)}원',
                style: kTitleText.copyWith(fontSize: 18),
              ),
              const SizedBox(width: 16),
              Text(
                '총 지출 : ${NumberFormat('#,###').format(totalOut)}원',
                style: kTitleText.copyWith(fontSize: 18, color: kError),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DailyTab extends ConsumerWidget {
  const DailyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txs = ref.watch(filteredTransactionsProvider);
    final grouped = <String, List<Transaction>>{};
    for (var t in txs) {
      final key = DateFormat('M월 d일 (E)', 'ko').format(t.transactionDate);
      grouped.putIfAbsent(key, () => []).add(t);
    }

    return ListView(
      children:
          grouped.entries.map((e) {
            final dateLabel = e.key;
            final items = e.value;
            final inSum = items
                .where((t) => t.amount > 0)
                .fold(0, (s, t) => s + t.amount);
            final outSum = items
                .where((t) => t.amount < 0)
                .fold(0, (s, t) => s + t.amount.abs());
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: kSecondaryBackground,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Text(
                        dateLabel,
                        style: kBodyText.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Text(
                        '+${NumberFormat('#,###').format(inSum)}원',
                        style: kBodyText.copyWith(color: kSuccess),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '-${NumberFormat('#,###').format(outSum)}원',
                        style: kBodyText.copyWith(color: kError),
                      ),
                    ],
                  ),
                ),
                ...items.map(
                  (t) => Slidable(
                    key: ValueKey(t.id),
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (_) async {
                            final res = await context.push<bool>(
                              '/transaction/detail',
                              extra: t,
                            );
                            if (res == true) {
                              ref.invalidate(allTransactionsProvider);
                            }
                          },
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          icon: Icons.edit,
                          label: '수정',
                        ),
                        SlidableAction(
                          onPressed: (_) async {
                            try {
                              await TransactionService.deleteTransaction(t.id);
                              ref.invalidate(allTransactionsProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('삭제되었습니다')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('삭제 실패: \$e')),
                              );
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
                      leading: CircleAvatar(
                        backgroundColor: kPrimaryColor.withOpacity(0.1),
                        child: const Icon(
                          Icons.receipt_long,
                          color: kPrimaryColor,
                        ),
                      ),
                      title: Text(
                        t.description,
                        style: kBodyText.copyWith(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        '${DateFormat.Hm().format(t.transactionDate)} · ${t.accountName}',
                        style: kBodyText.copyWith(fontSize: 12),
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
                          '/transaction/detail',
                          extra: t,
                        );
                        if (res == true) {
                          ref.invalidate(allTransactionsProvider);
                        }
                      },
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
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

    final weeks = <Map<String, dynamic>>[];
    for (
      var start = first;
      start.isBefore(last) || start.isAtSameMomentAs(last);
      start = start.add(const Duration(days: 7))
    ) {
      final end =
          start.add(const Duration(days: 6)).isAfter(last)
              ? last
              : start.add(const Duration(days: 6));
      final weekTx =
          txs
              .where(
                (t) =>
                    !t.transactionDate.isBefore(start) &&
                    !t.transactionDate.isAfter(end),
              )
              .toList();
      final inSum = weekTx
          .where((t) => t.amount > 0)
          .fold(0, (s, t) => s + t.amount);
      final outSum = weekTx
          .where((t) => t.amount < 0)
          .fold(0, (s, t) => s + t.amount.abs());
      weeks.add({'start': start, 'end': end, 'in': inSum, 'out': outSum});
    }
    final idx = weeks.isEmpty ? -1 : (weeks.length > 2 ? 2 : weeks.length - 1);
    final diff = idx >= 0 ? weeks[idx]['out'] - weeks[idx]['in'] : 0;

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
        if (weeks.isNotEmpty)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: BarChart(
                BarChartData(
                  barGroups:
                      weeks.asMap().entries.map((e) {
                        final w = e.value;
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(toY: (w['in'] as int).toDouble()),
                            BarChartRodData(toY: (w['out'] as int).toDouble()),
                          ],
                        );
                      }).toList(),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  alignment: BarChartAlignment.spaceAround,
                ),
              ),
            ),
          ),
        ...weeks.asMap().entries.map((e) {
          final w = e.value;
          final start = w['start'] as DateTime;
          final end = w['end'] as DateTime;
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Text(
              '${e.key + 1}주차 [${start.month}.${start.day}~${end.month}.${end.day}]',
              style: kBodyText,
            ),
            trailing: Text(
              '+${NumberFormat('#,###').format(w['in'])} | -${NumberFormat('#,###').format(w['out'])}',
              style: kBodyText,
            ),
          );
        }),
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
  DateTime normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final txs = ref.watch(filteredTransactionsProvider);
    final events = <DateTime, List<Transaction>>{};
    for (var t in txs) {
      final d = normalize(t.transactionDate);
      events.putIfAbsent(d, () => []).add(t);
    }
    final selected = _selected != null ? normalize(_selected!) : null;

    int sumIn(List<Transaction> l) =>
        l.where((e) => e.amount > 0).fold(0, (s, e) => s + e.amount);
    int sumOut(List<Transaction> l) =>
        l.where((e) => e.amount < 0).fold(0, (s, e) => s + e.amount.abs());

    return Column(
      children: [
        TableCalendar<Transaction>(
          firstDay: DateTime(2000),
          lastDay: DateTime(2100),
          focusedDay: _focused,
          selectedDayPredicate: (d) => normalize(d) == selected,
          eventLoader: (d) => events[normalize(d)] ?? [],
          headerVisible: false,
          calendarStyle: CalendarStyle(
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
            defaultBuilder: (ctx, day, _) {
              final key = normalize(day);
              final list = events[key] ?? [];
              final inSum = sumIn(list);
              final outSum = sumOut(list);
              return Container(
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                decoration:
                    normalize(day) == selected
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
          onDaySelected:
              (day, focus) => setState(() {
                _selected = day;
                _focused = focus;
              }),
        ),
        if (selected != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_selected!.month}월 ${_selected!.day}일 (${DateFormat.E('ko').format(_selected!)})',
                  style: kBodyText.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '+${NumberFormat('#,###').format(sumIn(events[selected]!))}원',
                  style: kBodyText.copyWith(color: kSuccess, fontSize: 14),
                ),
                const SizedBox(width: 12),
                Text(
                  '-${NumberFormat('#,###').format(sumOut(events[selected]!))}원',
                  style: kBodyText.copyWith(color: kError, fontSize: 14),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: events[selected]!.length,
              itemBuilder: (ctx, i) {
                final t = events[selected]![i];
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
                    leading: CircleAvatar(
                      backgroundColor: kPrimaryColor.withOpacity(0.1),
                      child: const Icon(
                        Icons.receipt_long,
                        color: kPrimaryColor,
                      ),
                    ),
                    title: Text(
                      t.description,
                      style: kBodyText.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${DateFormat.Hm().format(t.transactionDate)} · ${t.accountName}',
                      style: kBodyText.copyWith(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
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
          const Center(child: Text('날짜를 선택해 보세요.', style: kBodyText)),
        ],
      ],
    );
  }
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    // 모달이 열릴 때마다 초기 선택 상태를 복사해 둡니다.
    final initial = ref.read(selectedAccountsProvider);
    final selected = Set<String>.from(initial);

    return accountsAsync.when(
      data: (list) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  const Divider(height: 1),
                  ...list.map((a) {
                    return CheckboxListTile(
                      title: Text(a.institutionName),
                      value: selected.contains(a.institutionName),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            selected.add(a.institutionName);
                          } else {
                            selected.remove(a.institutionName);
                          }
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                    ),
                    onPressed: () {
                      // 최종 선택한 항목만 provider 에 저장
                      ref.read(selectedAccountsProvider.notifier).state =
                          selected.toList();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      '저장',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
      loading:
          () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
      error:
          (e, _) => Padding(
            padding: const EdgeInsets.all(32),
            child: Center(child: Text('오류: $e')),
          ),
    );
  }
}
