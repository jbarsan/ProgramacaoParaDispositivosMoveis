import 'package:cloud_firestore/cloud_firestore.dart';

import 'demanda_model.dart';

// Representa um endereço/destino individual dentro de uma viagem,
// podendo estar vinculado a uma demanda específica ou adicionado manualmente.
class ViagemDestino {
  // ID da demanda associada a este destino (nulo se adicionado manualmente).
  final String? demandaId;

  // Número SGP da demanda associada para exibição rápida.
  final String? demandaNumeroSgp;

  // Cidade do destino.
  final String cidade;

  // Endereço completo formatado.
  final String endereco;

  // Logradouro (rua, avenida, etc.).
  final String logradouro;

  // Número do endereço (opcional).
  final String? numero;

  // Complemento (opcional).
  final String? complemento;

  // Bairro.
  final String bairro;

  // Sigla do Estado (UF).
  final String estado;

  // CEP.
  final String cep;

  // Latitude do destino.
  final double latitude;

  // Longitude do destino.
  final double longitude;

  const ViagemDestino({
    this.demandaId,
    this.demandaNumeroSgp,
    required this.cidade,
    required this.endereco,
    this.logradouro = '',
    this.numero,
    this.complemento,
    this.bairro = '',
    this.estado = 'PI',
    this.cep = '',
    required this.latitude,
    required this.longitude,
  });

  // Cria um [ViagemDestino] preenchido automaticamente a partir de uma [DemandaModel].
  factory ViagemDestino.fromDemanda(DemandaModel demanda) {
    return ViagemDestino(
      demandaId: demanda.id,
      demandaNumeroSgp: demanda.numeroSgp,
      cidade: demanda.municipio,
      endereco: demanda.endereco,
      logradouro: demanda.logradouro,
      numero: demanda.numero,
      complemento: demanda.complemento,
      bairro: demanda.bairro,
      estado: demanda.estado,
      cep: demanda.cep,
      latitude: demanda.latitude,
      longitude: demanda.longitude,
    );
  }

  // Constrói um [ViagemDestino] a partir de um mapa do Firestore/JSON.
  factory ViagemDestino.fromMap(Map<String, dynamic> map) {
    return ViagemDestino(
      demandaId: map['demandaId'] as String?,
      demandaNumeroSgp: map['demandaNumeroSgp'] as String?,
      cidade: (map['cidade'] as String?) ?? '',
      endereco: (map['endereco'] as String?) ?? '',
      logradouro: (map['logradouro'] as String?) ?? '',
      numero: map['numero'] as String?,
      complemento: map['complemento'] as String?,
      bairro: (map['bairro'] as String?) ?? '',
      estado: (map['estado'] as String?) ?? 'PI',
      cep: (map['cep'] as String?) ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Converte este destino para mapa compatível com o Firestore.
  Map<String, dynamic> toMap() {
    return {
      'demandaId': demandaId,
      'demandaNumeroSgp': demandaNumeroSgp,
      'cidade': cidade,
      'endereco': endereco,
      'logradouro': logradouro,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'estado': estado,
      'cep': cep,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

// Modelo que representa uma viagem/deslocamento na coleção `viagens`.
class ViagemModel {
  // Identificador do documento no Firestore.
  final String id;

  // Lista de IDs das demandas associadas a esta viagem.
  final List<String> demandasIds;

  // Unidade solicitante herdada da(s) demanda(s) associada(s).
  final String unidadeSolicitante;

  // Número SEI da Portaria de viagem.
  final String seiPortaria;

  // Número oficial da Portaria.
  final String numeroPortaria;

  // Descrição resumida das atividades periciais em campo.
  final String descricaoAtividades;

  // Cidade principal de destino da viagem.
  final String destinoCidade;

  // Endereço completo principal do destino para compatibilidade e listagem.
  final String destinoEndereco;

  // Logradouro do destino principal.
  final String logradouro;

  // Número do endereço principal (opcional).
  final String? numero;

  // Complemento do endereço principal (opcional).
  final String? complemento;

  // Bairro do destino principal.
  final String bairro;

  // Sigla do Estado (UF).
  final String estado;

  // CEP no formato `00000-000`.
  final String cep;

  // Latitude do destino principal.
  final double latitude;

  // Longitude do destino principal.
  final double longitude;

  // Lista completa de destinos/paradas da viagem (suporta múltiplas cidades/endereços).
  final List<ViagemDestino> destinos;

  // Data de partida prevista/realizada.
  final DateTime dataIda;

  // Data de retorno prevista/realizada.
  final DateTime dataRetorno;

  // Situação atual: `agendada`, `em_andamento`, `concluida` ou `cancelada`.
  final String situacao;

  // Número SEI da Prestação de Contas após o retorno (opcional).
  final String? seiPrestacaoContas;

  // Observações complementares sobre o deslocamento.
  final String? observacoes;

  // UID do servidor principal responsável pela viagem (compatibilidade).
  final String servidorId;

  // Lista de UIDs dos servidores vinculados à viagem (múltiplos servidores).
  final List<String> servidoresIds;

  // Lista de nomes dos servidores vinculados à viagem.
  final List<String> servidoresNomes;

  // Construtor principal do modelo de viagem.
  const ViagemModel({
    required this.id,
    required this.demandasIds,
    required this.unidadeSolicitante,
    required this.seiPortaria,
    required this.numeroPortaria,
    required this.descricaoAtividades,
    required this.destinoCidade,
    required this.destinoEndereco,
    this.logradouro = '',
    this.numero,
    this.complemento,
    this.bairro = '',
    this.estado = 'PI',
    this.cep = '',
    required this.latitude,
    required this.longitude,
    this.destinos = const [],
    required this.dataIda,
    required this.dataRetorno,
    required this.situacao,
    this.seiPrestacaoContas,
    this.observacoes,
    required this.servidorId,
    this.servidoresIds = const [],
    this.servidoresNomes = const [],
  });

  // Retorna a lista efetiva de destinos (ou o destino principal como fallback).
  List<ViagemDestino> get destinosEfetivos {
    if (destinos.isNotEmpty) return destinos;
    if (destinoCidade.isEmpty && destinoEndereco.isEmpty) return const [];
    return [
      ViagemDestino(
        cidade: destinoCidade,
        endereco: destinoEndereco,
        logradouro: logradouro,
        numero: numero,
        complemento: complemento,
        bairro: bairro,
        estado: estado,
        cep: cep,
        latitude: latitude,
        longitude: longitude,
      ),
    ];
  }

  // Constrói um [ViagemModel] a partir de um mapa do Firestore ou JSON.
  factory ViagemModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    final rawIds = map['demandasIds'];
    final List<String> parsedIds = rawIds is Iterable
        ? rawIds.map((e) => e.toString()).toList()
        : <String>[];

    final rawDestinos = map['destinos'];
    final List<ViagemDestino> parsedDestinos = rawDestinos is Iterable
        ? rawDestinos
              .whereType<Map<String, dynamic>>()
              .map(ViagemDestino.fromMap)
              .toList()
        : <ViagemDestino>[];

    final rawServIds = map['servidoresIds'];
    final List<String> parsedServIds = rawServIds is Iterable
        ? rawServIds.map((e) => e.toString()).toList()
        : <String>[];
    final fallbackServId = (map['servidorId'] as String?) ?? '';
    final effectiveServIds = parsedServIds.isNotEmpty
        ? parsedServIds
        : (fallbackServId.isNotEmpty ? [fallbackServId] : <String>[]);

    final rawServNomes = map['servidoresNomes'];
    final List<String> parsedServNomes = rawServNomes is Iterable
        ? rawServNomes.map((e) => e.toString()).toList()
        : <String>[];

    return ViagemModel(
      id: (map['id'] as String?) ?? documentId ?? '',
      demandasIds: parsedIds,
      unidadeSolicitante: (map['unidadeSolicitante'] as String?) ?? '',
      seiPortaria: (map['seiPortaria'] as String?) ?? '',
      numeroPortaria: (map['numeroPortaria'] as String?) ?? '',
      descricaoAtividades: (map['descricaoAtividades'] as String?) ?? '',
      destinoCidade: (map['destinoCidade'] as String?) ?? '',
      destinoEndereco: (map['destinoEndereco'] as String?) ?? '',
      logradouro: (map['logradouro'] as String?) ?? '',
      numero: map['numero'] as String?,
      complemento: map['complemento'] as String?,
      bairro: (map['bairro'] as String?) ?? '',
      estado: (map['estado'] as String?) ?? 'PI',
      cep: (map['cep'] as String?) ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      destinos: parsedDestinos,
      dataIda: parseDate(map['dataIda']),
      dataRetorno: parseDate(map['dataRetorno']),
      situacao: (map['situacao'] as String?) ?? 'agendada',
      seiPrestacaoContas: map['seiPrestacaoContas'] as String?,
      observacoes: map['observacoes'] as String?,
      servidorId: fallbackServId,
      servidoresIds: effectiveServIds,
      servidoresNomes: parsedServNomes,
    );
  }

  // Converte a instância para mapa compatível com o Cloud Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'demandasIds': demandasIds,
      'unidadeSolicitante': unidadeSolicitante,
      'seiPortaria': seiPortaria,
      'numeroPortaria': numeroPortaria,
      'descricaoAtividades': descricaoAtividades,
      'destinoCidade': destinoCidade,
      'destinoEndereco': destinoEndereco,
      'logradouro': logradouro,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'estado': estado,
      'cep': cep,
      'latitude': latitude,
      'longitude': longitude,
      'destinos': destinos.map((d) => d.toMap()).toList(),
      'dataIda': Timestamp.fromDate(dataIda),
      'dataRetorno': Timestamp.fromDate(dataRetorno),
      'situacao': situacao,
      'seiPrestacaoContas': seiPrestacaoContas,
      'observacoes': observacoes,
      'servidorId': servidorId,
      'servidoresIds': servidoresIds.isNotEmpty
          ? servidoresIds
          : (servidorId.isNotEmpty ? [servidorId] : <String>[]),
      'servidoresNomes': servidoresNomes,
    };
  }

  // Retorna uma cópia imutável com os campos informados atualizados.
  ViagemModel copyWith({
    String? id,
    List<String>? demandasIds,
    String? unidadeSolicitante,
    String? seiPortaria,
    String? numeroPortaria,
    String? descricaoAtividades,
    String? destinoCidade,
    String? destinoEndereco,
    String? logradouro,
    String? numero,
    String? complemento,
    String? bairro,
    String? estado,
    String? cep,
    double? latitude,
    double? longitude,
    List<ViagemDestino>? destinos,
    DateTime? dataIda,
    DateTime? dataRetorno,
    String? situacao,
    String? seiPrestacaoContas,
    String? observacoes,
    String? servidorId,
    List<String>? servidoresIds,
    List<String>? servidoresNomes,
  }) {
    return ViagemModel(
      id: id ?? this.id,
      demandasIds: demandasIds ?? this.demandasIds,
      unidadeSolicitante: unidadeSolicitante ?? this.unidadeSolicitante,
      seiPortaria: seiPortaria ?? this.seiPortaria,
      numeroPortaria: numeroPortaria ?? this.numeroPortaria,
      descricaoAtividades: descricaoAtividades ?? this.descricaoAtividades,
      destinoCidade: destinoCidade ?? this.destinoCidade,
      destinoEndereco: destinoEndereco ?? this.destinoEndereco,
      logradouro: logradouro ?? this.logradouro,
      numero: numero ?? this.numero,
      complemento: complemento ?? this.complemento,
      bairro: bairro ?? this.bairro,
      estado: estado ?? this.estado,
      cep: cep ?? this.cep,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      destinos: destinos ?? this.destinos,
      dataIda: dataIda ?? this.dataIda,
      dataRetorno: dataRetorno ?? this.dataRetorno,
      situacao: situacao ?? this.situacao,
      seiPrestacaoContas: seiPrestacaoContas ?? this.seiPrestacaoContas,
      observacoes: observacoes ?? this.observacoes,
      servidorId: servidorId ?? this.servidorId,
      servidoresIds: servidoresIds ?? this.servidoresIds,
      servidoresNomes: servidoresNomes ?? this.servidoresNomes,
    );
  }
}
