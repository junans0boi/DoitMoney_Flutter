import 'package:flutter/material.dart';

class SnsButton extends StatelessWidget {
  final Color background;
  final Widget child;

  /// onTap 이 **없어도** 만들 수 있도록 nullable 로 바꿉니다.
  final VoidCallback? onTap;

  const SnsButton({
    super.key,
    required this.background,
    required this.child,
    this.onTap,          // ← nullable!
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,      // ← null 이면 무시
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}