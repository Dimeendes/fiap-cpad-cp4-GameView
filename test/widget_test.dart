import 'package:flutter_test/flutter_test.dart';
import 'package:gameview/main.dart';
import 'package:gameview/screens/login_screen.dart';

void main() {
  testWidgets('GameView inicia na tela de abertura', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GameViewApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
