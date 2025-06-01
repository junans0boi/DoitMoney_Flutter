// lib/shared/widgets/loading_overlay.dart
// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';

/// 페이지 전체를 블러 처리하면서 CircularProgressIndicator를 보여주는 오버레이 위젯
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({Key? key, required this.isLoading, required this.child})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
