import 'package:flutter/material.dart';
import '../../../constants/colors.dart';

class ProgressBar extends StatelessWidget {
  final double ratio; // 0.0 ~ 1.0

  const ProgressBar({super.key, required this.ratio});

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: ratio,
      minHeight: 2,
      color: kPrimary,
      backgroundColor: Colors.grey.shade200,
    );
  }
}