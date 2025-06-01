// lib/shared/widgets/common_input.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/colors.dart';

/// 기본 텍스트 입력 필드.
/// - hint: 힌트 텍스트
/// - controller: TextEditingController
/// - keyboardType: 키보드 타입 (숫자, 이메일 등)
/// - obscure: 비밀번호 입력 시 true
/// - inputFormatters: 추가적인 입력 필터
class CommonInput extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscure;
  final List<TextInputFormatter>? inputFormatters;

  const CommonInput({
    Key? key,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.inputFormatters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kInputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kInputBorder),
        ),
      ),
    );
  }
}
