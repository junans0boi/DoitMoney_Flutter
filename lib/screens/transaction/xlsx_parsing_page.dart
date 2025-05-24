import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:intl/intl.dart';
import 'package:protect/protect.dart';
import '../../utils/agile_decrypt.dart'; // ▲ NEW
import '../../services/transaction_service.dart'
    show Transaction, TransactionService, TransactionType;
import '../../services/account_service.dart' show Account, AccountService;

class XlsxParsingPage extends StatefulWidget {
  final String path;
  const XlsxParsingPage({Key? key, required this.path}) : super(key: key);

  @override
  State<XlsxParsingPage> createState() => _XlsxParsingPageState();
}

class _XlsxParsingPageState extends State<XlsxParsingPage> {
  /* ── state ─────────────────────────────────────────────── */
  final _pwController = TextEditingController();
  bool _loading = true;
  String _raw = '';
  List<Transaction> _txs = [];
  List<Account> _accounts = [];
  Account? _selected;

  /* ── life-cycle ─────────────────────────────────────────── */
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _accounts = await AccountService.fetchAccounts();
    await _parse();
  }

  /* ── 1️⃣ 원본 or 복호화 바이트 확보 ───────────────────────── */
  Future<Uint8List> _getBytes() async {
    final orig = await File(widget.path).readAsBytes();

    // 암호 없음?
    if (_canDecode(orig)) return orig;

    while (true) {
      final pwd = await _askPwd();
      if (pwd == null) throw '사용자 취소';

      // AES-128 (Protect)
      final p = await Protect.decryptUint8List(orig, pwd);
      if (p.isDataValid &&
          p.processedBytes != null &&
          _canDecode(p.processedBytes!)) {
        return p.processedBytes!;
      }

      // AES-256 (Agile)
      final agile = AgileDecryptor.decryptXlsx(orig, pwd);
      if (agile.ok && _canDecode(agile.bytes!)) return agile.bytes!;

      // 실패 → 다시
      if (!mounted) throw '복호화 실패';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('❌ 비밀번호가 틀렸습니다')));
    }
  }

  bool _canDecode(Uint8List b) {
    try {
      Excel.decodeBytes(b);
      return true;
    } catch (_) {}
    try {
      SpreadsheetDecoder.decodeBytes(b, update: false);
      return true;
    } catch (_) {}
    return false;
  }

  Future<String?> _askPwd() {
    // ❶ 다이얼로그 띄우기 전에 한 번만 비우기
    _pwController.clear();

    // ❷ 빌더 안에서는 controller만 전달 – 더 이상 setState()를 유발하지 않음
    return showDialog<String>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('엑셀 비밀번호'),
            content: TextField(
              controller: _pwController, // ✅ 안전
              decoration: const InputDecoration(hintText: '비밀번호 입력'),
              obscureText: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
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

  /* ── 2️⃣ 파싱 ─────────────────────────────────────────────── */
  Future<void> _parse() async {
    try {
      final bytes = await _getBytes();
      if (!_tryExcel(bytes)) _parseDecoder(bytes);
    } catch (e) {
      _raw = 'ERROR: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _tryExcel(Uint8List b) {
    try {
      _parseExcel(b);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _parseExcel(Uint8List b) {
    final ex = Excel.decodeBytes(b);
    final sheets =
        ex.tables.values
            .map(
              (t) =>
                  t.rows
                      .map(
                        (r) => r.map((c) => c?.value.toString() ?? '').toList(),
                      )
                      .toList(),
            )
            .toList();
    _digest(sheets);
  }

  void _parseDecoder(Uint8List b) {
    final dec = SpreadsheetDecoder.decodeBytes(b, update: true);
    final sheets =
        dec.tables.values
            .map(
              (t) =>
                  t.rows
                      .map((r) => r.map((e) => e?.toString() ?? '').toList())
                      .toList(),
            )
            .toList();
    _digest(sheets);
  }

  /* ── 3️⃣ 공통 로직 : 행 → Transaction ────────────────────── */
  void _digest(List<List<List<String>>> all) {
    final buf = StringBuffer();
    final list = <Transaction>[];

    for (final sheet in all) {
      final hdr = sheet.indexWhere(
        (r) =>
            r.any((c) => c.contains('거래일시')) &&
            r.any((c) => c.contains('거래금액')),
      );
      if (hdr == -1) continue;

      final header = sheet[hdr];
      final cDate = header.indexWhere((c) => c.contains('거래일시'));
      final cAmt = header.indexWhere((c) => c.contains('거래금액'));
      final cDesc = header.indexWhere(
        (c) => c.contains('내') && c.contains('용'),
      );
      final cType = header.indexWhere((c) => c.contains('구분'));

      for (var r = hdr + 1; r < sheet.length; r++) {
        final row = sheet[r];
        if (row.length <= cAmt) continue;

        final dt = _parseDate(row[cDate]);
        if (dt == null) continue;

        final amt =
            int.tryParse(row[cAmt].replaceAll(RegExp(r'[^0-9\-]'), '')) ?? 0;
        list.add(
          Transaction(
            id: 0,
            transactionDate: dt,
            transactionType:
                amt >= 0 ? TransactionType.income : TransactionType.expense,
            category:
                (cType != -1 && cType < row.length) ? row[cType].trim() : '',
            amount: amt,
            description:
                (cDesc != -1 && cDesc < row.length) ? row[cDesc].trim() : '',
            accountName: '',
            accountNumber: '',
          ),
        );
        buf.writeln(row.join('\t'));
      }
    }
    setState(() => _raw = buf.toString().isEmpty ? '자료 없음' : buf.toString());
    _txs = list;
  }

  DateTime? _parseDate(String s) {
    final m = RegExp(
      r'^(\d{4})\.(\d{2})\.(\d{2})\s*(\d{2}):(\d{2}):(\d{2})',
    ).firstMatch(s);
    return (m == null)
        ? null
        : DateTime(
          int.parse(m[1]!),
          int.parse(m[2]!),
          int.parse(m[3]!),
          int.parse(m[4]!),
          int.parse(m[5]!),
          int.parse(m[6]!),
        );
  }

  /* ── 4️⃣ 등록 ─────────────────────────────────────────────── */
  Future<void> _upload() async {
    if (_txs.isEmpty || _selected == null) return;
    setState(() => _loading = true);
    final a = _selected!;
    for (final t in _txs) {
      await TransactionService.addTransaction(
        Transaction(
          id: 0,
          transactionDate: t.transactionDate,
          transactionType: t.transactionType,
          category: t.category,
          amount: t.amount,
          description: t.description,
          accountName: a.institutionName,
          accountNumber: a.accountNumber,
        ),
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${_txs.length}건 등록 완료')));
    Navigator.pop(context, true);
  }

  /* ── 5️⃣ UI ──────────────────────────────────────────────── */
  @override
  Widget build(BuildContext context) {
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
                          child: Text('${a.institutionName} (…$last4)'),
                        );
                      }).toList(),
                  value: _selected,
                  onChanged: (v) => setState(() => _selected = v),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        const TabBar(
                          tabs: [Tab(text: '원본'), Tab(text: '미리보기')],
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
                      (_txs.isEmpty || _selected == null) ? null : _upload,
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

  Widget _buildTable() {
    if (_txs.isEmpty) return const Center(child: Text('파싱된 거래가 없습니다'));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('날짜')),
          DataColumn(label: Text('유형')),
          DataColumn(label: Text('카테고리')),
          DataColumn(label: Text('금액')),
          DataColumn(label: Text('내용')),
        ],
        rows:
            _txs.map((t) {
              final d = t.transactionDate;
              final date =
                  '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
              final type =
                  t.transactionType == TransactionType.income ? '수입' : '지출';
              final amt = NumberFormat('#,###').format(t.amount.abs());
              return DataRow(
                cells: [
                  DataCell(Text(date)),
                  DataCell(Text(type)),
                  DataCell(Text(t.category)),
                  DataCell(Text(amt)),
                  DataCell(Text(t.description)),
                ],
              );
            }).toList(),
      ),
    );
  }
}
