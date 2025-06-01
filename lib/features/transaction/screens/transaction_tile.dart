// ignore_for_file: use_super_parameters, deprecated_member_use, unnecessary_brace_in_string_interps

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../constants/colors.dart';
import '../../../constants/styles.dart';
import '../services/transaction_service.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final bool selectMode;
  final bool selected;
  final void Function()? onTap;
  final void Function(bool?)? onCheckboxChanged;

  const TransactionTile({
    Key? key,
    required this.transaction,
    this.selectMode = false,
    this.selected = false,
    this.onTap,
    this.onCheckboxChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final amt = NumberFormat('#,###').format(transaction.amount.abs());

    return ListTile(
      leading:
          selectMode
              ? Checkbox(value: selected, onChanged: onCheckboxChanged)
              : CircleAvatar(
                backgroundColor: kPrimaryColor.withOpacity(0.1),
                child: const Icon(Icons.receipt_long, color: kPrimaryColor),
              ),
      title: Text(transaction.description, style: kBodyText),
      subtitle: Text(
        transaction.category,
        style: kBodyText.copyWith(color: Colors.black54),
      ),
      trailing: Text(
        '${amt}원',
        style: kBodyText.copyWith(
          color: transaction.amount < 0 ? kError : kPrimaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}
