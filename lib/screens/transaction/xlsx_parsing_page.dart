// lib/screens/transaction/xlsx_parsing_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../../services/transaction_service.dart'
    show Transaction, TransactionService, TransactionType;
import '../../services/account_service.dart' show Account, AccountService;

class XlsxParsingPage extends StatefulWidget {
  final Uint8List bytes;
  const XlsxParsingPage({Key? key, required this.bytes}) : super(key: key);

  @override
  _XlsxParsingPageState createState() => _XlsxParsingPageState();
}

class _XlsxParsingPageState extends State<XlsxParsingPage> {
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
    await Future.delayed(const Duration(milliseconds: 100));
    _parseXlsx();
  }

  void _parseXlsx() {
    final ex = Excel.decodeBytes(widget.bytes);
    final buf = StringBuffer();
    final list = <Transaction>[];
    for (var sheet in ex.tables.values) {
      for (var row in sheet.rows.skip(1)) {
        final cells = row.map((c) => c?.value.toString() ?? '').toList();
        buf.writeln(cells.join('\t'));
        final date = DateTime.parse(cells[0]);
        final desc = cells[1];
        final amt = int.parse(cells[2].replaceAll(',', ''));
        final type =
            amt >= 0 ? TransactionType.income : TransactionType.expense;
        list.add(
          Transaction(
            id: 0,
            transactionDate: date,
            transactionType: type,
            category: '',
            amount: amt,
            description: desc,
            accountName: '',
            accountNumber: '',
          ),
        );
      }
    }
    setState(() {
      _raw = buf.toString();
      _txs = list;
      _loading = false;
    });
  }

  Future<void> _upload() async {
    if (_txs.isEmpty || _selectedAccount == null) return;
    setState(() => _loading = true);
    final accName = _selectedAccount!.institutionName;
    final accNo = _selectedAccount!.accountNumber;
    final toUpload =
        _txs
            .map(
              (t) => Transaction(
                id: 0,
                transactionDate: t.transactionDate,
                transactionType: t.transactionType,
                category: t.category,
                amount: t.amount,
                description: t.description,
                accountName: accName,
                accountNumber: accNo,
              ),
            )
            .toList();
    for (final tx in toUpload) {
      await TransactionService.addTransaction(tx);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('\${toUpload.length}건이 등록되었습니다')));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('엑셀 파싱 결과')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<Account>(
                  decoration: const InputDecoration(labelText: '등록할 계좌 선택'),
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
                          child: Text('\${a.institutionName} (…\$last4)'),
                        );
                      }).toList(),
                  value: _selectedAccount,
                  hint: const Text('계좌를 선택하세요'),
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
                              _buildModelTable(),
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
                  label: const Text('거래 등록'),
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

  Widget _buildModelTable() {
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
              '${d.month.toString().padLeft(2, "0")}/${d.day.toString().padLeft(2, "0")}';
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
