import 'package:flutter/material.dart';
import '../../services/account_service.dart';
import 'add_account_page.dart';

class AccountDetailPage extends StatefulWidget {
  final Account account;
  const AccountDetailPage({super.key, required this.account});

  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage> {
  bool _hidden = false;

  Future<void> _delete() async {
    await AccountService.deleteAccount(widget.account.id);
    if (!mounted) return;
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('자산이 삭제되었습니다')));
  }

  Future<void> _edit() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddAccountPage(editing: widget.account),
      ),
    );
    if (updated == true && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.account;
    return Scaffold(
      appBar: AppBar(
        title: const Text('자산 상세'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _edit),
          IconButton(icon: const Icon(Icons.delete), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        children: [
          Row(
            children: [
              Image.asset(a.logoPath, width: 44, height: 44),
              const SizedBox(width: 16),
              Text(
                a.institutionName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            _currency(a.balance),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),

          _item('계좌번호', a.accountNumber.isEmpty ? '-' : a.accountNumber),
          _divider(),
          _item('유형', a.accountType.name),
          _divider(),
          _item('잔액', _currency(a.balance)),
          _divider(),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('자산 목록에서 숨기기'),
            value: _hidden,
            onChanged: (v) => setState(() => _hidden = v),
          ),
          _divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('삭제하기', style: TextStyle(color: Colors.red)),
            onTap: _delete,
          ),
        ],
      ),
    );
  }

  Widget _item(String label, String value) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    trailing: Text(value),
  );

  Widget _divider() => const Divider(height: 1);

  String _currency(num v) =>
      '${v.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}원';
}
