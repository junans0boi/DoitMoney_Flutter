import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../constants/colors.dart';
import '../../../shared/widgets/common_button.dart';
import '../../../shared/widgets/currency_text.dart';
import '../models/savings_goal.dart';
import '../services/savings_service.dart';
import 'add_savings_goal_page.dart';
import 'edit_savings_goal_page.dart';
import 'savings_detail_page.dart';

class SavingsPage extends ConsumerStatefulWidget {
  const SavingsPage({Key? key}) : super(key: key);
  @override
  ConsumerState<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends ConsumerState<SavingsPage> {
  late Future<List<SavingsGoal>> _futureGoals;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  void _loadGoals() {
    _futureGoals = SavingsService.fetchGoals();
  }

  Future<void> _refresh() async {
    setState(_loadGoals);
    await _futureGoals;
  }

  Future<void> _onAdd() async {
    final added = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AddSavingsGoalPage()));
    if (added == true) _refresh();
  }

  Future<void> _onEdit(SavingsGoal g) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditSavingsGoalPage(goal: g)),
    );
    if (updated == true) _refresh();
  }

  Future<void> _onDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('삭제 확인'),
            content: const Text('이 목표를 정말 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('삭제'),
              ),
            ],
          ),
    );
    if (confirm != true) return;
    await SavingsService.deleteGoal(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('저축 목표가 삭제되었습니다')));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: FutureBuilder<List<SavingsGoal>>(
          future: _futureGoals,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('오류: ${snap.error}'));
            }
            final goals = snap.data ?? [];
            if (goals.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/empty_savings.png',
                        width: 200,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '등록된 저축 목표가 없어요',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 32),
                      CommonElevatedButton(
                        text: '새 목표 추가하기',
                        onPressed: _onAdd,
                      ),
                    ],
                  ),
                ),
              );
            }

            final totalSaved = goals.fold<int>(0, (s, g) => s + g.savedAmount);
            final totalTarget = goals.fold<int>(
              0,
              (s, g) => s + g.targetAmount,
            );

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  // Summary Card
                  Container(
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '총 적립액',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        CurrencyText(
                          amount: totalSaved.toDouble(),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '총 목표액',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        CurrencyText(
                          amount: totalTarget.toDouble(),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Goals List
                  ...goals.map(
                    (g) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Slidable(
                        key: ValueKey(g.id),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) => _onEdit(g),
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              icon: Icons.edit,
                              label: '수정',
                            ),
                            SlidableAction(
                              onPressed: (_) => _onDelete(g.id),
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              label: '삭제',
                            ),
                          ],
                        ),
                        child: ListTile(
                          tileColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          onTap: () async {
                            final changed = await Navigator.of(
                              context,
                            ).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => SavingsDetailPage(goal: g),
                              ),
                            );
                            if (changed == true) _refresh();
                          },
                          title: Text(
                            g.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: g.progress,
                                minHeight: 6,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(g.progress * 100).round()}% (${g.savedAmount}원 / ${g.targetAmount}원)',
                              ),
                            ],
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.black38,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Add Button
                  CommonElevatedButton(text: '새 목표 추가', onPressed: _onAdd),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
