// lib/screens/account/add_account_page.dart
import 'package:flutter/material.dart';
import 'package:doitmoney_flutter/services/account_service.dart'
    show Account, AccountService, AccountType, BankDetail;
import '../../constants/colors.dart'; // colors 만 상대경로로

/// BankDetail enum 은 DEMAND, SAVINGS, OVERDRAFT, PENSION 으로 정의되어 있으니
/// extension 도 그에 맞춰 대문자로 씁니다.
extension BankDetailDisplay on BankDetail {
  String get label {
    switch (this) {
      case BankDetail.DEMAND:
        return '입출금';
      case BankDetail.SAVINGS:
        return '예적금';
      case BankDetail.OVERDRAFT:
        return '마이너스통장';
      case BankDetail.PENSION:
        return '연금';
    }
  }
}

class AddAccountPage extends StatefulWidget {
  final Account? editing;
  const AddAccountPage({super.key, this.editing});

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  AccountType? _type;
  BankDetail? _detail;
  String? _institution;

  final _no = TextEditingController();
  final _amt = TextEditingController();

  bool get _needInstitution =>
      _type == AccountType.BANK || _type == AccountType.CARD;
  bool get _needDetail => _type == AccountType.BANK;
  bool get _ready =>
      _type != null &&
      _amt.text.isNotEmpty &&
      (_needDetail ? _detail != null : true) &&
      (_needInstitution ? _institution != null : true);
  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final e = widget.editing!;
      _type = e.accountType;
      _detail = e.detailType;
      _institution = e.institutionName;
      _no.text = e.accountNumber;
      _amt.text = e.balance.round().toString();
    }
  }

  Future<void> _save() async {
    final acct = Account(
      id: widget.editing?.id ?? 0,
      accountType: _type!,
      detailType: _detail!,
      institutionName:
          _institution ?? (_type == AccountType.CASH ? '현금' : '기타'),
      accountNumber: _no.text,
      balance: double.tryParse(_amt.text.replaceAll(',', '')) ?? 0,
      logoPath:
          AccountService.logos[_institution ?? ''] ??
          'assets/images/default.png',
    );
    if (_isEdit) {
      await AccountService.updateAccount(acct.id, acct);
    } else {
      await AccountService.addAccount(acct);
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('자산 직접입력')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          children: [
            _select('유형*', _type?.name ?? '입력해주세요', _pickType),
            const Divider(height: 1),

            if (_needDetail) ...[
              _select('상세분류*', _detail?.label ?? '입력해주세요', _pickDetail),
              const Divider(height: 1),
            ],

            if (_needInstitution) ...[
              _select('은행*', _institution ?? '입력해주세요', _pickInstitution),
              const Divider(height: 1),
              _input('계좌번호', _no, TextInputType.number),
              const Divider(height: 1),
            ],

            _input('금액*', _amt, TextInputType.number, suffix: '원'),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _ready ? _save : null,
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  '등록하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* ─────────────────── 공통 위젯 ─────────────────── */
  Widget _select(String label, String value, VoidCallback onTap) => ListTile(
    title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: value.contains('입력') ? Colors.grey : kPrimary,
          ),
        ),
        const Icon(Icons.chevron_right),
      ],
    ),
    onTap: onTap,
  );

  Widget _input(
    String label,
    TextEditingController c,
    TextInputType t, {
    String? suffix,
  }) => ListTile(
    title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
    subtitle: TextField(
      controller: c,
      keyboardType: t,
      onChanged: (_) => setState(() {}), // 여기를 추가
      decoration: InputDecoration(
        hintText: '입력해주세요',
        border: InputBorder.none,
        suffixText: suffix,
      ),
    ),
  );

  /* ─────────────────── Pickers ─────────────────── */
  Future<void> _pickType() async {
    final sel = await _showPicker<AccountType>(
      '자산유형 선택',
      AccountType.values,
      (t) => switch (t) {
        AccountType.BANK => '계좌',
        AccountType.CARD => '카드',
        AccountType.CASH => '현금',
        AccountType.ETC => '기타',
      },
    );
    if (sel != null) {
      setState(() {
        _type = sel;
        _detail = null;
        _institution = null;
      });
    }
  }

  Future<void> _pickDetail() async {
    final sel = await _showPicker<BankDetail>(
      '상세분류 선택',
      BankDetail.values,
      (d) => d.label,
    );
    if (sel != null) setState(() => _detail = sel);
  }

  Future<void> _pickInstitution() async {
    final map =
        _type == AccountType.BANK
            ? AccountService.bankLogos
            : AccountService.cardLogos;

    final sel = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _InstitutionPicker(map: map),
    );
    if (sel != null) setState(() => _institution = sel);
  }

  /* 범용 리스트-바텀시트 */
  Future<T?> _showPicker<T>(
    String title,
    List<T> opts,
    String Function(T) display,
  ) {
    return showModalBottomSheet<T>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (_) =>
              _BottomPicker<T>(title: title, options: opts, display: display),
    );
  }
}

/* ─────────────────── 기관 선택 Grid ─────────────────── */
class _InstitutionPicker extends StatelessWidget {
  const _InstitutionPicker({required this.map});
  final Map<String, String> map;

  @override
  Widget build(BuildContext context) {
    final items = map.entries.toList();
    return SafeArea(
      child: SizedBox(
        height: 420,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '기관 선택',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisExtent: 96,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final e = items[i];
                  return InkWell(
                    onTap: () => Navigator.pop(context, e.key),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundImage: AssetImage(e.value),
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          e.key,
                          style: const TextStyle(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ─────────────────── 범용 목록 Picker ─────────────────── */
class _BottomPicker<T> extends StatelessWidget {
  const _BottomPicker({
    required this.title,
    required this.options,
    required this.display,
  });
  final String title;
  final List<T> options;
  final String Function(T) display;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const Divider(height: 1),
        ...options.map(
          (o) => ListTile(
            title: Text(display(o)),
            onTap: () => Navigator.pop(context, o),
          ),
        ),
        const SizedBox(height: 12),
      ],
    ),
  );
}
