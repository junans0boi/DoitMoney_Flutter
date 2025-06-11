// lib/features/transaction/screens/xlsx_parsing_page.dart (리팩터 후)

// ignore_for_file: unused_import, use_super_parameters, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/loading_progress_dialog.dart';
import 'package:doitmoney_flutter/features/transaction/services/transaction_service.dart'
    show Transaction, TransactionService, TransactionType;
import '../../../shared/widgets/common_input.dart';
import '../../../shared/widgets/common_button.dart';
import '../../../constants/colors.dart';
import '../../account/services/account_service.dart'
    show Account, AccountService;
import '../utils/category_mapper.dart';
import '../screens/upload_complete_page.dart';

class XlsxParsingPage extends StatefulWidget {
  final PlatformFile file;
  const XlsxParsingPage({Key? key, required this.file}) : super(key: key);

  @override
  State<XlsxParsingPage> createState() => _XlsxParsingPageState();
}

class _XlsxParsingPageState extends State<XlsxParsingPage> {
  List<Transaction> _existingTxs = []; // ①

  bool _busy = false;
  List<List<String>> _raw = [];
  List<Transaction> _txs = [];
  List<Account> _accounts = [];
  Account? _selectedAccount;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _loadExisting();
  }

  Future<void> _loadAccounts() async {
    _accounts = await AccountService.fetchAccounts();
    setState(() {});
  }

  Future<void> _loadExisting() async {
    _existingTxs = await TransactionService.fetchTransactions(); // ①
  }

  Future<void> _decryptAndParse() async {
    final ctrl = TextEditingController();
    final pwd = await showDialog<String>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: const Text('엑셀 비밀번호'),
            content: TextField(
              controller: ctrl,
              decoration: const InputDecoration(hintText: '비밀번호 입력'),
              obscureText: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, null),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, ctrl.text),
                child: const Text('확인'),
              ),
            ],
          ),
    );
    if (pwd == null) return;

    setState(() => _busy = true);
    try {
      final rows = await TransactionService.decryptExcel(
        widget.file.bytes!,
        widget.file.name,
        pwd,
      );
      setState(() {
        _raw = rows;
        _txs = _toTransactions(rows);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<Transaction> _toTransactions(List<List<String>> rows) {
    final fmt = DateFormat('yyyy.MM.dd HH:mm:ss');
    final out = <Transaction>[];

    for (final r in rows) {
      if (r.length < 3) continue; // 최소한 셀 세 개는 있어야 함

      // 만약 첫 번째 셀(r[0])이 비어 있으면 실제 데이터는 한 칸씩 뒤에 존재한다.
      final offset = (r[0].trim().isEmpty && r.length > 5) ? 1 : 0;

      try {
        final dateString = r[offset + 0]; // 거래일시
        final typeString = r[offset + 1]; // '입금' or '출금'
        final amtString = r[offset + 2]; // 거래금액 (쉼표 포함)
        final description = (r.length > offset + 5) ? r[offset + 5] : '';

        final dt = fmt.parse(dateString);
        final amt = int.parse(amtString.replaceAll(',', ''));
        final type =
            (typeString == '출금')
                ? TransactionType.expense
                : TransactionType.income;

        // description 또는 rawCategory가 필요하다면, 여기서 description을 사용하거나 mapCategory(description)
        final mappedCategory = mapCategory(description);

        out.add(
          Transaction(
            id: 0,
            transactionDate: dt,
            transactionType: type,
            category: mappedCategory,
            amount: (type == TransactionType.expense) ? -amt : amt,
            description: description,
            accountName: '',
            accountNumber: '',
          ),
        );
      } catch (_) {
        // 파싱 오류가 나는 행은 무시
      }
    }

    return out;
  }

  Future<void> _parseFile() async {
    if (_txs.isEmpty || _selectedAccount == null) return;

    // ② 중복 체크
    final toUpload = <Transaction>[];
    for (final t in _txs) {
      final isDup = _existingTxs.any((e) {
        final sameDate =
            e.transactionDate.year == t.transactionDate.year &&
            e.transactionDate.month == t.transactionDate.month &&
            e.transactionDate.day == t.transactionDate.day;
        return sameDate &&
            e.amount == t.amount &&
            e.description == t.description &&
            e.category == t.category;
      });
      if (!isDup) toUpload.add(t);
    }
    final dupCount = _txs.length - toUpload.length;

    if (toUpload.isNotEmpty) {
      final progress = ValueNotifier<double>(0);
      LoadingProgressDialog.show(
        context,
        title:
            '거래 내역을 ${_selectedAccount!.institutionName}…${_selectedAccount!.accountNumber.substring(_selectedAccount!.accountNumber.length - 4)} 계좌로 업로드 중',
        progress: progress,
      );
      for (var i = 0; i < toUpload.length; i++) {
        final t = toUpload[i].copyWith(
          accountName: _selectedAccount!.institutionName,
          accountNumber: _selectedAccount!.accountNumber,
        );
        await TransactionService.addTransaction(t).catchError((_) {});
        progress.value = (i + 1) / toUpload.length;
      }
      Navigator.of(context, rootNavigator: true).pop();
      progress.dispose();
    }

    if (!mounted) return;
    context.go(
      '/upload-complete',
      extra: {
        'account': _selectedAccount!,
        'uploadedCount': toUpload.length,
        'duplicateCount': dupCount,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('XLSX 미리보기')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DropdownButtonFormField<Account>(
                decoration: const InputDecoration(labelText: '계좌 선택'),
                items:
                    _accounts.map((a) {
                      final last4 =
                          a.accountNumber.length >= 4
                              ? a.accountNumber.substring(
                                a.accountNumber.length - 4,
                              )
                              : a.accountNumber;
                      return DropdownMenuItem(
                        value: a,
                        child: Text('${a.institutionName} (…$last4)'),
                      );
                    }).toList(),
                value: _selectedAccount,
                hint: const Text('계좌 선택'),
                onChanged: (v) => setState(() => _selectedAccount = v),
              ),
              const SizedBox(height: 12),
              CommonElevatedButton(
                text: '복호화 & 파싱',
                enabled: !_busy,
                onPressed: _decryptAndParse,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: kPrimaryColor,
                        tabs: const [Tab(text: '원본'), Tab(text: '미리보기')],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            SingleChildScrollView(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                _raw.map((r) => r.join(' | ')).join('\n'),
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                            ),
                            _buildPreviewTable(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              CommonElevatedButton(
                text: '등록',
                enabled: (_txs.isNotEmpty && _selectedAccount != null),
                onPressed: _parseFile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewTable() {
    if (_txs.isEmpty) return const Center(child: Text('파싱된 거래 없음'));

    // ① 컬럼 목록에 '카테고리' 추가
    final hdrs = const [
      DataColumn(label: Text('날짜')),
      DataColumn(label: Text('유형')),
      DataColumn(label: Text('카테고리')), // 추가된 부분
      DataColumn(label: Text('금액')),
      DataColumn(label: Text('내용')),
    ];

    final rows =
        _txs.map((t) {
          final date = DateFormat('MM/dd').format(t.transactionDate);
          final type =
              t.transactionType == TransactionType.income ? '수입' : '지출';
          final amt = NumberFormat('#,###').format(t.amount.abs());

          return DataRow(
            cells: [
              DataCell(Text(date)),
              DataCell(Text(type)),
              DataCell(Text(t.category)), // 카테고리 셀 추가
              DataCell(Text('$amt원')),
              DataCell(Text(t.description)),
            ],
          );
        }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(columns: hdrs, rows: rows),
    );
  }
}
