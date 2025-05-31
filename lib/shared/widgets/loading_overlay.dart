///Users/junzzang_m1/Documents/GitHub/DoitMoney_Flutter/lib/widgets/common/loading_overlay.dart
import 'package:flutter/material.dart';

/// 페이지 전체 로딩 블러-오버레이
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

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
