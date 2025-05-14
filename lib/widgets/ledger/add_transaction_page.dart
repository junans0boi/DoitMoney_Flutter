// DoitMoney_Flutter/lib/widgets/ledger/add_transaction_page.dart
import 'package:doitmoney_flutter/screens/transaction/transaction_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/transaction_service.dart';

enum TransactionType { income, expense }

class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({Key? key}) : super(key: key);
  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  TransactionType _transactionType = TransactionType.expense;
  DateTime _selectedDateTime = DateTime.now();
  bool _monthly = false;
  String? _selectedAccount;
  String _category = '기타';

  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();

  final List<String> _categories = ['식비', '교통/차량', '문화생활', '쇼핑', '기타'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _transactionType =
            _tabController.index == 0
                ? TransactionType.income
                : TransactionType.expense;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time == null) return;
    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  bool get _canSave {
    return (_descriptionController.text.isNotEmpty &&
        _amountController.text.isNotEmpty &&
        _selectedAccount != null);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedAmount =
        int.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;

    final transaction = Transaction(
      id: 0,
      transactionDate: _selectedDateTime,
      amount:
          _transactionType == TransactionType.expense
              ? -parsedAmount
              : parsedAmount,
      description: _descriptionController.text.trim(),
      accountName: _selectedAccount!,
    );

    await TransactionService.addTransaction(transaction);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final accountName = _selectedAccount ?? '거래';

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: Text('$accountName 직접 입력'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: '수입'), Tab(text: '지출')],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '지출명',
                  hintText: '지출명을 입력해 주세요',
                ),
                validator: (v) => v == null || v.isEmpty ? '필수 입력' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: '지출 금액',
                  hintText: '지출금액을 입력해 주세요',
                  suffixText: '원',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return '필수 입력';
                  if (int.tryParse(v.replaceAll(',', '')) == null)
                    return '숫자만 입력';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('지출일시'),
                subtitle: Text(
                  DateFormat(
                    'yyyy. M. d. a h:mm',
                    'ko',
                  ).format(_selectedDateTime),
                ),
                onTap: _pickDateTime,
              ),
              const Divider(),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('매월 지출로 등록'),
                value: _monthly,
                onChanged: (v) => setState(() => _monthly = v),
              ),
              const Divider(),

              accountsAsync.when(
                data:
                    (list) => DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: '지출 수단'),
                      items:
                          list
                              .map(
                                (a) => DropdownMenuItem(
                                  value: a.institutionName,
                                  child: Text(a.institutionName),
                                ),
                              )
                              .toList(),
                      value: _selectedAccount,
                      onChanged: (v) => setState(() => _selectedAccount = v),
                      validator: (v) => v == null ? '선택하세요' : null,
                    ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('오류: $e'),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: '지출 카테고리'),
                items:
                    _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                value: _category,
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _memoController,
                decoration: const InputDecoration(
                  labelText: '지출 메모',
                  hintText: '메모를 입력해주세요',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _canSave ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: const Text('저장하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
