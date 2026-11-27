import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';
import '../utils/constants.dart';

// Serviço responsável pela autenticação no Firebase Auth e pelo
// provisionamento inicial do perfil do usuário na coleção `profiles`.
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  bool _googleSignInInitialized = false;

  // Construtor com injeção opcional para facilitar testes.
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  // Stream do estado de autenticação do Firebase Auth.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuário autenticado atualmente, se houver.
  User? get currentUser => _auth.currentUser;

  // Constrói o perfil inicial de um usuário recém-autenticado.
  //
  // Regra de bootstrap: se [email] coincidir com [masterAdminEmail]
  // (`ADMIN_MASTER_EMAIL` do `.env`), o usuário nasce ativo como
  // `administrador` na lotação `CPPT`. Qualquer outro usuário nasce
  // como `pendente` e `ativo: false` aguardando aprovação.
  static UserModel buildInitialProfile({
    required String uid,
    required String email,
    required String masterAdminEmail,
    String? nome,
    String? matricula,
    String? cargo,
    String? fotoUrl,
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    final isMasterAdmin =
        masterAdminEmail.isNotEmpty && normalizedEmail == masterAdminEmail;

    // Se o usuário for o Master Admin, cria o perfil de administrador.
    if (isMasterAdmin) {
      return UserModel(
        uid: uid,
        nome: 'Administrador Geral SGP',
        email: normalizedEmail,
        matricula: '00001',
        cargo: 'Administrador do Sistema',
        lotacao: 'CPPT',
        role: AppConstants.roleAdministrador,
        ativo: true,
        fotoUrl: fotoUrl,
        createdAt: DateTime.now(),
      );
    }

    // Qualquer outro usuário nasce como `pendente` e `ativo: false` aguardando aprovação.
    return UserModel(
      uid: uid,
      nome: (nome != null && nome.trim().isNotEmpty)
          ? nome.trim()
          : normalizedEmail.split('@').first,
      email: normalizedEmail,
      matricula: matricula?.trim() ?? '',
      cargo: cargo?.trim() ?? '',
      lotacao: null,
      role: AppConstants.rolePendente, // pendente
      ativo: false, // inativo até aprovação
      fotoUrl: fotoUrl,
      createdAt: DateTime.now(),
    );
  }

  // Garante que o documento `profiles/{uid}` exista no Firestore.
  //
  // Caso não exista, cria usando [buildInitialProfile] e aplicando a regra
  // de provisionamento do Administrador Master.
  Future<UserModel> ensureProfileExists(
    User firebaseUser, {
    String? nome,
    String? matricula,
    String? cargo,
  }) async {
    final docRef = _firestore
        .collection(AppConstants.colProfiles)
        .doc(firebaseUser.uid);
    final docSnap = await docRef.get();

    if (docSnap.exists && docSnap.data() != null) {
      return UserModel.fromMap(docSnap.data()!, documentId: docSnap.id);
    }

    final initialProfile = buildInitialProfile(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      masterAdminEmail: AppConstants.adminMasterEmail,
      nome: nome ?? firebaseUser.displayName,
      matricula: matricula,
      cargo: cargo,
      fotoUrl: firebaseUser.photoURL,
    );

    await docRef.set(initialProfile.toMap());
    return initialProfile;
  }

  // Autentica usuário com e-mail e senha e garante a existência do perfil.
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Não foi possível obter os dados do usuário autenticado.',
      );
    }
    return ensureProfileExists(user);
  }

  // Cadastra novo usuário com e-mail/senha e cria seu perfil inicial no Firestore.
  Future<UserModel> registerWithEmailAndPassword({
    required String nome,
    required String email,
    required String matricula,
    required String cargo,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'operation-not-allowed',
        message: 'Não foi possível criar o usuário.',
      );
    }
    await user.updateDisplayName(nome.trim());

    // Grava explicitamente o perfil completo para evitar corrida com o listener authStateChanges.
    final profile = buildInitialProfile(
      uid: user.uid,
      email: user.email ?? email,
      masterAdminEmail: AppConstants.adminMasterEmail,
      nome: nome,
      matricula: matricula,
      cargo: cargo,
      fotoUrl: user.photoURL,
    );
    await _firestore
        .collection(AppConstants.colProfiles)
        .doc(user.uid)
        .set(profile.toMap());
    return profile;
  }

  // Autentica utilizando conta Google (suporte nativo Android e Flutter Web).
  Future<UserModel> signInWithGoogle() async {
    UserCredential credential;

    if (kIsWeb) {
      // Na Web, o popup nativo do Firebase Auth evita configurações extras de cliente.
      final provider = GoogleAuthProvider();
      credential = await _auth.signInWithPopup(provider);
    } else {
      // No Android, utiliza GoogleSignIn v7+ para obter o idToken e autenticar no Firebase.
      final googleSignIn = GoogleSignIn.instance;
      if (!_googleSignInInitialized) {
        await googleSignIn.initialize();
        _googleSignInInitialized = true;
      }
      final googleUser = await googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final oauthCredential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      credential = await _auth.signInWithCredential(oauthCredential);
    }

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'Falha ao autenticar com o Google.',
      );
    }
    return ensureProfileExists(user);
  }

  // Envia e-mail de redefinição de senha via Firebase Authentication (RF-002).
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // Altera a senha do usuário autenticado mediante confirmação da senha atual.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Nenhum usuário autenticado para alterar a senha.',
      );
    }

    // Reautentica o usuário antes de atualizar a senha por exigência do Firebase.
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  // Observa em tempo real o documento do perfil do usuário no Firestore.
  Stream<UserModel?> streamUserProfile(String uid) {
    return _firestore
        .collection(AppConstants.colProfiles)
        .doc(uid)
        .snapshots()
        .map((snap) {
          if (!snap.exists || snap.data() == null) return null;
          return UserModel.fromMap(snap.data()!, documentId: snap.id);
        });
  }

  // Busca pontual do perfil do usuário no Firestore.
  Future<UserModel?> getUserProfile(String uid) async {
    final snap = await _firestore
        .collection(AppConstants.colProfiles)
        .doc(uid)
        .get();
    if (!snap.exists || snap.data() == null) return null;
    return UserModel.fromMap(snap.data()!, documentId: snap.id);
  }

  // Encerra a sessão atual no Firebase Auth (e Google Sign-In no Android).
  Future<void> signOut() async {
    if (!kIsWeb && _googleSignInInitialized) {
      await GoogleSignIn.instance.signOut();
    }
    await _auth.signOut();
  }
}
