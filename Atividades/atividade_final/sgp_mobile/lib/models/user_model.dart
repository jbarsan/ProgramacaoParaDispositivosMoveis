import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo que representa o perfil de um usuário/servidor na coleção `profiles`.
//
// Controla o papel (`role`), o status de aprovação (`ativo`) e a lotação
// atribuída pela Coordenação ou pelo Administrador Master.
class UserModel {
  // Identificador único do usuário no Firebase Authentication.
  final String uid;

  // Nome completo do servidor.
  final String nome;

  // E-mail institucional ou de login.
  final String email;

  // Matrícula funcional do servidor no MPPI.
  final String matricula;

  // Cargo ocupado pelo servidor (ex.: Perito Engenheiro, Psicólogo).
  final String cargo;

  // Lotação/Assessoria atribuída na aprovação (ex.: CPPT, ENG, PSI).
  final String? lotacao;

  // Papel no sistema: `pendente`, `servidor`, `coordenacao` ou `administrador`.
  final String role;

  // Indica se o acesso às funcionalidades operacionais está liberado.
  final bool ativo;

  // URL pública da foto de perfil armazenada no Firebase Storage.
  final String? fotoUrl;

  // Data e hora de criação do cadastro.
  final DateTime createdAt;

  // Construtor principal do modelo de usuário.
  const UserModel({
    required this.uid,
    required this.nome,
    required this.email,
    required this.matricula,
    required this.cargo,
    this.lotacao,
    required this.role,
    required this.ativo,
    this.fotoUrl,
    required this.createdAt,
  });

  // Retorna `true` se o usuário já foi aprovado e não possui papel `pendente`.
  bool get isAprovado => ativo && role != 'pendente';

  // Retorna `true` se o usuário possui privilégios de gestão (`administrador` ou `coordenacao`).
  bool get isGestor =>
      isAprovado && (role == 'administrador' || role == 'coordenacao');

  // Retorna `true` se o usuário é o Administrador Master.
  bool get isAdmin => isAprovado && role == 'administrador';

  // Constrói um [UserModel] a partir de um mapa vindo do Firestore ou JSON.
  factory UserModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    final rawCreatedAt = map['createdAt'];
    DateTime parsedDate;
    if (rawCreatedAt is Timestamp) {
      parsedDate = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      parsedDate = rawCreatedAt;
    } else if (rawCreatedAt is String) {
      parsedDate = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return UserModel(
      uid: (map['uid'] as String?) ?? documentId ?? '',
      nome: (map['nome'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      matricula: (map['matricula'] as String?) ?? '',
      cargo: (map['cargo'] as String?) ?? '',
      lotacao: map['lotacao'] as String?,
      role: (map['role'] as String?) ?? 'pendente',
      ativo: (map['ativo'] as bool?) ?? false,
      fotoUrl: map['fotoUrl'] as String?,
      createdAt: parsedDate,
    );
  }

  // Converte a instância para mapa compatível com o Cloud Firestore.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nome': nome,
      'email': email,
      'matricula': matricula,
      'cargo': cargo,
      'lotacao': lotacao,
      'role': role,
      'ativo': ativo,
      'fotoUrl': fotoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Retorna uma cópia imutável do usuário com os campos informados atualizados.
  UserModel copyWith({
    String? uid,
    String? nome,
    String? email,
    String? matricula,
    String? cargo,
    String? lotacao,
    String? role,
    bool? ativo,
    String? fotoUrl,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      matricula: matricula ?? this.matricula,
      cargo: cargo ?? this.cargo,
      lotacao: lotacao ?? this.lotacao,
      role: role ?? this.role,
      ativo: ativo ?? this.ativo,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
