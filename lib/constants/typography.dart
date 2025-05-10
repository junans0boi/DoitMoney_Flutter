import 'package:flutter/material.dart';
import 'colors.dart';

final textTheme = TextTheme(
  headlineMedium: const TextStyle(
    fontSize: 28, fontWeight: FontWeight.w700,
    fontFamily: 'GmarketSans', color: kPrimary,   // ← 수정
  ),
  titleMedium: const TextStyle(
    fontSize: 18, fontWeight: FontWeight.w500,
    fontFamily: 'GmarketSans', color: kPrimary,   // ← 수정
  ),
  bodyMedium: const TextStyle(                  // 본문(16)
    fontSize: 16, fontFamily: 'GmarketSans',
    color: Colors.black87,
  ),
);