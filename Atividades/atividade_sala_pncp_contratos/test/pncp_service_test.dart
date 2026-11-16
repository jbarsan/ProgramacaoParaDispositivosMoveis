import 'dart:io';

import 'package:atividade_sala_pncp_contratos/controllers/ata_controller.dart';
import 'package:atividade_sala_pncp_contratos/controllers/contrato_controller.dart';
import 'package:atividade_sala_pncp_contratos/main.dart';
import 'package:atividade_sala_pncp_contratos/services/pncp_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cnpjMppi = '05805924000189';
  const ano = '2026';
  const dataInicial = '20260101';
  const dataFinal = '20261101';

  setUpAll(() {
    // Permite requisições HTTP reais nos testes de acesso à API do PNCP
    HttpOverrides.global = null;
  });

  group('Testes de Acesso à API do PNCP (MPPI - 2026)', () {
    late PncpService service;

    setUp(() {
      service = PncpService();
    });

    test(
      'Deve consultar Contratos/Empenhos do MPPI (05805924000189) de 20260101 a 20261101',
      () async {
        final contratos = await service.buscarContratos(
          cnpjMppi,
          ano,
          dataInicial: dataInicial,
          dataFinal: dataFinal,
          tamanhoPagina: 10,
        );

        expect(contratos, isNotEmpty);
        final primeiro = contratos.first;
        expect(primeiro.cnpjOrgao, equals(cnpjMppi));
        expect(primeiro.numeroControlePNCP, isNotEmpty);
        expect(primeiro.objetoContrato, isNotEmpty);
        expect(primeiro.nomeFornecedor, isNotEmpty);
      },
      timeout: const Timeout(Duration(seconds: 90)),
    );

    test(
      'Deve consultar Atas de Registro de Preço do MPPI (05805924000189) de 20260101 a 20261101',
      () async {
        final atas = await service.buscarAtas(
          cnpjMppi,
          ano,
          dataInicial: dataInicial,
          dataFinal: dataFinal,
          tamanhoPagina: 10,
        );

        expect(atas, isNotEmpty);
        final primeira = atas.first;
        expect(primeira.cnpjOrgao, equals(cnpjMppi));
        expect(primeira.numeroControlePNCPAta, isNotEmpty);
        expect(primeira.numeroAtaRegistroPreco, isNotEmpty);
        expect(primeira.objetoContratacao, isNotEmpty);
      },
      timeout: const Timeout(Duration(seconds: 90)),
    );

    test(
      'ContratoController e AtaController devem carregar e filtrar dados do MPPI',
      () async {
        final contratoController = ContratoController(service: service);
        await contratoController.consultarCnpj(
          cnpjMppi,
          ano,
          dataInicial: dataInicial,
          dataFinal: dataFinal,
        );
        expect(contratoController.erro, isEmpty);
        expect(contratoController.contratos, isNotEmpty);

        final ataController = AtaController(service: service);
        await ataController.consultarCnpj(
          cnpjMppi,
          ano,
          dataInicial: dataInicial,
          dataFinal: dataFinal,
        );
        expect(ataController.erro, isEmpty);
        expect(ataController.atas, isNotEmpty);
      },
      timeout: const Timeout(Duration(seconds: 120)),
    );
  });

  testWidgets(
    'Deve exibir as duas abas: Contratos/Empenhos e Atas de Registro de Preço',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MeuApp());

      expect(find.text('Contratos / Empenhos'), findsOneWidget);
      expect(find.text('Atas de Registro de Preço'), findsOneWidget);
      expect(find.text(cnpjMppi), findsWidgets);
      expect(find.text(dataInicial), findsWidgets);
      expect(find.text(dataFinal), findsWidgets);
    },
  );
}
