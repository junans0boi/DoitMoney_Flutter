import 'package:flutter_test/flutter_test.dart';
import 'package:doitmoney_flutter/main.dart';

void main() {
  testWidgets('SplashScreen shows Planary logo', (WidgetTester tester) async {
    await tester.pumpWidget(const PlanaryApp());
    await tester.pumpAndSettle(); // 애니메이션/지연 끝까지

    // 초기 화면은 SplashScreen 이므로 'Planary' 텍스트가 보여야 함
    expect(find.text('Planary'), findsOneWidget);
  });
}
