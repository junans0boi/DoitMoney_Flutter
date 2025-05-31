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
import 'package:doitmoney_flutter/widgets/common/loading_progress_dialog.dart';

import './_filter_sheet.dart';
import 'transaction_group.dart';
import 'transaction_tile.dart';

const Color kSecondaryBackground = Color(0xFFF5F5F5);

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
          child: const Icon(Icons.add),
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
                            // use ref, not context
                            ref.read(lastRefreshProvider.notifier).state =
                                DateTime.now();
                            context.push<bool>('/transaction/add').then((ok) {
                              if (ok == true) {
                                ref.invalidate(allTransactionsProvider);
                              }
                            });
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('PDF/엑셀파일로 추가'),
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
                      builder: (_) => const FilterSheet(),
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
            children: [
              Flexible(
                child: Text(
                  '총 수입 : ${NumberFormat('#,###').format(totalIn)}원',
                  style: kTitleText.copyWith(fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  '총 지출 : ${NumberFormat('#,###').format(totalOut)}원',
                  style: kTitleText.copyWith(fontSize: 18, color: kError),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DailyTab extends ConsumerStatefulWidget {
  const DailyTab({super.key});
  @override
  ConsumerState<DailyTab> createState() => _DailyTabState();
}

class _DailyTabState extends ConsumerState<DailyTab> {
  final _selectedIds = <int>{};
  bool get _selectMode => _selectedIds.isNotEmpty;

  void _toggle(int id) => setState(() {
    if (_selectedIds.contains(id))
      _selectedIds.remove(id);
    else
      _selectedIds.add(id);
  });

  void _toggleAll(List<Transaction> list) => setState(() {
    if (_selectedIds.length == list.length) {
      _selectedIds.clear();
    } else {
      _selectedIds
        ..clear()
        ..addAll(list.map((e) => e.id));
    }
  });

  Future<void> _deleteSel() async {
    final ids =
        ref
            .read(filteredTransactionsProvider)
            .where((t) => _selectedIds.contains(t.id))
            .map((t) => t.id)
            .toList();
    final progress = ValueNotifier<double>(0);

    LoadingProgressDialog.show(context, title: '거래 삭제 중…', progress: progress);

    for (var i = 0; i < ids.length; i++) {
      try {
        await TransactionService.deleteTransaction(ids[i]);
      } catch (_) {}
      progress.value = (i + 1) / ids.length;
    }

    Navigator.of(context, rootNavigator: true).pop();
    progress.dispose();
    _selectedIds.clear();
    ref.invalidate(allTransactionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final txs = ref.watch(filteredTransactionsProvider);

    if (_selectMode) {
      return Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: SizedBox(
          width: 260,
          child: Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: kError),
                  onPressed: _deleteSel,
                  child: const Text('선택 삭제'),
                ),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () => _toggleAll(txs),
                icon: Icon(
                  _selectedIds.length == txs.length
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                ),
                label: const Text('전체 선택'),
              ),
            ],
          ),
        ),
        body: _buildList(txs),
      );
    }

    return _buildList(txs);
  }

  Widget _buildList(List<Transaction> txs) {
    // 1) group by date
    final grouped = <DateTime, List<Transaction>>{};
    for (var t in txs) {
      final day = DateTime(
        t.transactionDate.year,
        t.transactionDate.month,
        t.transactionDate.day,
      );
      grouped.putIfAbsent(day, () => []).add(t);
    }
    // 2) sort descending
    final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView(
      children:
          days.map((day) {
            final items = grouped[day]!;
            final inSum = items
                .where((e) => e.amount > 0)
                .fold(0, (s, e) => s + e.amount);
            final outSum = items
                .where((e) => e.amount < 0)
                .fold(0, (s, e) => s + e.amount.abs());

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TransactionGroupHeader(date: day, inSum: inSum, outSum: outSum),
                ...items.map(
                  (t) => Slidable(
                    key: ValueKey(t.id),
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (_) {
                            context.push('/transaction/edit', extra: t).then((
                              ok,
                            ) {
                              if (ok == true)
                                ref.invalidate(allTransactionsProvider);
                            });
                          },
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          icon: Icons.edit,
                          label: '수정',
                        ),
                        SlidableAction(
                          onPressed: (_) async {
                            await TransactionService.deleteTransaction(t.id);
                            ref.invalidate(allTransactionsProvider);
                          },
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: '삭제',
                        ),
                      ],
                    ),
                    child: TransactionTile(
                      transaction: t,
                      selectMode: _selectMode,
                      selected: _selectedIds.contains(t.id),
                      onCheckboxChanged: (_) => _toggle(t.id),
                      onTap:
                          _selectMode
                              ? () => _toggle(t.id)
                              : () =>
                                  context.push('/transaction/detail', extra: t),
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

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    // 1) 모든 거래 가져와서 날짜별로 맵핑
    final txs = ref.watch(filteredTransactionsProvider);
    final Map<DateTime, List<Transaction>> events = {};
    for (var t in txs) {
      final day = _normalize(t.transactionDate);
      events.putIfAbsent(day, () => []).add(t);
    }

    // 2) 선택된 날짜와, 해당 날짜의 거래 리스트
    final selectedDay = _selected != null ? _normalize(_selected!) : null;
    final dayEvents =
        selectedDay != null ? (events[selectedDay] ?? []) : <Transaction>[];

    // 3) 해당 날짜 수입/지출 합계 계산 함수
    int sumIn = dayEvents
        .where((e) => e.amount > 0)
        .fold(0, (s, e) => s + e.amount);
    int sumOut = dayEvents
        .where((e) => e.amount < 0)
        .fold(0, (s, e) => s + e.amount.abs());

    return Column(
      children: [
        // ── 캘린더 위젯
        TableCalendar<Transaction>(
          firstDay: DateTime(2000),
          lastDay: DateTime(2100),
          focusedDay: _focused,
          selectedDayPredicate: (d) => _normalize(d) == selectedDay,
          eventLoader: (d) => events[_normalize(d)] ?? [],
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
            // 기본 점(marker) 숨기기
            markersMaxCount: 0,
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (ctx, day, _) {
              final d = _normalize(day);
              final msgs = events[d] ?? [];
              final inSum = msgs
                  .where((e) => e.amount > 0)
                  .fold(0, (s, e) => s + e.amount);
              final outSum = msgs
                  .where((e) => e.amount < 0)
                  .fold(0, (s, e) => s + e.amount.abs());
              return FittedBox(
                child: Container(
                  margin: const EdgeInsets.all(4),
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 2,
                  ),
                  decoration:
                      d == selectedDay
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
                          '+${NumberFormat.compact().format(inSum)}',
                          style: kBodyText.copyWith(
                            fontSize: 10,
                            color: kSuccess,
                          ),
                        ),
                      if (outSum > 0)
                        Text(
                          '-${NumberFormat.compact().format(outSum)}',
                          style: kBodyText.copyWith(
                            fontSize: 10,
                            color: kError,
                          ),
                        ),
                    ],
                  ),
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

        // ── 선택된 날짜가 있을 때
        if (selectedDay != null) ...[
          const SizedBox(height: 8),

          // 4) 날짜 및 합계 요약
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${selectedDay.month}월 ${selectedDay.day}일 (${DateFormat.E('ko').format(selectedDay)})',
                  style: kBodyText.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '+${NumberFormat('#,###').format(sumIn)}원',
                  style: kBodyText.copyWith(color: kSuccess, fontSize: 14),
                ),
                const SizedBox(width: 12),
                Text(
                  '-${NumberFormat('#,###').format(sumOut)}원',
                  style: kBodyText.copyWith(color: kError, fontSize: 14),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 5) 거래 리스트 (없으면 안내문)
          if (dayEvents.isEmpty)
            const Expanded(
              child: Center(child: Text('등록된 거래가 없습니다', style: kBodyText)),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: dayEvents.length,
                itemBuilder: (ctx, i) {
                  final t = dayEvents[i];
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
                        t.category,
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
                          '/transaction/detail',
                          extra: t,
                        );
                        if (res == true)
                          ref.invalidate(allTransactionsProvider);
                      },
                    ),
                  );
                },
              ),
            ),
        ]
        // ── 날짜 미선택 시
        else ...[
          const SizedBox(height: 24),
          const Center(child: Text('날짜를 선택해 보세요.', style: kBodyText)),
        ],
      ],
    );
  }
}
