// lib/features/transaction/screens/xlsx_parsing_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../account/services/account_service.dart'
    show Account, AccountService;
import '../services/transaction_service.dart'
    show Transaction, TransactionService, TransactionType;
import '../utils/category_mapper.dart';
import '../../../shared/widgets/loading_progress_dialog.dart';

class XlsxParsingPage extends StatefulWidget {
  final PlatformFile file;
  const XlsxParsingPage({Key? key, required this.file}) : super(key: key);

  @override
  State<XlsxParsingPage> createState() => _XlsxParsingPageState();
}

class _XlsxParsingPageState extends State<XlsxParsingPage> {
  late List<Account> _accounts;
  late List<Transaction> _existingTxs;
  late List<Transaction> _txs;
  Account? _selectedAccount;
  final _pwController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startProcess());
  }

  Future<void> _startProcess() async {
    // 1) 초기 데이터 로드
    _accounts = await AccountService.fetchAccounts();
    _existingTxs = await TransactionService.fetchTransactions();

    // 2) 엑셀 비밀번호 입력
    final pwd = await _askPassword();
    if (pwd == null) {
      context.go('/ledger');
      return;
    }

    // 3) 복호화 및 파싱
    List<List<String>> rows;
    try {
      rows = await TransactionService.decryptExcel(
        widget.file.bytes!,
        widget.file.name,
        pwd,
      );
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

    // 4) 트랜잭션 변환 및 계좌 자동 선택
    _txs = _toTransactions(rows);
    _autoSelectAccountFromRows(rows);

    // 5) 중복 제거 및 업로드 준비
    final toUpload = <Transaction>[];
    for (final t in _txs) {
      final same = _existingTxs.any((e) {
        final sameDate =
            e.transactionDate.year == t.transactionDate.year &&
            e.transactionDate.month == t.transactionDate.month &&
            e.transactionDate.day == t.transactionDate.day;
        return sameDate &&
            e.amount == t.amount &&
            e.description == t.description &&
            e.category == t.category;
      });
      if (!same) toUpload.add(t);
    }
    final dupCount = _txs.length - toUpload.length;

    // 6) 로딩 다이얼로그 & 업로드
    final progress = ValueNotifier<double>(0);
    LoadingProgressDialog.show(
      context,
      title: '파일의 거래내역을 등록하고 있어요!',
      progress: progress,
    );
    for (var i = 0; i < toUpload.length; i++) {
      final t = toUpload[i].copyWith(
        accountName: _selectedAccount!.institutionName,
        accountNumber: _selectedAccount!.accountNumber,
      );
      try {
        await TransactionService.addTransaction(t);
      } catch (_) {}
      progress.value = (i + 1) / toUpload.length;
    }
    Navigator.of(context, rootNavigator: true).pop();
    progress.dispose();

    // 7) 완료 페이지 이동
    context.go(
      '/upload-complete',
      extra: {
        'account': _selectedAccount!,
        'uploadedCount': toUpload.length,
        'duplicateCount': dupCount,
      },
    );
  }

  Future<String?> _askPassword() async {
    return showDialog<String>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('엑셀 비밀번호'),
            content: TextField(
              controller: _pwController,
              obscureText: true,
              decoration: const InputDecoration(hintText: '비밀번호 입력'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, _pwController.text),
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  List<Transaction> _toTransactions(List<List<String>> rows) {
    final list = <Transaction>[];
    for (final r in rows) {
      if (r.length < 3) continue;

      // 첫 컬럼이 비어 있으면 offset = 1
      final offset = (r[0].trim().isEmpty && r.length > 5) ? 1 : 0;
      try {
        // 1) 날짜 문자열
        final dateString = r[offset];
        DateTime dt;
        // 1-1) 기본 포맷 시도
        try {
          dt = DateFormat('yyyy.MM.dd HH:mm:ss').parse(dateString);
        }
        // 1-2) 실패 시 ISO 파싱 or 현재 시간
        catch (_) {
          dt = DateTime.tryParse(dateString) ?? DateTime.now();
        }

        // 2) 타입·금액·설명
        final typeString = r[offset + 1].trim();
        final amtString = r[offset + 2];
        final description = r.length > offset + 5 ? r[offset + 5] : '';

        // 3) 숫자 이외 제거 후 파싱
        final val = int.parse(amtString.replaceAll(RegExp(r'[^0-9]'), ''));

        // 4) 수입/지출 판정
        final isExpense = typeString == '출금';
        final amount = isExpense ? -val : val;
        final txType =
            isExpense ? TransactionType.expense : TransactionType.income;

        // 5) 카테고리 매핑
        final mappedCategory = mapCategory(description);

        // 6) 리스트에 추가
        list.add(
          Transaction(
            id: 0,
            transactionDate: dt,
            transactionType: txType,
            category: mappedCategory,
            amount: amount,
            description: description,
            accountName: '',
            accountNumber: '',
          ),
        );
      } catch (e) {
        // 한 행에서 에러 나도 전체 중단하지 않도록 로깅 후 다음으로
        debugPrint('XLSX row parse failed: $e');
        continue;
      }
    }
    return list;
  }

  void _autoSelectAccountFromRows(List<List<String>> rows) {
    for (final row in rows) {
      final idx = row.indexWhere((c) => c.trim() == '계좌번호');
      if (idx != -1 && row.length > idx + 1) {
        final rawNum = row[idx + 1].replaceAll(RegExp(r'[^0-9]'), '');
        final accIdx = _accounts.indexWhere(
          (a) => a.accountNumber.replaceAll('-', '').endsWith(rawNum),
        );
        if (accIdx != -1) _selectedAccount = _accounts[accIdx];
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('XLSX 파싱 중...')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
