import 'package:flutter/material.dart';
import 'colors.dart';

const textTheme = TextTheme(
  headlineMedium: TextStyle(
    // ← const 키워드 삭제
    fontSize: 28,
    fontWeight: FontWeight.w700,
    fontFamily: 'GmarketSans',
    color: kPrimary,
  ),
  titleMedium: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    fontFamily: 'GmarketSans',
    color: kPrimary,
  ),
  bodyMedium: TextStyle(
    fontSize: 16,
    fontFamily: 'GmarketSans',
    color: Colors.black87,
  ),
);
