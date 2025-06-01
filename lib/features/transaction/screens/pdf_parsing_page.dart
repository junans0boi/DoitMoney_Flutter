// lib/features/transaction/screens/pdf_parsing_page.dart (리팩터 후)

// ignore_for_file: unused_import, use_super_parameters, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_pdf_text/flutter_pdf_text.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/loading_progress_dialog.dart';
import '../../account/services/account_service.dart'
    show Account, AccountService;
import '../services/transaction_service.dart'
    show Transaction, TransactionService, TransactionType;
import '../../../shared/widgets/common_input.dart';
import '../../../shared/widgets/common_button.dart';

class PdfParsingPage extends StatefulWidget {
  final String path;
  const PdfParsingPage({Key? key, required this.path}) : super(key: key);

  @override
  State<PdfParsingPage> createState() => _PdfParsingPageState();
}

class _PdfParsingPageState extends State<PdfParsingPage> {
  final TextEditingController _pwController = TextEditingController();
  bool _loading = true;
  String _raw = '';
  List<Transaction> _txs = [];
  List<Account> _accounts = [];
  Account? _selectedAccount;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _accounts = await AccountService.fetchAccounts();
    await _parsePdf();
  }

  Future<void> _parsePdf() async {
    try {
      final text = await _loadPdfText(widget.path);
      final list = _extractTransactions(text);
      setState(() {
        _raw = text;
        _txs = list;
      });
    } catch (e) {
      setState(() => _raw = 'ERROR: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<String> _loadPdfText(String path) async {
    String? pwd;
    while (true) {
      try {
        final doc =
            (pwd == null)
                ? await PDFDoc.fromPath(path)
                : await PDFDoc.fromPath(path, password: pwd);
        return doc.text;
      } catch (e) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('password') || msg.contains('encrypted')) {
          final input = await showDialog<String>(
            context: context,
            builder:
                (c) => AlertDialog(
                  title: const Text('PDF 비밀번호'),
                  content: TextField(
                    controller: _pwController,
                    decoration: const InputDecoration(hintText: '비밀번호 입력'),
                    obscureText: true,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c, null),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(c, _pwController.text),
                      child: const Text('확인'),
                    ),
                  ],
                ),
          );
          if (input == null) throw 'PDF 비밀번호 입력 취소';
          pwd = input;
        } else {
          rethrow;
        }
      }
    }
  }

  List<Transaction> _extractTransactions(String raw) {
    final list = <Transaction>[];
    final chunks = raw.split(
      RegExp(r'(?=^20\d{6}\s+\d{2}:\d{2}:\d{2})', multiLine: true),
    );
    final rowRegex = RegExp(
      r'^(20\d{6})\s+(\d{2}:\d{2}:\d{2})\s+(.+?)\s+([\d,]+)\s+([\d,]+)\s+(.+?)\s+([\d,]+)\s+.+$',
    );

    for (final chunk in chunks) {
      final line = chunk.replaceAll('\n', ' ').trim();
      final m = rowRegex.firstMatch(line);
      if (m == null) continue;

      final datePart = m.group(1)!; // YYYYMMDD
      final timePart = m.group(2)!; // HH:mm:ss
      final category = m.group(3)!.trim();
      final outStr = m.group(4)!.replaceAll(',', '');
      final inStr = m.group(5)!.replaceAll(',', '');
      final description = m.group(6)!.trim();
      final amount =
          int.parse(outStr) > 0 ? -int.parse(outStr) : int.parse(inStr);
      final type =
          int.parse(outStr) > 0
              ? TransactionType.expense
              : (int.parse(inStr) > 0
                  ? TransactionType.income
                  : TransactionType.transfer);

      final year = int.parse(datePart.substring(0, 4));
      final month = int.parse(datePart.substring(4, 6));
      final day = int.parse(datePart.substring(6, 8));
      final parts = timePart.split(':').map(int.parse).toList();
      final dt = DateTime(year, month, day, parts[0], parts[1], parts[2]);

      list.add(
        Transaction(
          id: 0,
          transactionDate: dt,
          transactionType: type,
          category: category,
          amount: amount,
          description: description,
          accountName: '',
          accountNumber: '',
        ),
      );
    }

    return list;
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
      final t = _txs[i];
      try {
        await TransactionService.addTransaction(
          Transaction(
            id: 0,
            transactionDate: t.transactionDate,
            transactionType: t.transactionType,
            category: t.category,
            amount: t.amount,
            description: t.description,
            accountName: _selectedAccount!.institutionName,
            accountNumber: _selectedAccount!.accountNumber,
          ),
        );
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('PDF 파싱 결과')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 계좌 선택 드롭다운
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
                const SizedBox(height: 16),
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          labelColor: theme.primaryColor,
                          tabs: const [Tab(text: '원본'), Tab(text: '미리보기')],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              SingleChildScrollView(
                                child: Text(
                                  _raw,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              _buildDataTable(),
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
                  onPressed: _upload,
                ),
              ],
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black38,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    if (_txs.isEmpty) return const Center(child: Text('파싱된 거래가 없습니다'));
    final cols = <DataColumn>[
      const DataColumn(label: Text('날짜')),
      const DataColumn(label: Text('유형')),
      const DataColumn(label: Text('카테고리')),
      const DataColumn(label: Text('금액')),
      const DataColumn(label: Text('내용')),
    ];
    final rows =
        _txs.map((t) {
          final d = t.transactionDate;
          final dateStr =
              '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
          final typeStr =
              t.transactionType == TransactionType.income
                  ? '수입'
                  : t.transactionType == TransactionType.expense
                  ? '지출'
                  : '이체';
          final amt = NumberFormat('#,###').format(t.amount.abs());
          return DataRow(
            cells: [
              DataCell(Text(dateStr)),
              DataCell(Text(typeStr)),
              DataCell(Text(t.category)),
              DataCell(Text(amt)),
              DataCell(Text(t.description)),
            ],
          );
        }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(columns: cols, rows: rows),
      ),
    );
  }
}
