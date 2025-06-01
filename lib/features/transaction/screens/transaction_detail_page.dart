// lib/features/transaction/screens/transaction_detail_page.dart (리팩터 후)

// ignore_for_file: use_build_context_synchronously

import 'package:doitmoney_flutter/shared/widgets/common_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../constants/colors.dart';
import '../../../constants/styles.dart';
import '../services/transaction_service.dart';

class TransactionDetailPage extends ConsumerWidget {
  final Transaction transaction;

  const TransactionDetailPage({required this.transaction, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tx = transaction;
    final amountText = '${NumberFormat('#,###').format(tx.amount.abs())}원';
    final amountColor = tx.amount < 0 ? kError : kSuccess;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('거래 상세'),
        actions: [
          TextButton(
            onPressed: () async {
              final edited = await context.push<bool>(
                '/transaction/edit',
                extra: transaction,
              );
              if (edited == true) {
                context.pop(true);
              }
            },
            child: const Text('수정', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, size: 32, color: kPrimaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.description, style: kTitleText),
                    const SizedBox(height: 4),
                    Text(
                      amountText,
                      style: kTitleText.copyWith(color: amountColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          CommonListItem(label: '카테고리', value: tx.category, showArrow: false),
          CommonListItem(
            label: '지출 일시',
            value: DateFormat('yyyy년 M월 d일 H:mm').format(tx.transactionDate),
            showArrow: false,
          ),
          CommonListItem(
            label: '지출 수단',
            value: tx.accountName,
            showArrow: false,
          ),
          const Divider(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('가계부 내역 포함', style: kBodyText),
              Switch(value: true, onChanged: (_) {}),
            ],
          ),
          const SizedBox(height: 16),

          const Text('메모', style: kBodyText),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(tx.description, style: kBodyText),
          ),

          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: 스토리 등록 로직
            },
            icon: const Icon(Icons.add_comment),
            label: const Text('스토리 등록하기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEEEAF8),
            ),
          ),
        ],
      ),
    );
  }
}
