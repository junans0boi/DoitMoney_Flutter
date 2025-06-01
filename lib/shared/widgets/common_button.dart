// lib/shared/widgets/common_button.dart

import 'package:flutter/material.dart';
import '../../constants/colors.dart';

/// 기본 색상(Primary)을 배경으로 하는 ElevatedButton
class CommonElevatedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool enabled;

  const CommonElevatedButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade600,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// 외곽선(outline)만 있는 버튼
class CommonOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool enabled;

  const CommonOutlinedButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: kPrimary),
          foregroundColor: kPrimary,
          disabledForegroundColor: Colors.grey.shade600,
          disabledBackgroundColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
