// lib/screens/transaction/add_transaction_page.dart

import 'package:doitmoney_flutter/services/account_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/transaction_service.dart';
import '../../providers/transaction_providers.dart';

/// 기존 TransactionService.transactionType 과 동일한 enum 사용
// enum TransactionType { income, expense, transfer } // 지우고

class AddTransactionPage extends ConsumerStatefulWidget {
  /// 기존 거래가 넘어오면 '수정' 모드, 아니면 '추가' 모드
  final Transaction? existing;
  const AddTransactionPage({Key? key, this.existing}) : super(key: key);

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  late TransactionType _transactionType;
  late DateTime _selectedDateTime;
  Account? _selectedAccountObj;
  String _category = '기타';

  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  final List<String> _categories = ['식비', '교통/차량', '문화생활', '쇼핑', '기타'];

  @override
  void initState() {
    super.initState();
    final tx = widget.existing;
    _transactionType = tx?.transactionType ?? TransactionType.expense;
    _tabController =
        TabController(length: 2, vsync: this)
          ..index = (_transactionType == TransactionType.income ? 0 : 1)
          ..addListener(() {
            setState(() {
              _transactionType =
                  (_tabController.index == 0)
                      ? TransactionType.income
                      : TransactionType.expense;
            });
          });
    _selectedDateTime = tx?.transactionDate ?? DateTime.now();
    // 편집 모드라도 여기서는 나중에 drop-down 목록에서 골라주도록,
    // 초기에는 null 로 두겠습니다.
    _selectedAccountObj = null;
    _category = tx?.category ?? '기타';
    _descriptionController.text = tx?.description ?? '';
    _amountController.text = tx != null ? tx.amount.abs().toString() : '';
    _memoController.text = ''; // 만약 tx.memo 필드 있으면 그걸로

    // 수정 모드라면 탭 위치도 맞춰주기
    if (tx != null) {
      _tabController.index =
          tx.transactionType == TransactionType.income ? 0 : 1;
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

  bool get _canSave {
    return _descriptionController.text.isNotEmpty &&
        _amountController.text.isNotEmpty &&
        _selectedAccountObj != null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final parsed = int.parse(_amountController.text.replaceAll(',', ''));
    final signedAmt =
        _transactionType == TransactionType.expense ? -parsed : parsed;

    final newTx = Transaction(
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
      await TransactionService.addTransaction(newTx);
    } else {
      await TransactionService.updateTransaction(newTx.id, newTx);
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
              // 설명
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
                  if (int.tryParse(v.replaceAll(',', '')) == null)
                    return '숫자만 입력';
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
                  // 기존 거래 편집 시 초기값 매칭
                  final initial =
                      _selectedAccountObj ??
                      (widget.existing != null
                          ? list.firstWhere(
                            (a) =>
                                a.institutionName ==
                                widget.existing!.accountName,
                            orElse: () => list.first,
                          )
                          : null);

                  return DropdownButtonFormField<Account>(
                    decoration: const InputDecoration(labelText: '계좌 선택'),
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
                    value: initial,
                    onChanged: (v) => setState(() => _selectedAccountObj = v),
                    validator: (v) => v == null ? '선택하세요' : null,
                  );
                }, // ← data 핸들러 끝나면 반드시 “},” 를 찍어야 함
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('오류: $e'),
              ),

              const SizedBox(height: 16),
              // 카테고리, 저장 버튼 등 나머지…

              // 카테고리
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: '카테고리'),
                items:
                    _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                value: _category,
                onChanged: (v) => setState(() => _category = v!),
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
