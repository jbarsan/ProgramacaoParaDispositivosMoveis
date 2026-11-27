import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

// Controller responsável pelo estado de autenticação, perfil atual e
// edição dos dados pessoais do servidor logado.
class AuthController extends ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<UserModel?>? _profileSub;

  // Construtor com injeção de serviços para manter desacoplamento.
  AuthController({AuthService? authService, FirestoreService? firestoreService})
    : _authService = authService ?? AuthService(),
      _firestoreService = firestoreService ?? FirestoreService();

  // Perfil completo do usuário logado no Firestore.
  UserModel? get currentUser => _currentUser;

  // Indica se há uma operação assíncrona em andamento.
  bool get isLoading => _isLoading;

  // Última mensagem de erro amigável ocorrida.
  String? get errorMessage => _errorMessage;

  // Inicia o monitoramento reativo do Firebase Auth e do documento `profiles/{uid}`.
  void startListening() {
    _authSub?.cancel();
    _authSub = _authService.authStateChanges.listen((firebaseUser) {
      _profileSub?.cancel();
      if (firebaseUser == null) {
        _currentUser = null;
        notifyListeners();
        return;
      }

      // Garante provisionamento caso o usuário já tenha sessão ativa no navegador/device.
      _authService
          .ensureProfileExists(firebaseUser)
          .then((_) {
            _profileSub = _authService
                .streamUserProfile(firebaseUser.uid)
                .listen((profile) {
                  _currentUser = profile;
                  notifyListeners();
                });
          })
          .catchError((Object e) {
            _errorMessage = e.toString();
            notifyListeners();
          });
    });
  }

  // Força recarregamento pontual do perfil (usado na tela Aguardando Aprovação).
  Future<void> refreshProfile() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser == null) return;
    _setLoading(true);
    try {
      _currentUser = await _authService.getUserProfile(firebaseUser.uid);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar status: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Realiza login com e-mail e senha.
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    try {
      _currentUser = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _errorMessage = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e.code);
      return false;
    } on FirebaseException catch (e) {
      _errorMessage = _mapFirebaseError(e);
      return false;
    } catch (e) {
      _errorMessage = 'Erro inesperado ao entrar: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cadastra um novo servidor (sempre nasce com `role: pendente` e `ativo: false`).
  Future<bool> register({
    required String nome,
    required String email,
    required String matricula,
    required String cargo,
    required String password,
  }) async {
    _setLoading(true);
    try {
      _currentUser = await _authService.registerWithEmailAndPassword(
        nome: nome,
        email: email,
        matricula: matricula,
        cargo: cargo,
        password: password,
      );
      _errorMessage = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e.code);
      return false;
    } catch (e) {
      _errorMessage = 'Erro inesperado ao cadastrar: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Realiza login social com conta Google.
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      _currentUser = await _authService.signInWithGoogle();
      _errorMessage = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e.code);
      return false;
    } catch (e) {
      _errorMessage = 'Não foi possível concluir o login com Google: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Envia e-mail de recuperação de senha.
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _authService.sendPasswordResetEmail(email);
      _errorMessage = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e.code);
      return false;
    } catch (e) {
      _errorMessage = 'Erro ao enviar e-mail de recuperação: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Atualiza dados pessoais do servidor logado e o avatar selecionado em `assets/images`.
  Future<bool> updateOwnProfile({
    required String nome,
    required String matricula,
    required String cargo,
    String? novaFotoAsset,
  }) async {
    final user = _currentUser;
    if (user == null) return false;
    _setLoading(true);
    try {
      await _firestoreService.updateOwnProfile(
        uid: user.uid,
        nome: nome,
        matricula: matricula,
        cargo: cargo,
        fotoUrl: novaFotoAsset,
      );
      _currentUser = user.copyWith(
        nome: nome.trim(),
        matricula: matricula.trim(),
        cargo: cargo.trim(),
        fotoUrl: novaFotoAsset ?? user.fotoUrl,
      );
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar perfil: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Altera a senha do usuário autenticado mediante confirmação da senha atual.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _errorMessage = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e.code);
      return false;
    } catch (e) {
      _errorMessage = 'Erro ao alterar senha: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Encerra a sessão do usuário atual.
  Future<void> signOut() async {
    _profileSub?.cancel();
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _mapFirebaseError(FirebaseException e) {
    if (e.code == 'unavailable') {
      return 'Não foi possível conectar ao Cloud Firestore (unavailable). '
          'Verifique se o banco Firestore (default) foi criado no Firebase Console '
          'e se não há bloqueio de rede/extensão (AdBlock) para firestore.googleapis.com.';
    }
    return 'Erro no serviço Firebase (${e.code}): ${e.message ?? ""}';
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'O e-mail informado é inválido.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado no sistema.';
      case 'weak-password':
        return 'A senha deve possuir ao menos 6 caracteres.';
      default:
        return 'Erro de autenticação ($code).';
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
