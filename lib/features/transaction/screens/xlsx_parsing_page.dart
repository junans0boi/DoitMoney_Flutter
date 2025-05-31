// lib/screens/transaction/xlsx_parsing_page.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:doitmoney_flutter/services/account_service.dart'
    show Account, AccountService;
import 'package:doitmoney_flutter/services/transaction_service.dart'
    show Transaction, TransactionService, TransactionType;
import 'package:doitmoney_flutter/widgets/common/loading_progress_dialog.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../constants/colors.dart';
import 'package:go_router/go_router.dart';

class XlsxParsingPage extends StatefulWidget {
  final PlatformFile file;
  const XlsxParsingPage({Key? key, required this.file}) : super(key: key);

  @override
  State<XlsxParsingPage> createState() => _XlsxParsingPageState();
}

class _XlsxParsingPageState extends State<XlsxParsingPage> {
  bool _busy = false;
  List<List<String>> _raw = [];
  List<Transaction> _txs = [];
  List<Account> _accounts = [];
  Account? _selectedAccount;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    _accounts = await AccountService.fetchAccounts();
    setState(() {});
  }

  Future<void> _decryptAndParse() async {
    final pwd = await _askPwd();
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

  Future<String?> _askPwd() {
    final ctrl = TextEditingController();
    return showDialog<String>(
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
  }

  List<Transaction> _toTransactions(List<List<String>> rows) {
    final fmt = DateFormat('yyyy.MM.dd HH:mm:ss');
    final out = <Transaction>[];
    for (final r in rows) {
      if (r.length < 3) continue;
      try {
        final dt = fmt.parse(r[0]);
        final amt = int.parse(r[2].replaceAll(',', ''));
        final type =
            r[1] == '출금' ? TransactionType.expense : TransactionType.income;
        out.add(
          Transaction(
            id: 0,
            transactionDate: dt,
            transactionType: type,
            category: '',
            amount: type == TransactionType.expense ? -amt : amt,
            description: r.length > 5 ? r[5] : '',
            accountName: '',
            accountNumber: '',
          ),
        );
      } catch (_) {}
    }
    return out;
  }

  Future<void> _upload() async {
    if (_txs.isEmpty || _selectedAccount == null) return;
    final total = _txs.length;
    final progress = ValueNotifier<double>(0);

    LoadingProgressDialog.show(
      context,
      title:
          '거래 내역을 ${_selectedAccount!.institutionName}(${_selectedAccount!.accountNumber.substring(_selectedAccount!.accountNumber.length - 4)}) 계좌로 업로드 하고 있어요!',
      progress: progress,
    );

    for (var i = 0; i < total; i++) {
      final t = _txs[i].copyWith(
        accountName: _selectedAccount!.institutionName,
        accountNumber: _selectedAccount!.accountNumber,
      );
      try {
        await TransactionService.addTransaction(t);
      } catch (_) {}
      progress.value = (i + 1) / total;
    }

    Navigator.of(context, rootNavigator: true).pop();
    progress.dispose();
    if (!mounted) return;
    context.go(
      '/upload-complete',
      extra: {'account': _selectedAccount!, 'count': total},
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
              FilledButton.icon(
                onPressed: _busy ? null : _decryptAndParse,
                icon: const Icon(Icons.lock_open),
                label: const Text('복호화 & 파싱'),
                style: FilledButton.styleFrom(backgroundColor: kPrimaryColor),
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
              FilledButton.icon(
                onPressed:
                    (_txs.isEmpty || _selectedAccount == null) ? null : _upload,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('등록'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewTable() {
    if (_txs.isEmpty) return const Center(child: Text('파싱된 거래 없음'));

    final hdrs = const [
      DataColumn(label: Text('날짜')),
      DataColumn(label: Text('유형')),
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
