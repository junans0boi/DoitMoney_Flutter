// lib/features/account/screens/account_page.dart (리팩터 후)

import 'package:doitmoney_flutter/core/utils/format_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../shared/widgets/common_button.dart';
import '../../../shared/widgets/common_dialog.dart';
import '../../../shared/widgets/news_banner.dart';
import '../services/account_service.dart';
import 'add_account_page.dart';
import 'account_detail_page.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  late Future<List<Account>> _futureAccounts;
  bool _banksCollapsed = false, _cardsCollapsed = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  void _loadAccounts() {
    _futureAccounts = AccountService.fetchAccounts();
  }

  Future<void> _refresh() async {
    setState(() {
      _loadAccounts();
    });
    await _futureAccounts;
  }

  Future<void> _onAdd() async {
    final added = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AddAccountPage()));
    if (added == true) _refresh();
  }

  Future<void> _onEdit(Account a) async {
    final updated = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => AddAccountPage(editing: a)));
    if (updated == true) _refresh();
  }

  Future<void> _onDelete(int id) async {
    final confirm = await showConfirmationDialog(
      context: context,
      title: '계좌 삭제',
      content: '정말 이 계좌를 삭제하시겠습니까?',
    );
    if (!confirm) return;

    await AccountService.deleteAccount(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('자산이 삭제되었습니다')));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: FutureBuilder<List<Account>>(
          future: _futureAccounts,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('오류: ${snap.error}'));
            }

            final items = snap.data ?? [];
            if (items.isEmpty) return _buildEmpty();

            final total = items.fold<double>(0, (s, e) => s + e.balance);
            final banks =
                items.where((e) => e.accountType == AccountType.BANK).toList();
            final cards =
                items.where((e) => e.accountType == AccountType.CARD).toList();

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _buildSummaryCard(total, items.length),
                  const SizedBox(height: 16),
                  _buildAdBanner(),
                  const SizedBox(height: 24),

                  _buildSectionHeader(
                    title: '계좌',
                    count: banks.length,
                    collapsed: _banksCollapsed,
                    onTap:
                        () =>
                            setState(() => _banksCollapsed = !_banksCollapsed),
                  ),
                  if (!_banksCollapsed) ..._buildAccountList(banks),
                  const SizedBox(height: 24),

                  _buildSectionHeader(
                    title: '카드',
                    count: cards.length,
                    collapsed: _cardsCollapsed,
                    onTap:
                        () =>
                            setState(() => _cardsCollapsed = !_cardsCollapsed),
                  ),
                  if (!_cardsCollapsed) ..._buildAccountList(cards),
                  const SizedBox(height: 24),

                  _buildAddButton(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/empty_assets.png', width: 200),
          const SizedBox(height: 24),
          Text('연결된 자산이 없어요', style: textTheme.headlineMedium),
          const SizedBox(height: 32),
          CommonElevatedButton(text: '자산 추가하기', onPressed: _onAdd),
        ],
      ),
    ),
  );

  Widget _buildSummaryCard(double total, int count) => Container(
    decoration: BoxDecoration(
      color: kPrimaryColor,
      borderRadius: BorderRadius.circular(20),
    ),
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('총자산', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        Text(
          formatCurrency(total),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.list_alt, size: 16, color: Colors.white),
          label: Text(
            '$count개 자산 합계',
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white70),
            backgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildAdBanner() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: NewsBanner(
        height: 120,
        borderRadius: BorderRadius.all(Radius.circular(8)),
        fontSize: 12,
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required int count,
    required bool collapsed,
    required VoidCallback onTap,
  }) => Row(
    children: [
      Expanded(
        child: Text(
          '$title ($count개)',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      IconButton(
        onPressed: onTap,
        icon: Icon(
          collapsed ? Icons.expand_more : Icons.expand_less,
          color: Colors.black54,
        ),
      ),
    ],
  );

  List<Widget> _buildAccountList(List<Account> accounts) =>
      accounts
          .map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Slidable(
                key: ValueKey(a.id),
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (_) => _onEdit(a),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      icon: Icons.edit,
                      label: '수정',
                    ),
                    SlidableAction(
                      onPressed: (_) => _onDelete(a.id),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: '삭제',
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Image.asset(a.logoPath, width: 40, height: 40),
                  title: Text(
                    a.institutionName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle:
                      a.accountNumber.isNotEmpty ? Text(a.accountNumber) : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatCurrency(a.balance),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, color: Colors.black38),
                    ],
                  ),
                  onTap: () async {
                    final edited = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => AccountDetailPage(account: a),
                      ),
                    );
                    if (edited == true) {
                      setState(() {
                        _loadAccounts();
                      });
                    }
                  },
                ),
              ),
            ),
          )
          .toList();

  Widget _buildAddButton() => GestureDetector(
    onTap: _onAdd,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F0FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '자산 추가하기',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kPrimaryColor,
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.add, color: kPrimaryColor),
        ],
      ),
    ),
  );
}
