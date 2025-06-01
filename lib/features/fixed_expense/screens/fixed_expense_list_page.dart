// lib/screens/fixed_expense/fixed_expense_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/fixed_expense_service.dart';
import '../providers/fixed_expense_provider.dart';
import 'add_fixed_expense_page.dart';

class FixedExpenseListPage extends ConsumerWidget {
  const FixedExpenseListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(fixedExpensesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('고정 지출 목록')),
      body: async.when(
        data: (list) {
          final total = list.fold<int>(0, (s, fe) => s + fe.amount);
          if (list.isEmpty) {
            return const Center(child: Text('등록된 고정 지출이 없습니다.'));
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '매월 총 지출: ${total.toString()}원',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 23,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final fe = list[i];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                                // ignore: deprecated_member_use
                              ).primaryColor.withOpacity(0.1),
                              child: Text('${fe.dayOfMonth}'),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                fe.category,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            Text(
                              '${fe.amount}원',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final ok = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => AddFixedExpensePage(editing: fe),
                                  ),
                                );
                                if (ok == true) {
                                  // ignore: unused_result
                                  ref.refresh(fixedExpensesProvider);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await FixedExpenseService.deleteFixedExpense(
                                  fe.id,
                                );
                                // ignore: unused_result
                                ref.refresh(fixedExpensesProvider);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ok = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddFixedExpensePage()),
          );
          // ignore: unused_result
          if (ok == true) ref.refresh(fixedExpensesProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
