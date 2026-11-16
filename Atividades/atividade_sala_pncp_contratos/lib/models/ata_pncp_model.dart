class AtaPncpModel {
  final String numeroControlePNCPAta;
  final String numeroAtaRegistroPreco;
  final int anoAta;
  final String numeroControlePNCPCompra;
  final bool cancelado;
  final String? dataCancelamento;
  final String dataAssinatura;
  final String vigenciaInicio;
  final String vigenciaFim;
  final String dataPublicacaoPncp;
  final String dataInclusao;
  final String dataAtualizacao;
  final String objetoContratacao;
  final String cnpjOrgao;
  final String nomeOrgao;
  final String codigoUnidadeOrgao;
  final String nomeUnidadeOrgao;
  final bool? possibilidadeAdesao;
  final String usuario;

  AtaPncpModel({
    required this.numeroControlePNCPAta,
    required this.numeroAtaRegistroPreco,
    required this.anoAta,
    required this.numeroControlePNCPCompra,
    required this.cancelado,
    this.dataCancelamento,
    required this.dataAssinatura,
    required this.vigenciaInicio,
    required this.vigenciaFim,
    required this.dataPublicacaoPncp,
    required this.dataInclusao,
    required this.dataAtualizacao,
    required this.objetoContratacao,
    required this.cnpjOrgao,
    required this.nomeOrgao,
    required this.codigoUnidadeOrgao,
    required this.nomeUnidadeOrgao,
    this.possibilidadeAdesao,
    required this.usuario,
  });

  factory AtaPncpModel.fromMap(Map<String, dynamic> map) {
    return AtaPncpModel(
      numeroControlePNCPAta:
          map['numeroControlePNCPAta']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      numeroAtaRegistroPreco:
          map['numeroAtaRegistroPreco']?.toString() ?? 'S/N',
      anoAta: map['anoAta'] is int
          ? map['anoAta'] as int
          : int.tryParse(map['anoAta']?.toString() ?? '') ?? 0,
      numeroControlePNCPCompra:
          map['numeroControlePNCPCompra']?.toString() ?? '',
      cancelado: map['cancelado'] == true,
      dataCancelamento: map['dataCancelamento']?.toString(),
      dataAssinatura:
          map['dataAssinatura']?.toString() ?? 'Data Indisponível',
      vigenciaInicio: map['vigenciaInicio']?.toString() ?? 'Não informada',
      vigenciaFim: map['vigenciaFim']?.toString() ?? 'Não informada',
      dataPublicacaoPncp:
          map['dataPublicacaoPncp']?.toString() ?? 'Não informada',
      dataInclusao: map['dataInclusao']?.toString() ?? '',
      dataAtualizacao: map['dataAtualizacao']?.toString() ?? '',
      objetoContratacao:
          map['objetoContratacao']?.toString() ?? 'Sem objeto definido',
      cnpjOrgao: map['cnpjOrgao']?.toString() ?? '',
      nomeOrgao: map['nomeOrgao']?.toString() ?? 'Órgão não informado',
      codigoUnidadeOrgao: map['codigoUnidadeOrgao']?.toString() ?? '',
      nomeUnidadeOrgao:
          map['nomeUnidadeOrgao']?.toString() ?? 'Unidade não informada',
      possibilidadeAdesao: map['possibilidadeAdesao'] is bool
          ? map['possibilidadeAdesao'] as bool
          : null,
      usuario: map['usuario']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'numeroControlePNCPAta': numeroControlePNCPAta,
      'numeroAtaRegistroPreco': numeroAtaRegistroPreco,
      'anoAta': anoAta,
      'numeroControlePNCPCompra': numeroControlePNCPCompra,
      'cancelado': cancelado,
      'dataCancelamento': dataCancelamento,
      'dataAssinatura': dataAssinatura,
      'vigenciaInicio': vigenciaInicio,
      'vigenciaFim': vigenciaFim,
      'dataPublicacaoPncp': dataPublicacaoPncp,
      'dataInclusao': dataInclusao,
      'dataAtualizacao': dataAtualizacao,
      'objetoContratacao': objetoContratacao,
      'cnpjOrgao': cnpjOrgao,
      'nomeOrgao': nomeOrgao,
      'codigoUnidadeOrgao': codigoUnidadeOrgao,
      'nomeUnidadeOrgao': nomeUnidadeOrgao,
      'possibilidadeAdesao': possibilidadeAdesao,
      'usuario': usuario,
    };
  }
}
