// lib/features/account/screens/account_detail_page.dart (리팩터 후)

import 'package:flutter/material.dart';
import '../../../shared/widgets/common_list_item.dart';
import '../../../shared/widgets/currency_text.dart';
import '../services/account_service.dart';
import 'add_account_page.dart';
import '../../../shared/widgets/common_dialog.dart';

class AccountDetailPage extends StatefulWidget {
  final Account account;
  const AccountDetailPage({super.key, required this.account});

  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage> {
  bool _hidden = false;

  Future<void> _onDeletePressed() async {
    final confirm = await showConfirmationDialog(
      context: context,
      title: '정말 삭제하시겠습니까?',
      content: '한 번 삭제된 자산은 복구할 수 없습니다.',
    );
    if (!confirm) return;

    await AccountService.deleteAccount(widget.account.id);
    if (!mounted) return;
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('자산이 삭제되었습니다')));
  }

  Future<void> _onEditPressed() async {
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
          IconButton(icon: const Icon(Icons.edit), onPressed: _onEditPressed),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _onDeletePressed,
          ),
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

          // 공통 위젯으로 분리된 CurrencyText 사용
          CurrencyText(
            amount: a.balance,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),

          const SizedBox(height: 32),

          // CommonListItem 을 활용하여 중복 제거
          CommonListItem(
            label: '계좌번호',
            value: a.accountNumber.isEmpty ? '-' : a.accountNumber,
            showArrow: false,
          ),
          const Divider(height: 1),
          CommonListItem(label: '유형', value: a.accountType.name),
          const Divider(height: 1),
          CommonListItem(
            label: '잔액',
            // 다시 CurrencyText 위젯을 중첩해도 되지만, 간단히 텍스트로 표시
            value:
                '${a.balance.round().toString().replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => ",")}원',
          ),
          const Divider(height: 1),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('자산 목록에서 숨기기'),
            value: _hidden,
            onChanged: (v) => setState(() => _hidden = v),
          ),
          const Divider(height: 1),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('삭제하기', style: TextStyle(color: Colors.red)),
            onTap: _onDeletePressed,
          ),
        ],
      ),
    );
  }
}
