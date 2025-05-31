import 'package:flutter/material.dart';
import '../../constants/typography.dart';
import 'progress_bar.dart';

class AuthScaffold extends StatelessWidget {
  final String? title; // 헤더 텍스트
  final Widget body;
  final Widget? footer; // 버튼 등
  final bool showBack;
  final double? progress; // 0 ~ 1 (null 이면 숨김)

  const AuthScaffold({
    super.key,
    this.title,
    required this.body,
    this.footer,
    this.showBack = true,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ─── HEADER ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (showBack)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, size: 28),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                    ),
                  if (title != null)
                    Text(
                      title!,
                      style: textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
            if (progress != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ProgressBar(ratio: progress!),
              ),

            // ─── BODY ───
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: body,
              ),
            ),

            // ─── FOOTER ───
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}
