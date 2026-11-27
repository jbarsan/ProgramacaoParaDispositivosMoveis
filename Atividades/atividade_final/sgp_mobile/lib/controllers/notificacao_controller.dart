import 'package:flutter/foundation.dart';

import '../models/notificacao_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

// Controller responsável pelo stream de notificações in-app e marcação de leitura.
class NotificacaoController extends ChangeNotifier {
  final FirestoreService _firestoreService;

  NotificacaoController({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  // Stream de notificações visíveis para o [usuario] atual.
  Stream<List<NotificacaoModel>> streamNotificacoes(UserModel usuario) =>
      _firestoreService.streamNotificacoes(usuario);

  // Marca uma notificação específica como lida pelo usuário [uid].
  Future<void> marcarComoLida(String notificacaoId, String uid) async {
    await _firestoreService.marcarNotificacaoLida(
      notificacaoId: notificacaoId,
      uid: uid,
    );
  }
}
