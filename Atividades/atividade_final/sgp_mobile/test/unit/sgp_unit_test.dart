import 'package:flutter_test/flutter_test.dart';
import 'package:sgp_mobile/controllers/admin_controller.dart';
import 'package:sgp_mobile/controllers/demanda_controller.dart';
import 'package:sgp_mobile/controllers/viagem_controller.dart';
import 'package:sgp_mobile/models/comentario_model.dart';
import 'package:sgp_mobile/models/demanda_model.dart';
import 'package:sgp_mobile/models/historico_model.dart';
import 'package:sgp_mobile/models/notificacao_model.dart';
import 'package:sgp_mobile/models/user_model.dart';
import 'package:sgp_mobile/models/viagem_model.dart';
import 'package:sgp_mobile/services/auth_service.dart';
import 'package:sgp_mobile/services/location_service.dart';
import 'package:sgp_mobile/utils/formatters.dart';

/// Testes unitários obrigatórios das regras de negócio e serialização dos modelos.
void main() {
  group('Serialização dos Modelos (fromMap / toMap)', () {
    test('UserModel serializa e desserializa corretamente', () {
      final user = UserModel(
        uid: 'u1',
        nome: 'Maria Silva',
        email: 'maria@mppi.mp.br',
        matricula: '12345',
        cargo: 'Perita Engenheira',
        lotacao: 'ENG',
        role: 'servidor',
        ativo: true,
        createdAt: DateTime(2026, 11, 24),
      );

      final restored = UserModel.fromMap(user.toMap(), documentId: 'u1');
      expect(restored.uid, 'u1');
      expect(restored.nome, 'Maria Silva');
      expect(restored.lotacao, 'ENG');
      expect(restored.isAprovado, isTrue);
      expect(restored.isGestor, isFalse);
    });

    test('DemandaModel serializa e calcula prazo corretamente', () {
      final demanda = DemandaModel(
        id: 'd1',
        numeroSgp: '0010/2026 - ENG',
        titulo: 'Vistoria estrutural',
        descricao: 'Laudo técnico em prédio público',
        unidadeSolicitante: '1ª Promotoria de Teresina',
        numeroSei: '19.09.0001/2026',
        status: 'em_andamento',
        prioridade: 'alta',
        servidorId: 'u1',
        servidorNome: 'Maria Silva',
        lotacao: 'ENG',
        municipio: 'Teresina',
        endereco: 'Av. Frei Serafim, 100',
        latitude: -5.0892,
        longitude: -42.8019,
        dataRecebimento: DateTime(2026, 11, 1),
        prazoDias: 15,
      );

      final restored = DemandaModel.fromMap(demanda.toMap(), documentId: 'd1');
      expect(restored.numeroSgp, '0010/2026 - ENG');
      expect(restored.dataLimite, DateTime(2026, 11, 16));
      expect(restored.latitude, -5.0892);
    });

    test('ViagemModel e HistoricoModel serializam e desserializam', () {
      final viagem = ViagemModel(
        id: 'v1',
        demandasIds: const ['d1'],
        unidadeSolicitante: '1ª Promotoria',
        seiPortaria: '19.09.0020/2026',
        numeroPortaria: '045/2026',
        descricaoAtividades: 'Inspeção in loco',
        destinoCidade: 'Parnaíba',
        destinoEndereco: 'Centro, Parnaíba - PI',
        latitude: -2.9055,
        longitude: -41.7734,
        dataIda: DateTime(2026, 12, 1),
        dataRetorno: DateTime(2026, 12, 3),
        situacao: 'agendada',
        servidorId: 'u1',
      );
      final restoredViagem =
          ViagemModel.fromMap(viagem.toMap(), documentId: 'v1');
      expect(restoredViagem.destinoCidade, 'Parnaíba');
      expect(restoredViagem.demandasIds, ['d1']);

      final hist = HistoricoModel(
        id: 'h1',
        usuarioNome: 'Maria Silva',
        unidade: 'ENG',
        descricao: 'Demanda criada',
        createdAt: DateTime(2026, 11, 24),
      );
      final restoredHist =
          HistoricoModel.fromMap(hist.toMap(), documentId: 'h1');
      expect(restoredHist.descricao, 'Demanda criada');
    });
  });

  group('Provisionamento do Administrador Master', () {
    test('Provisiona administrador@sgp.com.br já ativo como administrador', () {
      final admin = AuthService.buildInitialProfile(
        uid: 'admin-uid',
        email: 'administrador@sgp.com.br',
        masterAdminEmail: 'administrador@sgp.com.br',
      );

      expect(admin.role, 'administrador');
      expect(admin.ativo, isTrue);
      expect(admin.lotacao, 'CPPT');
      expect(admin.isAprovado, isTrue);
      expect(admin.isGestor, isTrue);
    });

    test('Provisiona usuário comum como pendente e inativo', () {
      final comum = AuthService.buildInitialProfile(
        uid: 'user-uid',
        email: 'perito@mppi.mp.br',
        masterAdminEmail: 'administrador@sgp.com.br',
        nome: 'João Perito',
        matricula: '9988',
        cargo: 'Perito',
      );

      expect(comum.role, 'pendente');
      expect(comum.ativo, isFalse);
      expect(comum.lotacao, isNull);
      expect(comum.isAprovado, isFalse);
    });
  });

  group('Regras de Negócio (Comentários, Pausa e Gestão)', () {
    test('Permite edição de comentário apenas ao autor ou gestor aprovado', () {
      final comentario = ComentarioModel(
        id: 'c1',
        autorId: 'autor-1',
        autorNome: 'Autor',
        texto: 'Parecer preliminar',
        createdAt: DateTime(2026, 11, 24),
      );

      final autor = UserModel(
        uid: 'autor-1',
        nome: 'Autor',
        email: 'a@mppi.mp.br',
        matricula: '1',
        cargo: 'Perito',
        lotacao: 'ENG',
        role: 'servidor',
        ativo: true,
        createdAt: DateTime.now(),
      );

      final outroServidor = autor.copyWith(uid: 'outro-2');
      final coordenador =
          autor.copyWith(uid: 'coord-3', role: 'coordenacao');

      expect(comentario.podeEditarOuExcluir(autor), isTrue);
      expect(comentario.podeEditarOuExcluir(outroServidor), isFalse);
      expect(comentario.podeEditarOuExcluir(coordenador), isTrue);
    });

    test('Bloqueia pausa de demanda sem justificativa preenchida', () {
      expect(DemandaController.validarJustificativaPausa(null), isNotNull);
      expect(DemandaController.validarJustificativaPausa('   '), isNotNull);
      expect(DemandaController.validarJustificativaPausa('abc'), isNotNull);
      expect(
        DemandaController.validarJustificativaPausa(
          'Aguardando ofício da promotoria.',
        ),
        isNull,
      );
    });

    test('AdminController restringe gestão de usuários a gestores', () {
      final servidor = UserModel(
        uid: 's1',
        nome: 'Servidor',
        email: 's@mppi.mp.br',
        matricula: '1',
        cargo: 'Perito',
        lotacao: 'ENG',
        role: 'servidor',
        ativo: true,
        createdAt: DateTime.now(),
      );
      final admin = servidor.copyWith(role: 'administrador');

      expect(AdminController.podeGerenciarUsuarios(servidor), isFalse);
      expect(AdminController.podeGerenciarUsuarios(admin), isTrue);
    });

    test('Formata lotação com sigla e nome completo e valida máscara SEI', () {
      expect(
        AppFormatters.formatLotacao('CPPT'),
        'CPPT - Coordenadoria de Perícias e Pareceres Técnicos',
      );
      expect(
        AppFormatters.formatLotacao('ARQ'),
        'ARQ - Assessoria de Arquitetura',
      );
      expect(
        AppFormatters.formatLotacao('CONV'),
        'CONV - Assessoria de Convênios',
      );

      final formatter = SeiInputFormatter();
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '190900010001234202600'),
      );
      expect(result.text, '19.09.0001.0001234/2026-00');
      expect(AppFormatters.validateSei(result.text), isNull);
      expect(AppFormatters.validateSei('12345'), isNotNull);
      final anoFuturo = DateTime.now().year + 1;
      expect(
        AppFormatters.validateSei('19.09.0001.0001234/$anoFuturo-00'),
        isNotNull,
      );
    });

    test('ViagemModel suporta múltiplos destinos a partir de demandas', () {
      final d1 = DemandaModel(
        id: 'd1',
        numeroSgp: '0001/2026 - ENG',
        titulo: 'Vistoria A',
        descricao: '',
        unidadeSolicitante: '1ª PJ',
        numeroSei: '19.09.0001.0000001/2026-00',
        status: 'em_andamento',
        prioridade: 'normal',
        servidorId: 'u1',
        servidorNome: 'Perito',
        lotacao: 'ENG',
        municipio: 'Parnaíba',
        endereco: 'Av. São Sebastião, 100',
        latitude: -2.9055,
        longitude: -41.7734,
        dataRecebimento: DateTime(2026, 11, 1),
        prazoDias: 10,
      );
      final d2 = d1.copyWith(
        id: 'd2',
        numeroSgp: '0002/2026 - ENG',
        municipio: 'Luís Correia',
        endereco: 'Rua Principal, 50',
        latitude: -2.8794,
        longitude: -41.6672,
      );

      final viagem = ViagemModel(
        id: 'v-multi',
        demandasIds: const ['d1', 'd2'],
        unidadeSolicitante: '1ª PJ',
        seiPortaria: '19.09.0001.0000010/2026-00',
        numeroPortaria: '100/2026',
        descricaoAtividades: 'Perícias no litoral',
        destinoCidade: 'Parnaíba • Luís Correia',
        destinoEndereco: d1.endereco,
        latitude: d1.latitude,
        longitude: d1.longitude,
        destinos: [
          ViagemDestino.fromDemanda(d1),
          ViagemDestino.fromDemanda(d2),
        ],
        dataIda: DateTime(2026, 12, 1),
        dataRetorno: DateTime(2026, 12, 3),
        situacao: 'agendada',
        servidorId: 'u1',
      );

      final restored = ViagemModel.fromMap(viagem.toMap(), documentId: 'v-multi');
      expect(restored.destinos.length, 2);
      expect(restored.destinos[0].cidade, 'Parnaíba');
      expect(restored.destinos[1].cidade, 'Luís Correia');
    });

    test('LocationService formata endereço sem complementos para geocodificação', () {
      final formatted = LocationService.formatAddressForGeocoding(
        logradouro: 'Avenida Paulista',
        numero: '1578',
        bairro: 'Bela Vista',
        cidade: 'São Paulo',
        estado: 'SP',
        cep: '01310-200',
      );
      expect(
        formatted,
        'Avenida Paulista, 1578, Bela Vista, São Paulo - SP, 01310-200, Brasil',
      );
    });

    test('Valida regras de exclusão e desvínculo de demandas e viagens', () {
      final gestor = UserModel(
        uid: 'g1',
        nome: 'Gestor',
        email: 'g@mppi.mp.br',
        matricula: '1',
        cargo: 'Coord',
        lotacao: 'CPPT',
        role: 'coordenacao',
        ativo: true,
        createdAt: DateTime.now(),
      );
      final servidor = gestor.copyWith(uid: 's1', role: 'servidor');

      final demandaNaoIniciada = DemandaModel(
        id: 'd1',
        numeroSgp: '0001/2026 - ENG',
        titulo: 'Vistoria',
        descricao: '',
        unidadeSolicitante: '1ª PJ',
        numeroSei: '19.09.0001.0000001/2026-00',
        status: 'nao_iniciada',
        prioridade: 'normal',
        servidorId: 's1',
        servidorNome: 'Servidor',
        lotacao: 'ENG',
        municipio: 'Teresina',
        endereco: 'Centro',
        latitude: -5.0,
        longitude: -42.8,
        dataRecebimento: DateTime(2026, 11, 1),
        prazoDias: 10,
      );

      final viagemAgendada = ViagemModel(
        id: 'v1',
        demandasIds: const ['d1'],
        unidadeSolicitante: '1ª PJ',
        seiPortaria: '19.09.0001.0000002/2026-00',
        numeroPortaria: '10/2026',
        descricaoAtividades: '',
        destinoCidade: 'Teresina',
        destinoEndereco: 'Centro',
        latitude: -5.0,
        longitude: -42.8,
        dataIda: DateTime(2026, 12, 1),
        dataRetorno: DateTime(2026, 12, 2),
        situacao: 'agendada',
        servidorId: 's1',
      );

      // Exclusão de demanda: bloqueada com viagem, permitida se nao_iniciada e sem viagem.
      expect(
        DemandaController.validarExclusaoDemanda(
          demanda: demandaNaoIniciada,
          viagensVinculadas: [viagemAgendada],
          solicitante: gestor,
        ),
        isNotNull,
      );
      expect(
        DemandaController.validarExclusaoDemanda(
          demanda: demandaNaoIniciada.copyWith(status: 'em_andamento'),
          viagensVinculadas: const [],
          solicitante: gestor,
        ),
        isNotNull,
      );
      expect(
        DemandaController.validarExclusaoDemanda(
          demanda: demandaNaoIniciada,
          viagensVinculadas: const [],
          solicitante: gestor,
        ),
        isNull,
      );

      // Desvínculo pelo servidor: permitido em viagem agendada, bloqueado em em_andamento.
      expect(
        DemandaController.validarDesvinculoProprio(
          demanda: demandaNaoIniciada,
          viagensVinculadas: [viagemAgendada],
          servidor: servidor,
        ),
        isNull,
      );
      expect(
        DemandaController.validarDesvinculoProprio(
          demanda: demandaNaoIniciada,
          viagensVinculadas: [viagemAgendada.copyWith(situacao: 'em_andamento')],
          servidor: servidor,
        ),
        isNotNull,
      );

      // Viagem: exclusão só sem demandas; desvínculo bloqueado se em_andamento/concluida.
      expect(
        ViagemController.validarExclusaoViagem(
          viagem: viagemAgendada,
          solicitante: gestor,
        ),
        isNotNull,
      );
      expect(
        ViagemController.validarExclusaoViagem(
          viagem: viagemAgendada.copyWith(demandasIds: const []),
          solicitante: gestor,
        ),
        isNull,
      );
      expect(
        ViagemController.validarDesvinculoDemandaViagem(
          viagem: viagemAgendada.copyWith(situacao: 'concluida'),
          solicitante: gestor,
        ),
        isNotNull,
      );

      // NotificacaoModel
      final notif = NotificacaoModel(
        id: 'n1',
        destinatarioId: 'gestores',
        titulo: 'Teste',
        mensagem: 'Msg',
        tipo: 'demanda',
        referenciaId: 'd1',
        lidaPor: const ['g1'],
        createdAt: DateTime(2026, 11, 27),
      );
      final restoredNotif = NotificacaoModel.fromMap(notif.toMap(), documentId: 'n1');
      expect(restoredNotif.foiLidaPor('g1'), isTrue);
      expect(restoredNotif.foiLidaPor('s1'), isFalse);

      // Exclusão de conta de usuário: bloqueia autoexclusão e Admin Master.
      expect(
        AdminController.validarExclusaoUsuario(
          solicitante: gestor,
          alvo: gestor,
          masterAdminEmail: 'administrador@sgp.com.br',
        ),
        isNotNull,
      );
      expect(
        AdminController.validarExclusaoUsuario(
          solicitante: gestor,
          alvo: servidor.copyWith(email: 'administrador@sgp.com.br'),
          masterAdminEmail: 'administrador@sgp.com.br',
        ),
        isNotNull,
      );
      expect(
        AdminController.validarExclusaoUsuario(
          solicitante: gestor,
          alvo: servidor,
          masterAdminEmail: 'administrador@sgp.com.br',
        ),
        isNull,
      );
      // Coordenador não pode excluir outro coordenador; Administrador pode.
      final outroCoord = gestor.copyWith(uid: 'g2', email: 'g2@mppi.mp.br');
      final adminMaster = gestor.copyWith(
        uid: 'admin',
        role: 'administrador',
        email: 'administrador@sgp.com.br',
      );
      expect(
        AdminController.validarExclusaoUsuario(
          solicitante: gestor,
          alvo: outroCoord,
          masterAdminEmail: 'administrador@sgp.com.br',
        ),
        isNotNull,
      );
      expect(
        AdminController.validarExclusaoUsuario(
          solicitante: adminMaster,
          alvo: outroCoord,
          masterAdminEmail: 'administrador@sgp.com.br',
        ),
        isNull,
      );

      // Número SGP: formatação numero/ano + sigla da lotação.
      final sgpFmt = SgpNumeroInputFormatter();
      final sgpVal = sgpFmt.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '1234/2026'),
      );
      expect(AppFormatters.validateSgpNumero(sgpVal.text), isNull);
      expect(
        AppFormatters.formatNumeroSgpCompleto(sgpVal.text, 'ENG'),
        '0001234/2026-ENG',
      );
      expect(AppFormatters.validateSgpNumero('abc/26'), isNotNull);
    });
  });
}
