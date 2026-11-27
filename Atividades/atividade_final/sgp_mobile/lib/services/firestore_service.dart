import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../models/comentario_model.dart';
import '../models/demanda_model.dart';
import '../models/historico_model.dart';
import '../models/notificacao_model.dart';
import '../models/user_model.dart';
import '../models/viagem_model.dart';
import '../utils/constants.dart';

// Serviço centralizado de comunicação com o Cloud Firestore.
//
// Isola todas as queries, streams e escritas das coleções `profiles`,
// `demandas` (com subcoleções `comentarios` e `historico`) e `viagens`.
class FirestoreService {
  final FirebaseFirestore _firestore;

  // Construtor com injeção opcional para facilitar testes.
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // ===========================================================================
  // PERFIS DE USUÁRIOS (profiles)
  // ===========================================================================

  // Observa todos os perfis cadastrados (uso exclusivo de gestores).
  Stream<List<UserModel>> streamAllProfiles() {
    return _firestore
        .collection(AppConstants.colProfiles)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => UserModel.fromMap(doc.data(), documentId: doc.id))
              .toList(),
        );
  }

  // Lista todos os servidores aprovados para atribuição de demandas.
  Future<List<UserModel>> getServidoresAprovados() async {
    final snap = await _firestore
        .collection(AppConstants.colProfiles)
        .where('ativo', isEqualTo: true)
        .get();
    return snap.docs
        .map((doc) => UserModel.fromMap(doc.data(), documentId: doc.id))
        .toList();
  }

  // Atualiza papel, status de aprovação, lotação e (se necessário) dados cadastrais (RF-004).
  Future<void> updateUserApproval({
    required String uid,
    required String role,
    required bool ativo,
    required String lotacao,
    String? nome,
    String? matricula,
    String? cargo,
  }) async {
    final data = <String, dynamic>{
      'role': role,
      'ativo': ativo,
      'lotacao': lotacao,
    };
    if (nome != null) data['nome'] = nome.trim();
    if (matricula != null) data['matricula'] = matricula.trim();
    if (cargo != null) data['cargo'] = cargo.trim();

    await _firestore.collection(AppConstants.colProfiles).doc(uid).update(data);
  }

  /// Exclui o documento de perfil do usuário na coleção `profiles`.
  Future<void> deleteUserProfile(String uid) async {
    await _firestore.collection(AppConstants.colProfiles).doc(uid).delete();
  }

  // Atualiza apenas dados pessoais permitidos ao próprio servidor.
  Future<void> updateOwnProfile({
    required String uid,
    required String nome,
    required String matricula,
    required String cargo,
    String? fotoUrl,
  }) async {
    final data = <String, dynamic>{
      'nome': nome.trim(),
      'matricula': matricula.trim(),
      'cargo': cargo.trim(),
    };
    if (fotoUrl != null) {
      data['fotoUrl'] = fotoUrl;
    }
    await _firestore.collection(AppConstants.colProfiles).doc(uid).update(data);
  }

  // ===========================================================================
  // DEMANDAS E SUBCOLEÇÕES (demandas / comentarios / historico)
  // ===========================================================================

  // Observa demandas em tempo real.
  //
  // Gestores visualizam todas as demandas; servidores visualizam as demandas
  // vinculadas ao seu `uid` ou à sua `lotacao`.
  Stream<List<DemandaModel>> streamDemandas(UserModel usuario) {
    Query<Map<String, dynamic>> query = _firestore.collection(
      AppConstants.colDemandas,
    );

    if (!usuario.isGestor) {
      // Filtra por servidorId; demandas da mesma lotação também são filtradas em memória
      // se necessário para evitar índices compostos complexos no Firestore.
      query = query.orderBy('dataRecebimento', descending: true);
      return query.snapshots().map((snap) {
        return snap.docs
            .map((doc) => DemandaModel.fromMap(doc.data(), documentId: doc.id))
            .where(
              (d) =>
                  d.servidorId == usuario.uid ||
                  (usuario.lotacao != null && d.lotacao == usuario.lotacao),
            )
            .toList();
      });
    }

    return query
        .orderBy('dataRecebimento', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => DemandaModel.fromMap(doc.data(), documentId: doc.id),
              )
              .toList(),
        );
  }

  // Cria uma nova demanda e retorna o ID gerado.
  Future<String> createDemanda(DemandaModel demanda) async {
    final docRef = _firestore.collection(AppConstants.colDemandas).doc();
    final novaDemanda = demanda.copyWith(id: docRef.id);
    await docRef.set(novaDemanda.toMap());
    return docRef.id;
  }

  // Atualiza os campos de uma demanda existente.
  Future<void> updateDemanda(DemandaModel demanda) async {
    await _firestore
        .collection(AppConstants.colDemandas)
        .doc(demanda.id)
        .update(demanda.toMap());
  }

  /// Exclui uma demanda e suas subcoleções (`comentarios` e `historico`).
  Future<void> deleteDemanda(String demandaId) async {
    final docRef = _firestore.collection(AppConstants.colDemandas).doc(demandaId);
    final comentarios = await docRef.collection(AppConstants.colComentarios).get();
    for (final c in comentarios.docs) {
      await c.reference.delete();
    }
    final historico = await docRef.collection(AppConstants.colHistorico).get();
    for (final h in historico.docs) {
      await h.reference.delete();
    }
    await docRef.delete();
  }

  // Observa comentários de uma demanda em ordem cronológica crescente.
  Stream<List<ComentarioModel>> streamComentarios(String demandaId) {
    return _firestore
        .collection(AppConstants.colDemandas)
        .doc(demandaId)
        .collection(AppConstants.colComentarios)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) =>
                    ComentarioModel.fromMap(doc.data(), documentId: doc.id),
              )
              .toList(),
        );
  }

  // Adiciona um novo comentário na subcoleção `comentarios`.
  Future<void> addComentario(
    String demandaId,
    ComentarioModel comentario,
  ) async {
    final docRef = _firestore
        .collection(AppConstants.colDemandas)
        .doc(demandaId)
        .collection(AppConstants.colComentarios)
        .doc();
    await docRef.set(
      ComentarioModel(
        id: docRef.id,
        autorId: comentario.autorId,
        autorNome: comentario.autorNome,
        texto: comentario.texto,
        createdAt: comentario.createdAt,
      ).toMap(),
    );
  }

  // Atualiza o texto de um comentário existente.
  Future<void> updateComentario({
    required String demandaId,
    required String comentarioId,
    required String novoTexto,
  }) async {
    await _firestore
        .collection(AppConstants.colDemandas)
        .doc(demandaId)
        .collection(AppConstants.colComentarios)
        .doc(comentarioId)
        .update({
          'texto': novoTexto.trim(),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
  }

  // Exclui um comentário da subcoleção `comentarios`.
  Future<void> deleteComentario({
    required String demandaId,
    required String comentarioId,
  }) async {
    await _firestore
        .collection(AppConstants.colDemandas)
        .doc(demandaId)
        .collection(AppConstants.colComentarios)
        .doc(comentarioId)
        .delete();
  }

  // Observa a linha do tempo de uma demanda em ordem cronológica reversa (RF-012).
  Stream<List<HistoricoModel>> streamHistorico(String demandaId) {
    return _firestore
        .collection(AppConstants.colDemandas)
        .doc(demandaId)
        .collection(AppConstants.colHistorico)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => HistoricoModel.fromMap(doc.data(), documentId: doc.id),
              )
              .toList(),
        );
  }

  // Registra um novo evento imutável na subcoleção `historico`.
  Future<void> addHistorico(String demandaId, HistoricoModel evento) async {
    final docRef = _firestore
        .collection(AppConstants.colDemandas)
        .doc(demandaId)
        .collection(AppConstants.colHistorico)
        .doc();
    await docRef.set(
      HistoricoModel(
        id: docRef.id,
        usuarioNome: evento.usuarioNome,
        unidade: evento.unidade,
        descricao: evento.descricao,
        createdAt: evento.createdAt,
      ).toMap(),
    );
  }

  // ===========================================================================
  // VIAGENS (viagens)
  // ===========================================================================

  // Observa viagens em tempo real conforme o perfil do usuário.
  Stream<List<ViagemModel>> streamViagens(UserModel usuario) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(AppConstants.colViagens)
        .orderBy('dataIda', descending: true);

    if (!usuario.isGestor) {
      return query.snapshots().map(
        (snap) => snap.docs
            .map((doc) => ViagemModel.fromMap(doc.data(), documentId: doc.id))
            .where((v) =>
                v.servidorId == usuario.uid ||
                v.servidoresIds.contains(usuario.uid))
            .toList(),
      );
    }

    return query.snapshots().map(
      (snap) => snap.docs
          .map((doc) => ViagemModel.fromMap(doc.data(), documentId: doc.id))
          .toList(),
    );
  }

  // Cria uma nova viagem e retorna o ID gerado.
  Future<String> createViagem(ViagemModel viagem) async {
    final docRef = _firestore.collection(AppConstants.colViagens).doc();
    final novaViagem = viagem.copyWith(id: docRef.id);
    await docRef.set(novaViagem.toMap());
    return docRef.id;
  }

  // Atualiza uma viagem existente.
  Future<void> updateViagem(ViagemModel viagem) async {
    await _firestore
        .collection(AppConstants.colViagens)
        .doc(viagem.id)
        .update(viagem.toMap());
  }

  /// Exclui uma viagem existente.
  Future<void> deleteViagem(String viagemId) async {
    await _firestore
        .collection(AppConstants.colViagens)
        .doc(viagemId)
        .delete();
  }

  /// Busca todas as viagens que possuem a demanda [demandaId] vinculada.
  Future<List<ViagemModel>> getViagensPorDemanda(String demandaId) async {
    final snap = await _firestore
        .collection(AppConstants.colViagens)
        .where('demandasIds', arrayContains: demandaId)
        .get();
    return snap.docs
        .map((doc) => ViagemModel.fromMap(doc.data(), documentId: doc.id))
        .toList();
  }

  // ===========================================================================
  // NOTIFICAÇÕES IN-APP (notificacoes)
  // ===========================================================================

  /// Observa notificações destinadas ao [usuario] (diretas ou para `'gestores'`).
  Stream<List<NotificacaoModel>> streamNotificacoes(UserModel usuario) {
    return _firestore
        .collection(AppConstants.colNotificacoes)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => NotificacaoModel.fromMap(
                  doc.data(),
                  documentId: doc.id,
                ),
              )
              .where(
                (n) =>
                    n.destinatarioId == usuario.uid ||
                    (usuario.isGestor && n.destinatarioId == 'gestores'),
              )
              .toList(),
        );
  }

  /// Registra uma nova notificação no Firestore.
  ///
  /// Falhas de permissão na coleção `notificacoes` (ex.: regras ainda não
  /// publicadas no Console) são registradas no log sem interromper a ação principal.
  Future<void> addNotificacao(NotificacaoModel notificacao) async {
    try {
      final docRef = _firestore.collection(AppConstants.colNotificacoes).doc();
      await docRef.set(
        NotificacaoModel(
          id: docRef.id,
          destinatarioId: notificacao.destinatarioId,
          titulo: notificacao.titulo,
          mensagem: notificacao.mensagem,
          tipo: notificacao.tipo,
          referenciaId: notificacao.referenciaId,
          lidaPor: notificacao.lidaPor,
          createdAt: notificacao.createdAt,
        ).toMap(),
      );
    } catch (e) {
      debugPrint('Aviso ao registrar notificação: $e');
    }
  }

  /// Marca uma notificação como lida para o usuário [uid].
  Future<void> marcarNotificacaoLida({
    required String notificacaoId,
    required String uid,
  }) async {
    await _firestore
        .collection(AppConstants.colNotificacoes)
        .doc(notificacaoId)
        .update({
      'lidaPor': FieldValue.arrayUnion([uid]),
    });
  }
}
