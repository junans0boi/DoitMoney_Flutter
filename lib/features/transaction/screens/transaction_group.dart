// lib/screens/transaction/transaction_group.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/styles.dart';

class TransactionGroupHeader extends StatelessWidget {
  final DateTime date;
  final int inSum, outSum;
  const TransactionGroupHeader({
    super.key,
    required this.date,
    required this.inSum,
    required this.outSum,
  });

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('yyyy.MM.dd').format(date);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        '$label   +${NumberFormat('#,###').format(inSum)} / -${NumberFormat('#,###').format(outSum)}',
        style: kBodyText,
      ),
    );
  }
}
