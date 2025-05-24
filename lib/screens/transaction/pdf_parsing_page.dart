// lib/screens/transaction/pdf_parsing_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_pdf_text/flutter_pdf_text.dart';
import 'package:intl/intl.dart';
import '../../services/transaction_service.dart'
    show Transaction, TransactionService, TransactionType;
import '../../services/account_service.dart' show Account, AccountService;

/// PDFDoc 암호 해제 및 텍스트 파싱 → 테이블 미리보기
class PdfParsingPage extends StatefulWidget {
  final String path;
  const PdfParsingPage({Key? key, required this.path}) : super(key: key);
  @override
  _PdfParsingPageState createState() => _PdfParsingPageState();
}

class _PdfParsingPageState extends State<PdfParsingPage> {
  final _pwController = TextEditingController();
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
      final list = _parsePdfTransactions(text);
      setState(() {
        _raw = text;
        _txs = list;
      });
    } catch (e) {
      setState(() => _raw = 'ERROR: \$e');
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
          pwd = await _askPwd();
          if (pwd == null) {
            throw 'PDF 비밀번호 입력이 취소되었습니다.';
          }
        } else {
          rethrow;
        }
      }
    }
  }

  Future<String?> _askPwd() {
    _pwController.clear();
    return showDialog<String>(
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
  }

  Future<void> _upload() async {
    if (_txs.isEmpty || _selectedAccount == null) return;
    setState(() => _loading = true);
    try {
      for (final t in _txs) {
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
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${_txs.length}건 등록 완료')));
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('업로드 실패: \$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Transaction> _parsePdfTransactions(String rawText) {
    final list = <Transaction>[];
    final chunks = rawText.split(
      RegExp(r'(?=^20\d{6}\s+\d{2}:\d{2}:\d{2})', multiLine: true),
    );
    final rowRegex = RegExp(
      r'^(20\d{6})\s+(\d{2}:\d{2}:\d{2})\s+(.+?)\s+([\d,]+)\s+([\d,]+)\s+(.+?)\s+([\d,]+)\s+.+$',
    );
    for (var chunk in chunks) {
      final line = chunk.replaceAll('\n', ' ').trim();
      final m = rowRegex.firstMatch(line);
      if (m == null) continue;

      final datePart = m.group(1)!;
      final timePart = m.group(2)!;
      final category = m.group(3)!.trim();
      final outStr = m.group(4)!.replaceAll(',', '');
      final inStr = m.group(5)!.replaceAll(',', '');
      final description = m.group(6)!.trim();
      final amount =
          (int.parse(outStr) > 0) ? -int.parse(outStr) : int.parse(inStr);
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
                              _buildTable(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed:
                      (_txs.isEmpty || _selectedAccount == null)
                          ? null
                          : _upload,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('등록'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
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

  /// 테이블 뷰 생성
  Widget _buildTable() {
    if (_txs.isEmpty) {
      return const Center(child: Text('파싱된 거래가 없습니다'));
    }
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
