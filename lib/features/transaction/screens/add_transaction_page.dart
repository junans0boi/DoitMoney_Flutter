// lib/screens/transaction/add_transaction_page.dart
import 'package:doitmoney_flutter/services/account_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/transaction_service.dart' as tx_svc;
import '../../services/fixed_expense_service.dart' as fx_svc;
import '../../providers/transaction_providers.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  final tx_svc.Transaction? existing;
  const AddTransactionPage({super.key, this.existing});

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  late tx_svc.TransactionType _transactionType;
  late DateTime _selectedDateTime;
  Account? _selectedAccountObj;
  String _category = '기타';
  bool _isFixed = false;

  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  final List<String> _categories = [
    '식비',
    '교통/차량',
    '문화생활',
    '쇼핑',
    '기타',
    '카드결제',
    '이체',
  ];

  @override
  void initState() {
    super.initState();
    final tx = widget.existing;
    _transactionType = tx?.transactionType ?? tx_svc.TransactionType.expense;
    _tabController =
        TabController(length: 2, vsync: this)
          ..index = (_transactionType == tx_svc.TransactionType.income ? 0 : 1)
          ..addListener(() {
            setState(() {
              _transactionType =
                  _tabController.index == 0
                      ? tx_svc.TransactionType.income
                      : tx_svc.TransactionType.expense;
            });
          });

    _selectedDateTime = tx?.transactionDate ?? DateTime.now();
    _category = tx?.category ?? '기타';
    _descriptionController.text = tx?.description ?? '';
    _amountController.text = tx != null ? tx.amount.abs().toString() : '';
    _memoController.text = '';

    if (tx != null) {
      _tabController.index =
          tx.transactionType == tx_svc.TransactionType.income ? 0 : 1;
    }
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

  bool get _canSave =>
      _descriptionController.text.isNotEmpty &&
      _amountController.text.isNotEmpty &&
      _selectedAccountObj != null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final parsed = int.parse(_amountController.text.replaceAll(',', ''));
    final signedAmt =
        _transactionType == tx_svc.TransactionType.expense ? -parsed : parsed;

    final newTx = tx_svc.Transaction(
      id: widget.existing?.id ?? 0,
      transactionDate: _selectedDateTime,
      transactionType: _transactionType,
      category: _category,
      amount: signedAmt,
      description: _descriptionController.text.trim(),
      accountName: _selectedAccountObj!.institutionName,
      accountNumber: _selectedAccountObj!.accountNumber,
    );

    if (widget.existing == null) {
      await tx_svc.TransactionService.addTransaction(newTx);
    } else {
      await tx_svc.TransactionService.updateTransaction(newTx.id, newTx);
    }

    if (_isFixed && _transactionType == tx_svc.TransactionType.expense) {
      final fe = fx_svc.FixedExpense(
        id: 0,
        amount: parsed,
        category: _category,
        content: _descriptionController.text.trim(),
        dayOfMonth: _selectedDateTime.day,
        transactionType: fx_svc.TransactionType.expense,
        fromAccountId: _selectedAccountObj!.id,
      );
      try {
        await fx_svc.FixedExpenseService.addFixedExpense(fe);
      } catch (e) {
        // parsing or server error—log but don’t block the pop
        debugPrint('fixed-expense registration failed: $e');
      }
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(widget.existing == null ? '거래 추가' : '거래 수정'),
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
              // 거래명
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: '거래명'),
                validator: (v) => (v == null || v.isEmpty) ? '필수 입력' : null,
              ),
              const SizedBox(height: 16),

              // 금액
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: '금액',
                  suffixText: '원',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return '필수 입력';
                  if (int.tryParse(v.replaceAll(',', '')) == null) {
                    return '숫자만 입력';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 일시
              ListTile(
                title: const Text('거래 일시'),
                subtitle: Text(
                  DateFormat(
                    'yyyy. M. d. a h:mm',
                    'ko',
                  ).format(_selectedDateTime),
                ),
                onTap: _pickDateTime,
              ),
              const Divider(),

              // 계좌
              accountsAsync.when(
                data: (list) {
                  // 편집 모드 시, 처음 빌드될 때 기존 거래의 계좌를 찾아 선택
                  if (_selectedAccountObj == null && widget.existing != null) {
                    final ex = widget.existing!;
                    _selectedAccountObj = list.firstWhere(
                      (a) =>
                          a.institutionName == ex.accountName &&
                          a.accountNumber == ex.accountNumber,
                      orElse: () => list.first,
                    );
                  }

                  return DropdownButtonFormField<Account>(
                    decoration: const InputDecoration(labelText: '계좌 선택'),
                    hint: const Text('계좌 선택'),
                    items:
                        list.map((a) {
                          final last4 =
                              a.accountNumber.length >= 4
                                  ? a.accountNumber.substring(
                                    a.accountNumber.length - 4,
                                  )
                                  : a.accountNumber;
                          return DropdownMenuItem(
                            value: a,
                            child: Text('${a.institutionName} ($last4)'),
                          );
                        }).toList(),
                    value: _selectedAccountObj,
                    onChanged: (v) => setState(() => _selectedAccountObj = v),
                    validator: (v) => v == null ? '선택하세요' : null,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('오류: $e'),
              ),
              const SizedBox(height: 16),

              // 카테고리
              Builder(
                builder: (_) {
                  final currentCategory = _category;
                  final categoryItems = List<String>.from(_categories);
                  // 편집 모드에서 _categories 에 없는 값이 있을 경우 맨 앞에 추가
                  if (!categoryItems.contains(currentCategory)) {
                    categoryItems.insert(0, currentCategory);
                  }
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: '카테고리'),
                    items:
                        categoryItems
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                    value: currentCategory,
                    onChanged: (v) => setState(() => _category = v!),
                  );
                },
              ),
              const SizedBox(height: 16),

              // 메모
              TextFormField(
                controller: _memoController,
                decoration: const InputDecoration(labelText: '메모'),
              ),
              const SizedBox(height: 16),

              // 매월 지출 등록
              SwitchListTile(
                title: const Text('매월 지출 등록'),
                value: _isFixed,
                onChanged: (v) => setState(() => _isFixed = v),
              ),
              const SizedBox(height: 32),

              // 저장
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _canSave ? _save : null,
                  child: Text(widget.existing == null ? '저장하기' : '수정하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
