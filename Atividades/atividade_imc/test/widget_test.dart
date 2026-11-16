import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atividade01_imc/main.dart';

void main() {
  testWidgets('Teste da Calculadora de IMC: fluxo completo', (
    WidgetTester tester,
  ) async {
    // 1. Carrega o aplicativo
    await tester.pumpWidget(const ImcApp());

    // Verifica se os elementos iniciais estão presentes
    expect(find.text('Calculadora de IMC'), findsOneWidget);
    expect(find.text('Informe seus dados!'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.text('Calcular'), findsOneWidget);

    // 2. Testa o caso de campos não preenchidos (deve avisar falta de dados)
    await tester.tap(find.text('Calcular'));
    await tester.pump();
    expect(find.text('Insira seus dados!'), findsOneWidget);

    // 3. Preenche peso e altura (exemplo da aula: Peso = 73, Altura = 182)
    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(2));

    await tester.enterText(textFields.at(0), '73');
    await tester.enterText(textFields.at(1), '182');
    await tester.pump();

    // Clica em "Calcular"
    await tester.tap(find.text('Calcular'));
    await tester.pump();

    // O IMC calculado deve ser 22.04 ("Peso Ideal (22.04)")
    expect(find.text('Peso Ideal (22.04)'), findsOneWidget);

    // 4. Testa o botão de reiniciar
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();

    // Mensagem deve voltar ao estado inicial e os campos devem estar vazios
    expect(find.text('Informe seus dados!'), findsOneWidget);
    expect(find.widgetWithText(TextField, '73'), findsNothing);
    expect(find.widgetWithText(TextField, '182'), findsNothing);
  });
}
