import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/common_list_item.dart';
import '../../../shared/widgets/currency_text.dart';
import '../models/savings_goal.dart';
import '../services/savings_service.dart';
import 'edit_savings_goal_page.dart';

class SavingsDetailPage extends ConsumerWidget {
  final SavingsGoal goal;
  const SavingsDetailPage({super.key, required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> onDelete() async {
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
      await SavingsService.deleteGoal(goal.id);
      if (!context.mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('저축 목표가 삭제되었습니다')));
    }

    Future<void> onEdit() async {
      final updated = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => EditSavingsGoalPage(goal: goal)),
      );
      if (updated == true && context.mounted) {
        Navigator.of(context).pop(true);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('저축 목표 상세'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
          IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Flutter 3 / Material 3 에서는 headline6 대신 titleLarge 사용
          Text(goal.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          CurrencyText(
            amount: goal.savedAmount.toDouble(),
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 32),
          CommonListItem(
            label: '목표 금액',
            value: '${NumberFormat('#,###').format(goal.targetAmount)}원',
            showArrow: false,
          ),
          const Divider(height: 1),
          CommonListItem(
            label: '적립액',
            value: '${NumberFormat('#,###').format(goal.savedAmount)}원',
            showArrow: false,
          ),
          const Divider(height: 1),
          CommonListItem(
            label: '진행률',
            value: '${(goal.progress * 100).round()}%',
            showArrow: false,
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
