import 'package:flutter/material.dart';
import '../../../constants/colors.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool enabled;
  final bool outline;

  const AuthButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.enabled = true,
    this.outline = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = outline ? Colors.white : kPrimary;
    final foreground = outline ? kPrimary : Colors.white;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade600,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: outline ? const BorderSide(color: kPrimary) : BorderSide.none,
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
