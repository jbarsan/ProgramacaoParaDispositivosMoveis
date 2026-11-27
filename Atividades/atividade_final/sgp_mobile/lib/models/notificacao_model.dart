import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo que representa uma notificação in-app na coleção `notificacoes`.
//
// Suporta envio direcionado a um servidor específico (`destinatarioId == uid`)
// ou a todos os gestores (`destinatarioId == 'gestores'`), controlando a
// leitura individual por meio da lista [lidaPor].
class NotificacaoModel {
  // Identificador do documento no Firestore.
  final String id;

  // UID do destinatário ou `'gestores'` para Coordenação e Administração.
  final String destinatarioId;

  // Título resumido da notificação.
  final String titulo;

  // Mensagem detalhada do evento ocorrido.
  final String mensagem;

  // Categoria do evento: `'demanda'` ou `'viagem'`.
  final String tipo;

  // ID do documento relacionado (demanda ou viagem).
  final String referenciaId;

  // Lista de UIDs dos usuários que já visualizaram/marcaram como lida.
  final List<String> lidaPor;

  // Data e hora de criação da notificação.
  final DateTime createdAt;

  // Construtor principal do modelo de notificação.
  const NotificacaoModel({
    required this.id,
    required this.destinatarioId,
    required this.titulo,
    required this.mensagem,
    required this.tipo,
    required this.referenciaId,
    this.lidaPor = const [],
    required this.createdAt,
  });

  // Indica se o usuário [uid] já leu esta notificação.
  bool foiLidaPor(String uid) => lidaPor.contains(uid);

  // Constrói um [NotificacaoModel] a partir de um mapa do Firestore ou JSON.
  factory NotificacaoModel.fromMap(
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

    final rawLidaPor = map['lidaPor'];
    final parsedLidaPor = rawLidaPor is Iterable
        ? rawLidaPor.map((e) => e.toString()).toList()
        : <String>[];

    return NotificacaoModel(
      id: (map['id'] as String?) ?? documentId ?? '',
      destinatarioId: (map['destinatarioId'] as String?) ?? '',
      titulo: (map['titulo'] as String?) ?? '',
      mensagem: (map['mensagem'] as String?) ?? '',
      tipo: (map['tipo'] as String?) ?? 'demanda',
      referenciaId: (map['referenciaId'] as String?) ?? '',
      lidaPor: parsedLidaPor,
      createdAt: parsedDate,
    );
  }

  // Converte a instância para mapa compatível com o Cloud Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'destinatarioId': destinatarioId,
      'titulo': titulo,
      'mensagem': mensagem,
      'tipo': tipo,
      'referenciaId': referenciaId,
      'lidaPor': lidaPor,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
