import 'package:flutter/foundation.dart';

import '../models/notificacao_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';

// Controller responsável pela Gestão de Usuários (RF-004).
//
// Invariante de segurança: apenas usuários com perfil `administrador` ou
// `coordenacao` (`isGestor == true`) podem aprovar cadastros pendentes,
// definir papéis, vincular lotações e excluir contas de usuários.
class AdminController extends ChangeNotifier {
  final FirestoreService _firestoreService;

  bool _isLoading = false;
  String? _errorMessage;

  AdminController({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Verifica se o usuário solicitante possui permissão de gestor.
  static bool podeGerenciarUsuarios(UserModel solicitante) =>
      solicitante.isGestor;

  // Valida se [solicitante] pode excluir a conta [alvo]:
  // - apenas gestores podem excluir;
  // - não é permitido excluir a própria conta nem o Administrador Master.
  static String? validarExclusaoUsuario({
    required UserModel solicitante,
    required UserModel alvo,
    String? masterAdminEmail,
  }) {
    if (!solicitante.isGestor) {
      return 'Acesso negado: apenas Administrador ou Coordenação podem excluir usuários.';
    }
    if (solicitante.uid == alvo.uid) {
      return 'Você não pode excluir sua própria conta.';
    }
    if ((alvo.role == AppConstants.roleCoordenacao ||
            alvo.role == AppConstants.roleAdministrador) &&
        !solicitante.isAdmin) {
      return 'Somente um Administrador pode excluir uma conta de Coordenação ou Administrador.';
    }
    final master = (masterAdminEmail ?? AppConstants.adminMasterEmail)
        .trim()
        .toLowerCase();
    if (master.isNotEmpty && alvo.email.trim().toLowerCase() == master) {
      return 'A conta do Administrador Master não pode ser excluída.';
    }
    return null;
  }

  // Stream de todos os perfis para exibição na tela de gestão.
  Stream<List<UserModel>> streamTodosPerfis() =>
      _firestoreService.streamAllProfiles();

  // Aprova ou atualiza o papel, status ativo, lotação e (se necessário)
  // os dados cadastrais de um usuário.
  Future<bool> aprovarOuAtualizarUsuario({
    required UserModel solicitante,
    required String targetUid,
    required String role,
    required bool ativo,
    required String lotacao,
    String? nome,
    String? matricula,
    String? cargo,
  }) async {
    if (!podeGerenciarUsuarios(solicitante)) {
      _errorMessage = 'Acesso negado: apenas Administrador ou Coordenação podem gerenciar usuários.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.updateUserApproval(
        uid: targetUid,
        role: role,
        ativo: ativo,
        lotacao: lotacao,
        nome: nome,
        matricula: matricula,
        cargo: cargo,
      );
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar usuário: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Exclui o perfil de um usuário do sistema e registra notificação aos gestores.
  Future<bool> excluirUsuario({
    required UserModel solicitante,
    required UserModel alvo,
  }) async {
    final erro = validarExclusaoUsuario(solicitante: solicitante, alvo: alvo);
    if (erro != null) {
      _errorMessage = erro;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.deleteUserProfile(alvo.uid);
      await _firestoreService.addNotificacao(
        NotificacaoModel(
          id: '',
          destinatarioId: 'gestores',
          titulo: 'Conta de Usuário Excluída',
          mensagem:
              '${solicitante.nome} excluiu a conta de ${alvo.nome} (${alvo.email}).',
          tipo: 'demanda',
          referenciaId: alvo.uid,
          createdAt: DateTime.now(),
        ),
      );
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao excluir usuário: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
