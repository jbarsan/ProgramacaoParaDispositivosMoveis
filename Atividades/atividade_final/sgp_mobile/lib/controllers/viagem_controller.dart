import 'package:flutter/foundation.dart';

import '../models/historico_model.dart';
import '../models/notificacao_model.dart';
import '../models/user_model.dart';
import '../models/viagem_model.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';

// Controller responsável pelo gerenciamento de viagens/deslocamentos (RF-013),
// regras de desvínculo/exclusão e notificações aos servidores vinculados.
class ViagemController extends ChangeNotifier {
  final FirestoreService _firestoreService;

  bool _isLoading = false;
  String? _errorMessage;

  ViagemController({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Valida se um gestor pode excluir uma viagem:
  // somente quando não houver nenhuma demanda vinculada.
  static String? validarExclusaoViagem({
    required ViagemModel viagem,
    required UserModel solicitante,
  }) {
    if (!solicitante.isGestor) {
      return 'Apenas Coordenação ou Administrador podem excluir viagens.';
    }
    if (viagem.demandasIds.isNotEmpty) {
      return 'Desvincule todas as demandas antes de excluir esta viagem.';
    }
    return null;
  }

  // Valida se uma demanda pode ser desvinculada de uma viagem:
  // bloqueia se a viagem já foi iniciada (`em_andamento`) ou `concluida`.
  static String? validarDesvinculoDemandaViagem({
    required ViagemModel viagem,
    required UserModel solicitante,
  }) {
    if (!solicitante.isGestor) {
      return 'Apenas Coordenação ou Administrador podem desvincular demandas da viagem.';
    }
    if (viagem.situacao == AppConstants.viagemEmAndamento ||
        viagem.situacao == AppConstants.viagemConcluida) {
      return 'Não é possível desvincular demandas de uma viagem iniciada ou concluída.';
    }
    return null;
  }

  // Stream de viagens conforme o perfil do usuário.
  Stream<List<ViagemModel>> streamViagens(UserModel usuario) =>
      _firestoreService.streamViagens(usuario);

  // Cadastra uma nova viagem, registra no histórico das demandas vinculadas
  // e notifica todos os servidores associados (RF-012 / RF-013).
  Future<bool> criarViagem({
    required ViagemModel viagem,
    required UserModel usuario,
  }) async {
    _setLoading(true);
    try {
      final viagemId = await _firestoreService.createViagem(viagem);
      for (final demandaId in viagem.demandasIds) {
        await _firestoreService.addHistorico(
          demandaId,
          HistoricoModel(
            id: '',
            usuarioNome: usuario.nome,
            unidade: usuario.lotacao ?? 'CPPT',
            descricao:
                'Viagem agendada para ${viagem.destinoCidade} (Portaria ${viagem.numeroPortaria}).',
            createdAt: DateTime.now(),
          ),
        );
      }
      for (final servId in viagem.servidoresIds) {
        await _firestoreService.addNotificacao(
          NotificacaoModel(
            id: '',
            destinatarioId: servId,
            titulo: 'Nova Viagem Vinculada',
            mensagem:
                'Você foi vinculado à viagem para ${viagem.destinoCidade} (Portaria ${viagem.numeroPortaria}).',
            tipo: 'viagem',
            referenciaId: viagemId,
            createdAt: DateTime.now(),
          ),
        );
      }
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao cadastrar viagem: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Atualiza os dados de uma viagem existente.
  Future<bool> atualizarViagem(ViagemModel viagem) async {
    _setLoading(true);
    try {
      await _firestoreService.updateViagem(viagem);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar viagem: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Desvincula uma demanda de uma viagem (desde que não iniciada ou concluída).
  Future<ViagemModel?> desvincularDemandaDeViagem({
    required ViagemModel viagem,
    required String demandaId,
    required UserModel gestor,
  }) async {
    final erro = validarDesvinculoDemandaViagem(
      viagem: viagem,
      solicitante: gestor,
    );
    if (erro != null) {
      _errorMessage = erro;
      notifyListeners();
      return null;
    }

    _setLoading(true);
    try {
      final novasDemandas = List<String>.from(viagem.demandasIds)
        ..remove(demandaId);
      final novosDestinos = viagem.destinosEfetivos
          .where((d) => d.demandaId != demandaId)
          .toList();

      final atualizada = viagem.copyWith(
        demandasIds: novasDemandas,
        destinos: novosDestinos,
      );
      await _firestoreService.updateViagem(atualizada);

      await _firestoreService.addHistorico(
        demandaId,
        HistoricoModel(
          id: '',
          usuarioNome: gestor.nome,
          unidade: gestor.lotacao ?? 'CPPT',
          descricao:
              'Demanda desvinculada da viagem (Portaria ${viagem.numeroPortaria}) por ${gestor.nome}.',
          createdAt: DateTime.now(),
        ),
      );

      for (final servId in viagem.servidoresIds) {
        await _firestoreService.addNotificacao(
          NotificacaoModel(
            id: '',
            destinatarioId: servId,
            titulo: 'Demanda Desvinculada de Viagem',
            mensagem:
                'Uma demanda foi desvinculada da viagem Portaria ${viagem.numeroPortaria}.',
            tipo: 'viagem',
            referenciaId: viagem.id,
            createdAt: DateTime.now(),
          ),
        );
      }

      _errorMessage = null;
      return atualizada;
    } catch (e) {
      _errorMessage = 'Erro ao desvincular demanda da viagem: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Exclui uma viagem (apenas gestor, se não possuir demandas vinculadas).
  Future<bool> excluirViagem({
    required ViagemModel viagem,
    required UserModel gestor,
  }) async {
    final erro = validarExclusaoViagem(viagem: viagem, solicitante: gestor);
    if (erro != null) {
      _errorMessage = erro;
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      await _firestoreService.deleteViagem(viagem.id);
      await _firestoreService.addNotificacao(
        NotificacaoModel(
          id: '',
          destinatarioId: 'gestores',
          titulo: 'Viagem Excluída',
          mensagem:
              'A viagem Portaria ${viagem.numeroPortaria} (${viagem.destinoCidade}) foi excluída por ${gestor.nome}.',
          tipo: 'viagem',
          referenciaId: viagem.id,
          createdAt: DateTime.now(),
        ),
      );
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao excluir viagem: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
