import 'package:flutter_test/flutter_test.dart';
import 'package:gameview/main.dart';

void main() {
  testWidgets('GameView inicia na tela de abertura', (WidgetTester tester) async {
    await tester.pumpWidget(const GameViewApp());

    expect(find.byType(GameViewApp), findsOneWidget);
  });
}