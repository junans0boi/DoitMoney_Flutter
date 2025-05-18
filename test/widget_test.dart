import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitmoney_flutter/main.dart';

void main() {
  testWidgets('DoitMoneyApp builds without error', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: DoitMoneyApp()));

    // Verify that a MaterialApp was created.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
