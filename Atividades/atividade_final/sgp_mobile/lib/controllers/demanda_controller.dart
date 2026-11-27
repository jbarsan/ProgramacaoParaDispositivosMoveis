import 'package:flutter/foundation.dart';

import '../models/comentario_model.dart';
import '../models/demanda_model.dart';
import '../models/historico_model.dart';
import '../models/notificacao_model.dart';
import '../models/user_model.dart';
import '../models/viagem_model.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';

// Controller responsável pelas regras de negócio das Demandas Periciais.
//
// Invariantes garantidas:
// - Bloqueia pausa sem justificativa preenchida (RF-010).
// - Registra automaticamente evento na subcoleção `historico` (RF-012).
// - Valida regras de exclusão, vínculo/desvínculo e envia notificações.
class DemandaController extends ChangeNotifier {
  final FirestoreService _firestoreService;

  bool _isLoading = false;
  String? _errorMessage;

  DemandaController({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Valida se a justificativa de pausa foi informada (RF-010).
  static String? validarJustificativaPausa(String? justificativa) {
    if (justificativa == null || justificativa.trim().isEmpty) {
      return 'A justificativa é obrigatória para pausar uma demanda.';
    }
    if (justificativa.trim().length < 5) {
      return 'Informe uma justificativa com pelo menos 5 caracteres.';
    }
    return null;
  }

  // Valida se um gestor pode excluir uma demanda:
  // somente quando `status == nao_iniciada` e sem viagens vinculadas.
  static String? validarExclusaoDemanda({
    required DemandaModel demanda,
    required List<ViagemModel> viagensVinculadas,
    required UserModel solicitante,
  }) {
    if (!solicitante.isGestor) {
      return 'Apenas Coordenação ou Administrador podem excluir demandas.';
    }
    if (demanda.status != AppConstants.statusNaoIniciada) {
      return 'A demanda só pode ser excluída se ainda não tiver sido iniciada.';
    }
    if (viagensVinculadas.isNotEmpty) {
      return 'Não é possível excluir uma demanda vinculada a uma viagem.';
    }
    return null;
  }

  // Valida se um servidor pode se desvincular da própria demanda:
  // permitido apenas se ela não estiver em viagem iniciada ou concluída.
  static String? validarDesvinculoProprio({
    required DemandaModel demanda,
    required List<ViagemModel> viagensVinculadas,
    required UserModel servidor,
  }) {
    if (demanda.servidorId != servidor.uid) {
      return 'Esta demanda não está vinculada ao seu usuário.';
    }
    final emViagemAtivaOuConcluida = viagensVinculadas.any(
      (v) =>
          v.situacao == AppConstants.viagemEmAndamento ||
          v.situacao == AppConstants.viagemConcluida,
    );
    if (emViagemAtivaOuConcluida) {
      return 'Não é possível desvincular-se: a demanda está em uma viagem iniciada ou concluída.';
    }
    return null;
  }

  // Stream de demandas visíveis para o [usuario] autenticado e aprovado.
  Stream<List<DemandaModel>> streamDemandas(UserModel usuario) =>
      _firestoreService.streamDemandas(usuario);

  // Stream de comentários de uma demanda.
  Stream<List<ComentarioModel>> streamComentarios(String demandaId) =>
      _firestoreService.streamComentarios(demandaId);

  // Stream da linha do tempo (histórico) de uma demanda.
  Stream<List<HistoricoModel>> streamHistorico(String demandaId) =>
      _firestoreService.streamHistorico(demandaId);

  // Lista todos os servidores aprovados para atribuição em demandas e viagens.
  Future<List<UserModel>> getServidoresAprovados() =>
      _firestoreService.getServidoresAprovados();

  // Retorna as viagens vinculadas a uma demanda específica.
  Future<List<ViagemModel>> getViagensPorDemanda(String demandaId) =>
      _firestoreService.getViagensPorDemanda(demandaId);

  // Cria uma nova demanda, registra no histórico e notifica servidor/gestores.
  Future<bool> criarDemanda({
    required DemandaModel demanda,
    required UserModel autor,
  }) async {
    _setLoading(true);
    try {
      final id = await _firestoreService.createDemanda(demanda);
      await _firestoreService.addHistorico(
        id,
        HistoricoModel(
          id: '',
          usuarioNome: autor.nome,
          unidade: autor.lotacao ?? 'CPPT',
          descricao: demanda.servidorId.isNotEmpty
              ? 'Demanda ${demanda.numeroSgp} criada e atribuída a ${demanda.servidorNome}.'
              : 'Demanda ${demanda.numeroSgp} criada e disponibilizada para o setor ${demanda.lotacao}.',
          createdAt: DateTime.now(),
        ),
      );
      if (demanda.servidorId.isNotEmpty && demanda.servidorId != autor.uid) {
        await _notificar(
          destinatarioId: demanda.servidorId,
          titulo: 'Nova Demanda Atribuída',
          mensagem:
              'Você foi vinculado à demanda ${demanda.numeroSgp} (${demanda.titulo}).',
          referenciaId: id,
        );
      }
      if (!autor.isGestor) {
        await _notificar(
          destinatarioId: 'gestores',
          titulo: 'Nova Demanda Criada por Servidor',
          mensagem:
              '${autor.nome} criou a demanda ${demanda.numeroSgp} no setor ${demanda.lotacao}.',
          referenciaId: id,
        );
      }
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao criar demanda: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Inicia uma demanda (`nao_iniciada` -> `em_andamento`) e registra no histórico.
  Future<bool> iniciarDemanda({
    required DemandaModel demanda,
    required UserModel usuario,
  }) async {
    _setLoading(true);
    try {
      final atualizada = demanda.copyWith(
        status: AppConstants.statusEmAndamento,
      );
      await _firestoreService.updateDemanda(atualizada);
      await _firestoreService.addHistorico(
        demanda.id,
        HistoricoModel(
          id: '',
          usuarioNome: usuario.nome,
          unidade: usuario.lotacao ?? 'CPPT',
          descricao: 'Demanda iniciada (Em Andamento).',
          createdAt: DateTime.now(),
        ),
      );
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao iniciar demanda: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Permite que um servidor do setor assuma uma demanda ainda sem vínculo.
  Future<bool> assumirDemanda({
    required DemandaModel demanda,
    required UserModel servidor,
  }) async {
    _setLoading(true);
    try {
      final atualizada = demanda.copyWith(
        servidorId: servidor.uid,
        servidorNome: servidor.nome,
      );
      await _firestoreService.updateDemanda(atualizada);
      await _firestoreService.addHistorico(
        demanda.id,
        HistoricoModel(
          id: '',
          usuarioNome: servidor.nome,
          unidade: servidor.lotacao ?? demanda.lotacao,
          descricao: 'Demanda assumida por ${servidor.nome}.',
          createdAt: DateTime.now(),
        ),
      );
      await _notificar(
        destinatarioId: 'gestores',
        titulo: 'Demanda Assumida',
        mensagem: '${servidor.nome} assumiu a demanda ${demanda.numeroSgp}.',
        referenciaId: demanda.id,
      );
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao assumir demanda: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Permite que o coordenador/administrador desvincule ou reatribua um servidor.
  Future<bool> alterarVinculoServidor({
    required DemandaModel demanda,
    required String novoServidorId,
    required String novoServidorNome,
    required UserModel gestor,
  }) async {
    if (!gestor.isGestor) {
      _errorMessage =
          'Apenas Coordenação ou Administrador podem alterar vínculos.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      final servidorAnteriorId = demanda.servidorId;
      final nomeEfetivo = novoServidorId.isEmpty
          ? 'Disponível para o setor'
          : novoServidorNome;

      final atualizada = demanda.copyWith(
        servidorId: novoServidorId,
        servidorNome: nomeEfetivo,
      );
      await _firestoreService.updateDemanda(atualizada);

      final desc = novoServidorId.isEmpty
          ? 'Servidor desvinculado da demanda por ${gestor.nome}. Demanda disponível para o setor.'
          : 'Demanda vinculada a $novoServidorNome por ${gestor.nome}.';

      await _firestoreService.addHistorico(
        demanda.id,
        HistoricoModel(
          id: '',
          usuarioNome: gestor.nome,
          unidade: gestor.lotacao ?? 'CPPT',
          descricao: desc,
          createdAt: DateTime.now(),
        ),
      );

      if (servidorAnteriorId.isNotEmpty &&
          servidorAnteriorId != novoServidorId) {
        await _notificar(
          destinatarioId: servidorAnteriorId,
          titulo: 'Desvinculação de Demanda',
          mensagem:
              'Você foi desvinculado da demanda ${demanda.numeroSgp} por ${gestor.nome}.',
          referenciaId: demanda.id,
        );
      }
      if (novoServidorId.isNotEmpty && novoServidorId != servidorAnteriorId) {
        await _notificar(
          destinatarioId: novoServidorId,
          titulo: 'Demanda Vinculada a Você',
          mensagem:
              'A demanda ${demanda.numeroSgp} foi vinculada a você por ${gestor.nome}.',
          referenciaId: demanda.id,
        );
      }
      await _notificar(
        destinatarioId: 'gestores',
        titulo: 'Vínculo de Demanda Alterado',
        mensagem: desc,
        referenciaId: demanda.id,
      );

      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao alterar vínculo: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Permite que o servidor se desvincule de sua própria demanda, se não estiver
  // em uma viagem iniciada ou concluída.
  Future<bool> desvincularPropriaDemanda({
    required DemandaModel demanda,
    required UserModel servidor,
  }) async {
    _setLoading(true);
    try {
      final viagens = await _firestoreService.getViagensPorDemanda(demanda.id);
      final erro = validarDesvinculoProprio(
        demanda: demanda,
        viagensVinculadas: viagens,
        servidor: servidor,
      );
      if (erro != null) {
        _errorMessage = erro;
        return false;
      }

      final atualizada = demanda.copyWith(
        servidorId: '',
        servidorNome: 'Disponível para o setor',
      );
      await _firestoreService.updateDemanda(atualizada);
      await _firestoreService.addHistorico(
        demanda.id,
        HistoricoModel(
          id: '',
          usuarioNome: servidor.nome,
          unidade: servidor.lotacao ?? demanda.lotacao,
          descricao: '${servidor.nome} desvinculou-se da demanda.',
          createdAt: DateTime.now(),
        ),
      );
      await _notificar(
        destinatarioId: 'gestores',
        titulo: 'Servidor Desvinculou-se de Demanda',
        mensagem:
            '${servidor.nome} desvinculou-se da demanda ${demanda.numeroSgp}.',
        referenciaId: demanda.id,
      );
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao desvincular demanda: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Exclui uma demanda (apenas gestor, se `nao_iniciada` e sem viagens).
  Future<bool> excluirDemanda({
    required DemandaModel demanda,
    required UserModel gestor,
  }) async {
    _setLoading(true);
    try {
      final viagens = await _firestoreService.getViagensPorDemanda(demanda.id);
      final erro = validarExclusaoDemanda(
        demanda: demanda,
        viagensVinculadas: viagens,
        solicitante: gestor,
      );
      if (erro != null) {
        _errorMessage = erro;
        return false;
      }

      await _firestoreService.deleteDemanda(demanda.id);
      await _notificar(
        destinatarioId: 'gestores',
        titulo: 'Demanda Excluída',
        mensagem:
            'A demanda ${demanda.numeroSgp} foi excluída por ${gestor.nome}.',
        referenciaId: demanda.id,
      );
      if (demanda.servidorId.isNotEmpty && demanda.servidorId != gestor.uid) {
        await _notificar(
          destinatarioId: demanda.servidorId,
          titulo: 'Demanda Excluída',
          mensagem:
              'A demanda ${demanda.numeroSgp} foi excluída por ${gestor.nome}.',
          referenciaId: demanda.id,
        );
      }
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao excluir demanda: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Pausa uma demanda em andamento exigindo justificativa obrigatória (RF-010).
  Future<bool> pausarDemanda({
    required DemandaModel demanda,
    required String justificativa,
    required UserModel usuario,
  }) async {
    final erroValidacao = validarJustificativaPausa(justificativa);
    if (erroValidacao != null) {
      _errorMessage = erroValidacao;
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      final atualizada = demanda.copyWith(
        status: AppConstants.statusPausada,
        justificativaPausa: justificativa.trim(),
      );
      await _firestoreService.updateDemanda(atualizada);
      await _firestoreService.addHistorico(
        demanda.id,
        HistoricoModel(
          id: '',
          usuarioNome: usuario.nome,
          unidade: usuario.lotacao ?? 'CPPT',
          descricao: 'Demanda pausada. Justificativa: ${justificativa.trim()}',
          createdAt: DateTime.now(),
        ),
      );
      await _notificar(
        destinatarioId: 'gestores',
        titulo: 'Demanda Pausada',
        mensagem:
            '${usuario.nome} pausou ${demanda.numeroSgp}: ${justificativa.trim()}',
        referenciaId: demanda.id,
      );
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao pausar demanda: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Retoma uma demanda pausada para `em_andamento` e registra no histórico.
  Future<bool> despausarDemanda({
    required DemandaModel demanda,
    required UserModel usuario,
  }) async {
    _setLoading(true);
    try {
      final atualizada = demanda.copyWith(
        status: AppConstants.statusEmAndamento,
        clearJustificativa: true,
      );
      await _firestoreService.updateDemanda(atualizada);
      await _firestoreService.addHistorico(
        demanda.id,
        HistoricoModel(
          id: '',
          usuarioNome: usuario.nome,
          unidade: usuario.lotacao ?? 'CPPT',
          descricao: 'Demanda retomada para Em Andamento.',
          createdAt: DateTime.now(),
        ),
      );
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao retomar demanda: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Marca uma demanda como concluída e registra no histórico.
  Future<bool> concluirDemanda({
    required DemandaModel demanda,
    required UserModel usuario,
  }) async {
    _setLoading(true);
    try {
      final atualizada = demanda.copyWith(
        status: AppConstants.statusConcluida,
        clearJustificativa: true,
      );
      await _firestoreService.updateDemanda(atualizada);
      await _firestoreService.addHistorico(
        demanda.id,
        HistoricoModel(
          id: '',
          usuarioNome: usuario.nome,
          unidade: usuario.lotacao ?? 'CPPT',
          descricao: 'Demanda concluída.',
          createdAt: DateTime.now(),
        ),
      );
      await _notificar(
        destinatarioId: 'gestores',
        titulo: 'Demanda Concluída',
        mensagem: '${usuario.nome} concluiu a demanda ${demanda.numeroSgp}.',
        referenciaId: demanda.id,
      );
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao concluir demanda: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Adiciona um comentário na demanda e registra o evento no histórico (RF-011/012).
  Future<bool> adicionarComentario({
    required String demandaId,
    required String texto,
    required UserModel autor,
  }) async {
    if (texto.trim().isEmpty) {
      _errorMessage = 'O comentário não pode estar vazio.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      await _firestoreService.addComentario(
        demandaId,
        ComentarioModel(
          id: '',
          autorId: autor.uid,
          autorNome: autor.nome,
          texto: texto.trim(),
          createdAt: DateTime.now(),
        ),
      );
      await _firestoreService.addHistorico(
        demandaId,
        HistoricoModel(
          id: '',
          usuarioNome: autor.nome,
          unidade: autor.lotacao ?? 'CPPT',
          descricao: 'Comentário adicionado: "${texto.trim()}"',
          createdAt: DateTime.now(),
        ),
      );
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao adicionar comentário: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Edita um comentário existente respeitando a regra de autoria/gestão (RF-011).
  Future<bool> editarComentario({
    required String demandaId,
    required ComentarioModel comentario,
    required String novoTexto,
    required UserModel usuario,
  }) async {
    if (!comentario.podeEditarOuExcluir(usuario)) {
      _errorMessage = 'Sem permissão para editar este comentário.';
      notifyListeners();
      return false;
    }
    if (novoTexto.trim().isEmpty) {
      _errorMessage = 'O comentário não pode ficar vazio.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      await _firestoreService.updateComentario(
        demandaId: demandaId,
        comentarioId: comentario.id,
        novoTexto: novoTexto,
      );
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao editar comentário: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Exclui um comentário respeitando a regra de autoria/gestão (RF-011).
  Future<bool> excluirComentario({
    required String demandaId,
    required ComentarioModel comentario,
    required UserModel usuario,
  }) async {
    if (!comentario.podeEditarOuExcluir(usuario)) {
      _errorMessage = 'Sem permissão para excluir este comentário.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      await _firestoreService.deleteComentario(
        demandaId: demandaId,
        comentarioId: comentario.id,
      );
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao excluir comentário: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _notificar({
    required String destinatarioId,
    required String titulo,
    required String mensagem,
    required String referenciaId,
  }) async {
    await _firestoreService.addNotificacao(
      NotificacaoModel(
        id: '',
        destinatarioId: destinatarioId,
        titulo: titulo,
        mensagem: mensagem,
        tipo: 'demanda',
        referenciaId: referenciaId,
        createdAt: DateTime.now(),
      ),
    );
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
