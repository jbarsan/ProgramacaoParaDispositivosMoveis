import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo que representa o histórico de movimentção da demanda.
// Registra automaticamente criação, pausa com justificativa, retomada,
// conclusão, inclusão de comentário e agendamento de viagem (RF-012).
class HistoricoModel {
  // Identificador do evento no Firestore.
  final String id;

  // Nome do usuário responsável pela ação.
  final String usuarioNome;

  // Lotação/unidade do usuário no momento da ação.
  final String unidade;

  // Descrição legível do evento ocorrido.
  final String descricao;

  // Data e hora em que o evento foi registrado.
  final DateTime createdAt;

  // Construtor principal do modelo de histórico.
  const HistoricoModel({
    required this.id,
    required this.usuarioNome,
    required this.unidade,
    required this.descricao,
    required this.createdAt,
  });

  // Constrói um [HistoricoModel] a partir de um mapa do Firestore ou JSON.
  factory HistoricoModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
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

    return HistoricoModel(
      id: (map['id'] as String?) ?? documentId ?? '',
      usuarioNome: (map['usuarioNome'] as String?) ?? '',
      unidade: (map['unidade'] as String?) ?? '',
      descricao: (map['descricao'] as String?) ?? '',
      createdAt: parsedDate,
    );
  }

  // Converte a instância para mapa compatível com o Cloud Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuarioNome': usuarioNome,
      'unidade': unidade,
      'descricao': descricao,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
