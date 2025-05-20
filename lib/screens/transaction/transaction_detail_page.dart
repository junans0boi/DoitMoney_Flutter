// lib/screens/transaction/transaction_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../services/transaction_service.dart';

const kInputBackground = Color(0xFFF5F5F5);
const kSecondaryColor = Color(0xFFEEEAF8);

class TransactionDetailPage extends ConsumerWidget {
  final Transaction transaction;

  const TransactionDetailPage({required this.transaction, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tx = transaction;
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
                // 수정 완료 후 리스트로 true 리턴
                context.pop(true);
              }
            },
            child: const Text('수정', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 상단: 아이콘 + 설명 + 금액
          Row(
            children: [
              // (원하시면 거래별 아이콘 매핑)
              const Icon(Icons.receipt_long, size: 32, color: kPrimaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.description, style: kTitleText),
                    const SizedBox(height: 4),
                    Text(
                      '${NumberFormat('#,###').format(tx.amount.abs())}원',
                      style: kTitleText.copyWith(
                        color: tx.amount < 0 ? kError : kSuccess,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildRow('카테고리', tx.category),
          _buildRow(
            '지출 일시',
            DateFormat('yyyy년 M월 d일 H:mm').format(tx.transactionDate),
          ),
          _buildRow('지출 수단', tx.accountName),
          const Divider(height: 32),

          // 포함 토글
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('가계부 내역 포함', style: kBodyText),
              Switch(
                value: true, // 필요에 따라 상태 관리
                onChanged: (_) {},
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 메모
          const Text('메모', style: kBodyText),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kInputBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              tx.description, // 실제 메모 필드가 있을 경우 대체
              style: kBodyText,
            ),
          ),

          const SizedBox(height: 32),
          // 스토리 등록 부분 (예시)
          ElevatedButton.icon(
            onPressed: () {
              // TODO: 스토리 등록 로직
            },
            icon: const Icon(Icons.add_comment),
            label: const Text('스토리 등록하기'),
            style: ElevatedButton.styleFrom(backgroundColor: kSecondaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(label, style: kBodyText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: kBodyText.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.black38),
        ],
      ),
    );
  }
}
