// lib/core/utils/date_utils.dart

import 'package:intl/intl.dart';

/// "MM/dd" → DateTime(올해, MM, dd)
DateTime parseMMddToThisYear(String mmdd) {
  final now = DateTime.now();
  final parts = mmdd.split('/');
  return DateTime(now.year, int.parse(parts[0]), int.parse(parts[1]));
}

/// "MM/dd HH:mm:ss" 형식의 문자열을 DateTime 객체로 변환 (올해 기준)
DateTime parseMMddHHmmss(String raw) {
  final m = RegExp(r'(\d{2})/(\d{2}) (\d{2}):(\d{2}):(\d{2})').firstMatch(raw);
  if (m == null) return DateTime.now();
  final y = DateTime.now().year;
  return DateTime(
    y,
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
    int.parse(m.group(4)!),
    int.parse(m.group(5)!),
  );
}

/// 화면에 "yyyy. M. d. a h:mm" (한국어) 등 자유롭게 포맷 출력
String formatDateTime({
  required DateTime dt,
  String pattern = 'yyyy. M. d. a h:mm',
  String locale = 'ko',
}) {
  return DateFormat(pattern, locale).format(dt);
}

/// "yyyy.MM.dd" 포맷
String formatYyyyMMdd(DateTime d) {
  return DateFormat('yyyy.MM.dd').format(d);
}

/// "MM/dd" 포맷
String formatMMdd(DateTime d) {
  return DateFormat('MM/dd').format(d);
}
