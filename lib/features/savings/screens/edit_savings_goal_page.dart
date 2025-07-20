import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/common_button.dart';
import '../../account/providers/accounts_provider.dart';
import '../models/savings_goal.dart';
import '../services/savings_service.dart';

class EditSavingsGoalPage extends ConsumerStatefulWidget {
  final SavingsGoal goal;
  const EditSavingsGoalPage({Key? key, required this.goal}) : super(key: key);
  @override
  ConsumerState<EditSavingsGoalPage> createState() =>
      _EditSavingsGoalPageState();
}

class _EditSavingsGoalPageState extends ConsumerState<EditSavingsGoalPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtl;
  late final TextEditingController _amountCtl;
  int? _accountId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _titleCtl = TextEditingController(text: widget.goal.title);
    _amountCtl = TextEditingController(
      text: widget.goal.targetAmount.toString(),
    );
    _accountId = widget.goal.targetAccountId;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await SavingsService.updateGoal(
        id: widget.goal.id,
        title: _titleCtl.text.trim(),
        targetAmount: int.parse(_amountCtl.text.replaceAll(',', '')),
        targetAccountId: _accountId!,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('수정 실패: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('저축 목표 수정')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleCtl,
                decoration: const InputDecoration(labelText: '목표 제목'),
                validator: (v) => v?.isEmpty == true ? '제목 입력' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountCtl,
                decoration: const InputDecoration(
                  labelText: '목표 금액',
                  suffixText: '원',
                ),
                keyboardType: TextInputType.number,
                validator:
                    (v) =>
                        v == null || int.tryParse(v.replaceAll(',', '')) == null
                            ? '금액 입력'
                            : null,
              ),
              const SizedBox(height: 16),
              accountsAsync.when(
                data:
                    (list) => DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: '저축 계좌 선택'),
                      value: _accountId,
                      items:
                          list
                              .map(
                                (a) => DropdownMenuItem(
                                  value: a.id,
                                  child: Text(
                                    '${a.institutionName} ${a.accountNumber}',
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => _accountId = v),
                      validator: (_) => _accountId == null ? '선택 필수' : null,
                    ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('계좌 로드 실패: $e'),
              ),
              const SizedBox(height: 32),
              CommonElevatedButton(
                text: '수정하기',
                onPressed: _loading ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
