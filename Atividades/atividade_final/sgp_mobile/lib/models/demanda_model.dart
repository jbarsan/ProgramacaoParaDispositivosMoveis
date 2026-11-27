import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo que representa uma demanda pericial na coleção `demandas`.
class DemandaModel {
  // Identificador do documento no Firestore.
  final String id;

  // Número identificador no SGP (ex.: `0042/2026 - ENG`).
  final String numeroSgp;

  // Título resumido da demanda pericial.
  final String titulo;

  // Descrição detalhada do objeto da perícia.
  final String descricao;

  // Promotoria ou unidade solicitante.
  final String unidadeSolicitante;

  // Número do processo no sistema SEI.
  final String numeroSei;

  // Status atual: `em_andamento`, `pausada` ou `concluida`.
  final String status;

  // Prioridade da demanda: `alta`, `normal` ou `baixa`.
  final String prioridade;

  // Justificativa obrigatória quando a demanda está com status `pausada`.
  final String? justificativaPausa;

  // UID do servidor/perito responsável pela demanda.
  final String servidorId;

  // Nome do servidor/perito responsável.
  final String servidorNome;

  // Lotação/Assessoria vinculada à demanda.
  final String lotacao;

  // Município onde a diligência/perícia será realizada.
  final String municipio;

  // Endereço completo formatado do local da perícia.
  final String endereco;

  // Logradouro (rua, avenida, etc.).
  final String logradouro;

  // Número do imóvel (opcional).
  final String? numero;

  // Complemento do endereço (opcional).
  final String? complemento;

  // Bairro do local da perícia.
  final String bairro;

  // Sigla do Estado (UF).
  final String estado;

  // CEP no formato `00000-000`.
  final String cep;

  // Latitude geográfica para plotagem no Google Maps.
  final double latitude;

  // Longitude geográfica para plotagem no Google Maps.
  final double longitude;

  // Data de recebimento da demanda pela CPPT.
  final DateTime dataRecebimento;

  // Prazo em dias corridos para conclusão a partir do recebimento.
  final int prazoDias;

  // Construtor principal do modelo de demanda.
  const DemandaModel({
    required this.id,
    required this.numeroSgp,
    required this.titulo,
    required this.descricao,
    required this.unidadeSolicitante,
    required this.numeroSei,
    required this.status,
    required this.prioridade,
    this.justificativaPausa,
    required this.servidorId,
    required this.servidorNome,
    required this.lotacao,
    required this.municipio,
    required this.endereco,
    this.logradouro = '',
    this.numero,
    this.complemento,
    this.bairro = '',
    this.estado = 'PI',
    this.cep = '',
    required this.latitude,
    required this.longitude,
    required this.dataRecebimento,
    required this.prazoDias,
  });

  // Calcula a data limite somando [prazoDias] à [dataRecebimento].
  DateTime get dataLimite => dataRecebimento.add(Duration(days: prazoDias));

  // Indica se a demanda não concluída já ultrapassou o prazo previsto.
  bool get isAtrasada =>
      status != 'concluida' && DateTime.now().isAfter(dataLimite);

  // Constrói um [DemandaModel] a partir de um mapa do Firestore ou JSON.
  factory DemandaModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    final rawData = map['dataRecebimento'];
    DateTime parsedData;
    if (rawData is Timestamp) {
      parsedData = rawData.toDate();
    } else if (rawData is DateTime) {
      parsedData = rawData;
    } else if (rawData is String) {
      parsedData = DateTime.tryParse(rawData) ?? DateTime.now();
    } else {
      parsedData = DateTime.now();
    }

    return DemandaModel(
      id: (map['id'] as String?) ?? documentId ?? '',
      numeroSgp: (map['numeroSgp'] as String?) ?? '',
      titulo: (map['titulo'] as String?) ?? '',
      descricao: (map['descricao'] as String?) ?? '',
      unidadeSolicitante: (map['unidadeSolicitante'] as String?) ?? '',
      numeroSei: (map['numeroSei'] as String?) ?? '',
      status: (map['status'] as String?) ?? 'em_andamento',
      prioridade: (map['prioridade'] as String?) ?? 'normal',
      justificativaPausa: map['justificativaPausa'] as String?,
      servidorId: (map['servidorId'] as String?) ?? '',
      servidorNome: (map['servidorNome'] as String?) ?? '',
      lotacao: (map['lotacao'] as String?) ?? '',
      municipio: (map['municipio'] as String?) ?? '',
      endereco: (map['endereco'] as String?) ?? '',
      logradouro: (map['logradouro'] as String?) ?? '',
      numero: map['numero'] as String?,
      complemento: map['complemento'] as String?,
      bairro: (map['bairro'] as String?) ?? '',
      estado: (map['estado'] as String?) ?? 'PI',
      cep: (map['cep'] as String?) ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      dataRecebimento: parsedData,
      prazoDias: (map['prazoDias'] as num?)?.toInt() ?? 15,
    );
  }

  // Converte a instância para mapa compatível com o Cloud Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numeroSgp': numeroSgp,
      'titulo': titulo,
      'descricao': descricao,
      'unidadeSolicitante': unidadeSolicitante,
      'numeroSei': numeroSei,
      'status': status,
      'prioridade': prioridade,
      'justificativaPausa': justificativaPausa,
      'servidorId': servidorId,
      'servidorNome': servidorNome,
      'lotacao': lotacao,
      'municipio': municipio,
      'endereco': endereco,
      'logradouro': logradouro,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'estado': estado,
      'cep': cep,
      'latitude': latitude,
      'longitude': longitude,
      'dataRecebimento': Timestamp.fromDate(dataRecebimento),
      'prazoDias': prazoDias,
    };
  }

  // Retorna uma cópia imutável com os campos informados atualizados.
  DemandaModel copyWith({
    String? id,
    String? numeroSgp,
    String? titulo,
    String? descricao,
    String? unidadeSolicitante,
    String? numeroSei,
    String? status,
    String? prioridade,
    String? justificativaPausa,
    bool clearJustificativa = false,
    String? servidorId,
    String? servidorNome,
    String? lotacao,
    String? municipio,
    String? endereco,
    double? latitude,
    double? longitude,
    DateTime? dataRecebimento,
    int? prazoDias,
  }) {
    return DemandaModel(
      id: id ?? this.id,
      numeroSgp: numeroSgp ?? this.numeroSgp,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      unidadeSolicitante: unidadeSolicitante ?? this.unidadeSolicitante,
      numeroSei: numeroSei ?? this.numeroSei,
      status: status ?? this.status,
      prioridade: prioridade ?? this.prioridade,
      justificativaPausa: clearJustificativa
          ? null
          : (justificativaPausa ?? this.justificativaPausa),
      servidorId: servidorId ?? this.servidorId,
      servidorNome: servidorNome ?? this.servidorNome,
      lotacao: lotacao ?? this.lotacao,
      municipio: municipio ?? this.municipio,
      endereco: endereco ?? this.endereco,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      dataRecebimento: dataRecebimento ?? this.dataRecebimento,
      prazoDias: prazoDias ?? this.prazoDias,
    );
  }
}
