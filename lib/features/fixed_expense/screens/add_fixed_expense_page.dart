// lib/screens/fixed_expense/add_fixed_expense_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/fixed_expense_service.dart';
import '../../account/services/account_service.dart';
import '../../transaction/providers/transaction_provider.dart'; // <-- provides accountsProvider

class AddFixedExpensePage extends ConsumerStatefulWidget {
  final FixedExpense? editing;
  const AddFixedExpensePage({super.key, this.editing});

  @override
  ConsumerState<AddFixedExpensePage> createState() =>
      _AddFixedExpensePageState();
}

class _AddFixedExpensePageState extends ConsumerState<AddFixedExpensePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _contentCtrl;
  int _day = 1;
  TransactionType _type = TransactionType.expense;
  int? _fromAccountId;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _amountCtrl = TextEditingController(text: e?.amount.toString() ?? '');
    _categoryCtrl = TextEditingController(text: e?.category ?? '');
    _contentCtrl = TextEditingController(text: e?.content ?? '');
    _day = e?.dayOfMonth ?? 1;
    _type = e?.transactionType ?? TransactionType.expense;
    _fromAccountId = e?.fromAccountId;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _categoryCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final fe = FixedExpense(
      id: widget.editing?.id ?? 0,
      amount: int.parse(_amountCtrl.text),
      category: _categoryCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      dayOfMonth: _day,
      transactionType: _type,
      fromAccountId: _fromAccountId!,
    );

    try {
      if (widget.editing != null) {
        await FixedExpenseService.updateFixedExpense(fe);
      } else {
        await FixedExpenseService.addFixedExpense(fe);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      // 실패 시 사용자에게 알려줍니다.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('고정 지출 저장에 실패했습니다:\n$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editing != null ? '고정 지출 수정' : '고정 지출 추가'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ▶ 계좌 선택 ▶
              accountsAsync.when(
                data: (list) {
                  // 선택 중인 계좌가 없으면 무조건 첫 번째로
                  final initial = list.firstWhere(
                    (a) => a.id == _fromAccountId,
                    orElse: () => list.first,
                  );
                  return DropdownButtonFormField<Account>(
                    decoration: const InputDecoration(labelText: '출금 계좌'),
                    value: initial,
                    items:
                        list.map((a) {
                          return DropdownMenuItem(
                            value: a,
                            child: Text(a.institutionName),
                          );
                        }).toList(),
                    onChanged:
                        (a) => setState(() {
                          _fromAccountId = a?.id;
                        }),
                    validator: (v) => v == null ? '계좌를 선택해주세요' : null,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (e, _) => Center(
                      child: Text(
                        '계좌 정보를 불러오는 중 오류가 발생했습니다.\n$e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
              ),

              const SizedBox(height: 16),

              // 카테고리
              TextFormField(
                controller: _categoryCtrl,
                decoration: const InputDecoration(labelText: '카테고리'),
                validator: (v) => (v == null || v.isEmpty) ? '필수 입력' : null,
              ),

              const SizedBox(height: 16),

              // 금액
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: '금액',
                  suffixText: '원',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? '필수 입력' : null,
              ),

              const SizedBox(height: 16),

              // 일자
              ListTile(
                title: const Text('매월 일자'),
                trailing: DropdownButton<int>(
                  value: _day,
                  items:
                      List.generate(31, (i) => i + 1)
                          .map(
                            (d) =>
                                DropdownMenuItem(value: d, child: Text('$d일')),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _day = v!),
                ),
              ),

              // 유형
              ListTile(
                title: const Text('유형'),
                trailing: DropdownButton<TransactionType>(
                  value: _type,
                  items:
                      TransactionType.values
                          .map(
                            (e) =>
                                DropdownMenuItem(value: e, child: Text(e.name)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _type = v!),
                ),
              ),

              const SizedBox(height: 16),

              // 메모
              TextFormField(
                controller: _contentCtrl,
                decoration: const InputDecoration(labelText: '메모'),
              ),

              const SizedBox(height: 24),

              // 저장
              ElevatedButton(onPressed: _save, child: const Text('저장')),
            ],
          ),
        ),
      ),
    );
  }
}
