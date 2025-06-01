// lib/shared/widgets/loading_progress_dialog.dart
// ignore_for_file: use_super_parameters

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 진행률(0.0~1.0)을 받아 화면 전체에 프로그레스 다이얼로그를 보여줍니다.
/// show 메서드를 통해 간단히 사용 가능.
class LoadingProgressDialog extends StatelessWidget {
  final String title;
  final ValueListenable<double> progress;

  const LoadingProgressDialog._({
    Key? key,
    required this.title,
    required this.progress,
  }) : super(key: key);

  /// [context]에 다이얼로그 형태로 띄우고, 배경은 흰색으로 처리합니다.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required ValueListenable<double> progress,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.white,
      pageBuilder:
          (_, __, ___) =>
              LoadingProgressDialog._(title: title, progress: progress),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (_, pct, __) {
              final percentText = (pct * 100).toStringAsFixed(0);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/upload_avatar.gif',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$percentText% 완료',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(value: pct, minHeight: 8),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
