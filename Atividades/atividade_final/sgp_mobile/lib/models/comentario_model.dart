import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_model.dart';

// Modelo que representa um comentário na subcoleção `demandas/{id}/comentarios`.
class ComentarioModel {
  // Identificador do comentário no Firestore.
  final String id;

  // UID do usuário que criou o comentário.
  final String autorId;

  // Nome de exibição do autor no momento da postagem.
  final String autorNome;

  // Conteúdo textual do comentário.
  final String texto;

  // Data e hora de criação.
  final DateTime createdAt;

  // Data e hora da última edição, caso tenha sido editado.
  final DateTime? updatedAt;

  // Construtor principal do modelo de comentário.
  const ComentarioModel({
    required this.id,
    required this.autorId,
    required this.autorNome,
    required this.texto,
    required this.createdAt,
    this.updatedAt,
  });

  // Regra de negócio RF-011: apenas o autor ou um gestor (`coordenacao` /
  // `administrador`) aprovado pode editar ou excluir este comentário.
  bool podeEditarOuExcluir(UserModel usuario) {
    if (!usuario.isAprovado) return false;
    return usuario.uid == autorId || usuario.isGestor;
  }

  // Constrói um [ComentarioModel] a partir de um mapa do Firestore ou JSON.
  factory ComentarioModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    DateTime parseDate(dynamic value, {DateTime? fallback}) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value) ?? (fallback ?? DateTime.now());
      }
      return fallback ?? DateTime.now();
    }

    return ComentarioModel(
      id: (map['id'] as String?) ?? documentId ?? '',
      autorId: (map['autorId'] as String?) ?? '',
      autorNome: (map['autorNome'] as String?) ?? '',
      texto: (map['texto'] as String?) ?? '',
      createdAt: parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
    );
  }

  // Converte a instância para mapa compatível com o Cloud Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'autorId': autorId,
      'autorNome': autorNome,
      'texto': texto,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
