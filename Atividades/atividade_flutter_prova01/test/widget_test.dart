import 'package:flutter_test/flutter_test.dart';
import 'package:atividade_flutter_prova01/main.dart';

void main() {
  testWidgets('Discovery app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Discovery'), findsOneWidget);
    expect(find.text('Nearby'), findsOneWidget);
  });
}
