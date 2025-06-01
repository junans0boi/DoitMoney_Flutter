// lib/core/utils/format_utils.dart

import 'package:intl/intl.dart';

/// 1) 3자리 구분자를 넣어서 "1,234,567"처럼 반환
String formatWithComma(num value) {
  return NumberFormat('#,###').format(value);
}

/// 2) "₩" 없이 숫자만 반환하고, 뒤에 "원"을 붙이고 싶을 때
String formatCurrency(num value) {
  final s = formatWithComma(value.round());
  return '$s원';
}

/// 3) 간단한 퍼센트 포맷 (소수점 반올림 없이 정수 표시)
String formatPercent(double ratio) {
  return '${(ratio * 100).round()}%';
}

/// 4) 소형 단위로 축약 (예: 1,200,000 → "1.2M", 980 → "980")
String formatCompact(num value) {
  return NumberFormat.compact().format(value);
}
