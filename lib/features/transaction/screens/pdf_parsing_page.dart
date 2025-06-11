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
import '../utils/category_mapper.dart';
import 'upload_complete_page.dart';

class PdfParsingPage extends StatefulWidget {
  final String path;
  const PdfParsingPage({Key? key, required this.path}) : super(key: key);

  @override
  State<PdfParsingPage> createState() => _PdfParsingPageState();
}

class _PdfParsingPageState extends State<PdfParsingPage> {
  List<Transaction> _existingTxs = []; // ① 서버에 있는 기존 거래
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
    _existingTxs = await TransactionService.fetchTransactions(); // ①
    await _parseFile();
  }

  Future<void> _parseFile() async {
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
      // 실제 가맹점명(키워드 검사 대상)은 group(6)에 들어 있습니다.
      final merchantName = m.group(6)!.trim(); // 예: “씨유(CU) 학익보성점”
      final outStr = m.group(4)!.replaceAll(',', '');
      final inStr = m.group(5)!.replaceAll(',', '');

      // 1) 날짜/시간 → DateTime
      final year = int.parse(datePart.substring(0, 4));
      final month = int.parse(datePart.substring(4, 6));
      final day = int.parse(datePart.substring(6, 8));
      final parts = timePart.split(':').map(int.parse).toList();
      final dt = DateTime(year, month, day, parts[0], parts[1], parts[2]);

      // 2) 금액, 유형(expense/income)
      final outAmt = int.parse(outStr);
      final inAmt = int.parse(inStr);
      final amount = (outAmt > 0) ? -outAmt : inAmt; // 출금이면 음수, 입금이면 양수
      final type =
          (outAmt > 0)
              ? TransactionType.expense
              : (inAmt > 0 ? TransactionType.income : TransactionType.transfer);

      // 3) ★★★ “rawCategory”를 이용해서 카테고리 매핑 ★★★
      // (원래 “description”이 아니라 “rawCategory”를 넘겨 줘야 정확히 잡힙니다)
      final mappedCategory = mapCategory(merchantName);
      print(
        '>>> mapCategory 호출: merchant="$merchantName" → mapped="$mappedCategory"',
      );

      list.add(
        Transaction(
          id: 0,
          transactionDate: dt,
          transactionType: type,
          category: mappedCategory,
          amount: amount,
          description: merchantName, // 또는 필요하다면 “메모” 컬럼을 따로 가져와도 됩니다.
          accountName: '',
          accountNumber: '',
        ),
      );
    }

    return list;
  }

  Future<void> _processUpload() async {
    if (_txs.isEmpty || _selectedAccount == null) return;

    // ② 중복 검사: 같은 날짜·금액·내용 조합으로 단순 비교
    final toUpload = <Transaction>[];
    for (final t in _txs) {
      final isDup = _existingTxs.any((e) {
        // ① 날짜만 비교 (DB엔 LocalDate 저장)
        final sameDate =
            e.transactionDate.year == t.transactionDate.year &&
            e.transactionDate.month == t.transactionDate.month &&
            e.transactionDate.day == t.transactionDate.day;
        // ② 금액·설명·카테고리 일치 여부
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

    // ③ 업로드 완료 페이지로: 성공 개수와 중복 개수 전달
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
                  onPressed: _processUpload,
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
      const DataColumn(label: Text('카테고리')), // 키워드 매핑된 카테고리 그대로 보여 줌
      const DataColumn(label: Text('금액')),
      const DataColumn(label: Text('내용')),
    ];
    final rows =
        _txs.map((t) {
          final dateStr =
              '${t.transactionDate.month.toString().padLeft(2, '0')}/${t.transactionDate.day.toString().padLeft(2, '0')}';
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
              DataCell(Text(t.category)), // mapCategory 로 결정된 값
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
