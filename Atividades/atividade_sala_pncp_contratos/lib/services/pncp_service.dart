import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ata_pncp_model.dart';
import '../models/contrato_pncp_model.dart';

class PncpService {
  // Base URL da API de Consulta oficial do PNCP
  // Swagger: https://pncp.gov.br/api/consulta/swagger-ui/index.html#/
  static const String baseUrl = 'https://pncp.gov.br/api/consulta/v1';

  final http.Client _client;

  PncpService({http.Client? client}) : _client = client ?? http.Client();

  /// Seção Contrato/Empenho:
  /// GET /v1/contratos (Consultar Contratos por Data de Publicação)
  /// ou GET /v1/contratos/atualizacao (por Data de Atualização Global)
  /// Parâmetros: dataInicial (AAAAMMDD), dataFinal (AAAAMMDD), cnpjOrgao, pagina
  Future<List<ContratoPncpModel>> buscarContratos(
    String cnpj,
    String ano, {
    String? dataInicial,
    String? dataFinal,
    int pagina = 1,
    int? tamanhoPagina,
    bool porAtualizacao = false,
  }) async {
    final cnpjLimpo = cnpj.replaceAll(RegExp(r'[^0-9]'), '');
    final dtInicial = (dataInicial != null && dataInicial.trim().isNotEmpty)
        ? dataInicial.replaceAll(RegExp(r'[^0-9]'), '')
        : '${ano}0101';
    final dtFinal = (dataFinal != null && dataFinal.trim().isNotEmpty)
        ? dataFinal.replaceAll(RegExp(r'[^0-9]'), '')
        : '${ano}1101';

    final rota = porAtualizacao ? 'contratos/atualizacao' : 'contratos';
    final queryParams = <String, String>{
      'dataInicial': dtInicial,
      'dataFinal': dtFinal,
      'cnpjOrgao': cnpjLimpo,
      'pagina': pagina.toString(),
      if (tamanhoPagina != null) 'tamanhoPagina': tamanhoPagina.toString(),
    };

    final url = Uri.parse('$baseUrl/$rota').replace(
      queryParameters: queryParams,
    );

    try {
      final response = await _client.get(
        url,
        headers: const {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) {
          return [];
        }
        final dynamic jsonDecodificado = json.decode(
          utf8.decode(response.bodyBytes),
        );
        List<dynamic> dados = [];

        if (jsonDecodificado is List) {
          dados = jsonDecodificado;
        } else if (jsonDecodificado is Map &&
            jsonDecodificado['data'] is List) {
          dados = jsonDecodificado['data'] as List<dynamic>;
        }

        return dados
            .whereType<Map<String, dynamic>>()
            .map(ContratoPncpModel.fromMap)
            .toList();
      } else if (response.statusCode == 204) {
        // 204 No Content indica que não há registros no período informado
        return [];
      } else {
        throw Exception(
          'Erro na API de Contratos (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Falha de comunicação com o PNCP (Contratos): $e');
    }
  }

  /// Seção ATA:
  /// GET /v1/atas (Consultar Ata de Registro de Preço por Período de Vigência)
  /// ou GET /v1/atas/atualizacao (por Data de Atualização Global)
  /// Parâmetros: dataInicial (AAAAMMDD), dataFinal (AAAAMMDD), cnpj, pagina
  Future<List<AtaPncpModel>> buscarAtas(
    String cnpj,
    String ano, {
    String? dataInicial,
    String? dataFinal,
    int pagina = 1,
    int? tamanhoPagina,
    bool porAtualizacao = false,
  }) async {
    final cnpjLimpo = cnpj.replaceAll(RegExp(r'[^0-9]'), '');
    final dtInicial = (dataInicial != null && dataInicial.trim().isNotEmpty)
        ? dataInicial.replaceAll(RegExp(r'[^0-9]'), '')
        : '${ano}0101';
    final dtFinal = (dataFinal != null && dataFinal.trim().isNotEmpty)
        ? dataFinal.replaceAll(RegExp(r'[^0-9]'), '')
        : '${ano}1101';

    final rota = porAtualizacao ? 'atas/atualizacao' : 'atas';
    final queryParams = <String, String>{
      'dataInicial': dtInicial,
      'dataFinal': dtFinal,
      'cnpj': cnpjLimpo,
      'pagina': pagina.toString(),
      if (tamanhoPagina != null) 'tamanhoPagina': tamanhoPagina.toString(),
    };

    final url = Uri.parse('$baseUrl/$rota').replace(
      queryParameters: queryParams,
    );

    try {
      final response = await _client.get(
        url,
        headers: const {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) {
          return [];
        }
        final dynamic jsonDecodificado = json.decode(
          utf8.decode(response.bodyBytes),
        );
        List<dynamic> dados = [];

        if (jsonDecodificado is List) {
          dados = jsonDecodificado;
        } else if (jsonDecodificado is Map &&
            jsonDecodificado['data'] is List) {
          dados = jsonDecodificado['data'] as List<dynamic>;
        }

        return dados
            .whereType<Map<String, dynamic>>()
            .map(AtaPncpModel.fromMap)
            .toList();
      } else if (response.statusCode == 204) {
        // 204 No Content indica que não há registros no período informado
        return [];
      } else {
        throw Exception(
          'Erro na API de Atas (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Falha de comunicação com o PNCP (Atas): $e');
    }
  }
}
