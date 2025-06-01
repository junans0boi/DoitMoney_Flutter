// lib/shared/widgets/common_dialog.dart

// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';

/// 간단한 확인 다이얼로그를 표시하고 결과(boolean)를 반환
Future<bool> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = '확인',
  String cancelText = '취소',
}) {
  return showDialog<bool>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(confirmText),
            ),
          ],
        ),
  ).then((v) => v ?? false);
}

/// 비밀번호 입력 다이얼로그 (PDF/XLSX 복호화용)
Future<String?> showPasswordInputDialog({
  required BuildContext context,
  required String title,
}) {
  final _pwController = TextEditingController();
  return showDialog<String>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: _pwController,
            decoration: const InputDecoration(hintText: '비밀번호 입력'),
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, _pwController.text),
              child: const Text('확인'),
            ),
          ],
        ),
  );
}
