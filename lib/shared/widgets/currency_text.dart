// lib/shared/widgets/currency_text.dart

// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import '../../core/utils/format_utils.dart';

/// 금액(숫자)을 포맷팅하여 '₩' 없이 “1,234,567원” 형태로 보여줍니다.
/// - amount: 숫자 금액
/// - color: 표시할 색상, 기본 검정색
/// - fontSize: 폰트 크기
/// - fontWeight: 두께
class CurrencyText extends StatelessWidget {
  final num amount;
  final Color? color;
  final double fontSize;
  final FontWeight fontWeight;

  const CurrencyText({
    Key? key,
    required this.amount,
    this.color,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatted = formatCurrency(amount);
    return Text(
      formatted,
      style: TextStyle(
        color: color ?? Colors.black,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );
  }
}
