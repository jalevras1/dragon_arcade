import 'package:flutter_test/flutter_test.dart';
import 'package:dragon_lunaryvell/main.dart';

void main() {
  testWidgets('game app starts and displays title HUD', (tester) async {
    await tester.pumpWidget(const DragonLunaryvellApp());
    expect(find.text('SCORE'), findsOneWidget);
    expect(find.text('WAVE'), findsOneWidget);
    expect(find.text('HULL'), findsOneWidget);
  });
}
