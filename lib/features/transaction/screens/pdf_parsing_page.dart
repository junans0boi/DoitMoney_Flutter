// lib/features/transaction/screens/pdf_parsing_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_pdf_text/flutter_pdf_text.dart';
import 'package:go_router/go_router.dart';
import '../../account/services/account_service.dart'
    show Account, AccountService;
import '../services/transaction_service.dart'
    show Transaction, TransactionService, TransactionType;
import '../utils/category_mapper.dart';
import '../../../shared/widgets/loading_progress_dialog.dart';

class PdfParsingPage extends StatefulWidget {
  final String path;
  const PdfParsingPage({Key? key, required this.path}) : super(key: key);

  @override
  State<PdfParsingPage> createState() => _PdfParsingPageState();
}

class _PdfParsingPageState extends State<PdfParsingPage> {
  late List<Account> _accounts;
  late List<Transaction> _existingTxs;
  late List<Transaction> _txs;
  Account? _selectedAccount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startProcess());
  }

  Future<void> _startProcess() async {
    // 1) 초기 데이터 로드
    _accounts = await AccountService.fetchAccounts();
    _existingTxs = await TransactionService.fetchTransactions();

    // 2) PDF 텍스트 로드 (비밀번호 다이얼로그)
    String raw;
    try {
      raw = await _loadPdfText(widget.path);
    } catch (e) {
      await showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('오류'),
              content: Text(e.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인'),
                ),
              ],
            ),
      );
      context.go('/ledger');
      return;
    }

    // 3) 거래 파싱
    _txs = _extractTransactions(raw);

    // 4) 계좌 자동 선택
    _autoSelectAccount(raw);

    // 5) 계좌 미선택 시 다이얼로그로 선택
    if (_selectedAccount == null) {
      final Account? chosen = await showDialog<Account>(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          Account? temp;
          return AlertDialog(
            title: const Text('계좌를 선택해주세요'),
            content: DropdownButtonFormField<Account>(
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
              onChanged: (v) => temp = v,
              hint: const Text('계좌 선택'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, temp),
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
      if (chosen == null) {
        context.go('/ledger');
        return;
      }
      _selectedAccount = chosen;
    }

    // 6) 중복 제거 및 준비
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

    // 7) 로딩 다이얼로그 & 업로드
    final progress = ValueNotifier<double>(0);
    LoadingProgressDialog.show(
      context,
      title: '파일의 거래내역을 등록하고 있어요!',
      progress: progress,
    );
    for (var i = 0; i < toUpload.length; i++) {
      final tx = toUpload[i].copyWith(
        accountName: _selectedAccount!.institutionName,
        accountNumber: _selectedAccount!.accountNumber,
      );
      try {
        await TransactionService.addTransaction(tx);
      } catch (_) {}
      progress.value = (i + 1) / toUpload.length;
    }
    Navigator.of(context, rootNavigator: true).pop();
    progress.dispose();

    // 8) 완료 페이지 이동
    context.go(
      '/upload-complete',
      extra: {
        'account': _selectedAccount!,
        'uploadedCount': toUpload.length,
        'duplicateCount': dupCount,
      },
    );
  }

  Future<String> _loadPdfText(String path) async {
    String? pwd;
    final controller = TextEditingController();
    while (true) {
      try {
        final doc =
            pwd == null
                ? await PDFDoc.fromPath(path)
                : await PDFDoc.fromPath(path, password: pwd);
        return doc.text;
      } catch (e) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('password') || msg.contains('encrypted')) {
          final input = await showDialog<String>(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: const Text('PDF 비밀번호'),
                  content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(hintText: '비밀번호 입력'),
                    obscureText: true,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, null),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, controller.text),
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

  void _autoSelectAccount(String raw) {
    final m = RegExp(r'계좌번호.*?([0-9\-]+)').firstMatch(raw);
    if (m == null) return;
    final num = m.group(1)!.replaceAll('-', '');
    final idx = _accounts.indexWhere(
      (a) => a.accountNumber.replaceAll('-', '').endsWith(num),
    );
    if (idx != -1) _selectedAccount = _accounts[idx];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF 파싱 중...')),
      body: const SizedBox.shrink(),
    );
  }
}
