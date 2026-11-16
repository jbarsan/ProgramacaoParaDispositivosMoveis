class ContratoPncpModel {
  final String idContrato;
  final String numeroControlePNCP;
  final String numeroContrato;
  final int anoContrato;
  final int sequencialContrato;
  final String tipoContratoNome;
  final String categoriaProcessoNome;
  final String processo;
  final String objetoContrato;
  final double valorInicial;
  final double valorParcela;
  final double valorGlobal;
  final String nomeFornecedor;
  final String niFornecedor;
  final String tipoPessoa;
  final String dataAssinatura;
  final String dataVigenciaInicio;
  final String dataVigenciaFim;
  final String dataPublicacaoPncp;
  final String cnpjOrgao;
  final String razaoSocialOrgao;
  final String codigoUnidadeOrgao;
  final String nomeUnidadeOrgao;
  final String? numeroControlePncpAta;
  final String? numeroControlePncpCompra;
  final String? informacaoComplementar;

  ContratoPncpModel({
    required this.idContrato,
    required this.numeroControlePNCP,
    required this.numeroContrato,
    required this.anoContrato,
    required this.sequencialContrato,
    required this.tipoContratoNome,
    required this.categoriaProcessoNome,
    required this.processo,
    required this.objetoContrato,
    required this.valorInicial,
    required this.valorParcela,
    required this.valorGlobal,
    required this.nomeFornecedor,
    required this.niFornecedor,
    required this.tipoPessoa,
    required this.dataAssinatura,
    required this.dataVigenciaInicio,
    required this.dataVigenciaFim,
    required this.dataPublicacaoPncp,
    required this.cnpjOrgao,
    required this.razaoSocialOrgao,
    required this.codigoUnidadeOrgao,
    required this.nomeUnidadeOrgao,
    this.numeroControlePncpAta,
    this.numeroControlePncpCompra,
    this.informacaoComplementar,
  });

  factory ContratoPncpModel.fromMap(Map<String, dynamic> map) {
    final orgao = map['orgaoEntidade'] is Map<String, dynamic>
        ? map['orgaoEntidade'] as Map<String, dynamic>
        : <String, dynamic>{};
    final unidade = map['unidadeOrgao'] is Map<String, dynamic>
        ? map['unidadeOrgao'] as Map<String, dynamic>
        : <String, dynamic>{};
    final tipoContrato = map['tipoContrato'] is Map<String, dynamic>
        ? map['tipoContrato'] as Map<String, dynamic>
        : <String, dynamic>{};
    final categoriaProcesso = map['categoriaProcesso'] is Map<String, dynamic>
        ? map['categoriaProcesso'] as Map<String, dynamic>
        : <String, dynamic>{};

    final controlePncp =
        map['numeroControlePNCP']?.toString() ??
        map['idContrato']?.toString() ??
        map['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();

    return ContratoPncpModel(
      idContrato: controlePncp,
      numeroControlePNCP: controlePncp,
      numeroContrato:
          map['numeroContratoEmpenho']?.toString() ??
          map['numeroContrato']?.toString() ??
          'S/N',
      anoContrato: map['anoContrato'] is int
          ? map['anoContrato'] as int
          : int.tryParse(map['anoContrato']?.toString() ?? '') ?? 0,
      sequencialContrato: map['sequencialContrato'] is int
          ? map['sequencialContrato'] as int
          : int.tryParse(map['sequencialContrato']?.toString() ?? '') ?? 0,
      tipoContratoNome:
          tipoContrato['nome']?.toString() ??
          map['tipoContratoNome']?.toString() ??
          'Contrato/Empenho',
      categoriaProcessoNome:
          categoriaProcesso['nome']?.toString() ??
          map['categoriaProcessoNome']?.toString() ??
          'Não informada',
      processo: map['processo']?.toString() ?? 'Não informado',
      objetoContrato:
          map['objetoContrato']?.toString() ?? 'Sem objeto definido',
      valorInicial: (map['valorInicial'] as num?)?.toDouble() ?? 0.0,
      valorParcela: (map['valorParcela'] as num?)?.toDouble() ?? 0.0,
      valorGlobal: (map['valorGlobal'] as num?)?.toDouble() ?? 0.0,
      nomeFornecedor:
          map['nomeRazaoSocialFornecedor']?.toString() ??
          map['nomeFornecedor']?.toString() ??
          'Fornecedor não informado',
      niFornecedor: map['niFornecedor']?.toString() ?? 'Não informado',
      tipoPessoa: map['tipoPessoa']?.toString() ?? '',
      dataAssinatura:
          map['dataAssinatura']?.toString() ?? 'Data Indisponível',
      dataVigenciaInicio:
          map['dataVigenciaInicio']?.toString() ?? 'Não informada',
      dataVigenciaFim: map['dataVigenciaFim']?.toString() ?? 'Não informada',
      dataPublicacaoPncp:
          map['dataPublicacaoPncp']?.toString() ?? 'Não informada',
      cnpjOrgao:
          orgao['cnpj']?.toString() ?? map['cnpjOrgao']?.toString() ?? '',
      razaoSocialOrgao:
          orgao['razaoSocial']?.toString() ??
          map['razaoSocialOrgao']?.toString() ??
          '',
      codigoUnidadeOrgao:
          unidade['codigoUnidade']?.toString() ??
          map['codigoUnidadeOrgao']?.toString() ??
          '',
      nomeUnidadeOrgao:
          unidade['nomeUnidade']?.toString() ??
          map['nomeUnidadeOrgao']?.toString() ??
          '',
      numeroControlePncpAta: map['numeroControlePncpAta']?.toString(),
      numeroControlePncpCompra: map['numeroControlePncpCompra']?.toString(),
      informacaoComplementar: map['informacaoComplementar']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idContrato': idContrato,
      'numeroControlePNCP': numeroControlePNCP,
      'numeroContrato': numeroContrato,
      'anoContrato': anoContrato,
      'sequencialContrato': sequencialContrato,
      'tipoContratoNome': tipoContratoNome,
      'categoriaProcessoNome': categoriaProcessoNome,
      'processo': processo,
      'objetoContrato': objetoContrato,
      'valorInicial': valorInicial,
      'valorParcela': valorParcela,
      'valorGlobal': valorGlobal,
      'nomeFornecedor': nomeFornecedor,
      'niFornecedor': niFornecedor,
      'tipoPessoa': tipoPessoa,
      'dataAssinatura': dataAssinatura,
      'dataVigenciaInicio': dataVigenciaInicio,
      'dataVigenciaFim': dataVigenciaFim,
      'dataPublicacaoPncp': dataPublicacaoPncp,
      'cnpjOrgao': cnpjOrgao,
      'razaoSocialOrgao': razaoSocialOrgao,
      'codigoUnidadeOrgao': codigoUnidadeOrgao,
      'nomeUnidadeOrgao': nomeUnidadeOrgao,
      'numeroControlePncpAta': numeroControlePncpAta,
      'numeroControlePncpCompra': numeroControlePncpCompra,
      'informacaoComplementar': informacaoComplementar,
    };
  }
}
