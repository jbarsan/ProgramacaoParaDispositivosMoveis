import 'package:flutter/foundation.dart';

import '../models/contrato_pncp_model.dart';
import '../services/pncp_service.dart';

class ContratoController extends ChangeNotifier {
  final PncpService _service;

  ContratoController({PncpService? service})
    : _service = service ?? PncpService();

  List<ContratoPncpModel> _contratos = [];
  List<ContratoPncpModel> _contratosFiltrados = [];
  bool _isLoading = false;
  String _erro = '';

  List<ContratoPncpModel> get contratos => _contratosFiltrados;
  int get totalCarregados => _contratos.length;
  bool get isLoading => _isLoading;
  String get erro => _erro;

  Future<void> consultarCnpj(
    String cnpj,
    String ano, {
    String? dataInicial,
    String? dataFinal,
    int pagina = 1,
    bool porAtualizacao = false,
  }) async {
    final cnpjLimpo = cnpj.replaceAll(RegExp(r'[^0-9]'), '');
    final anoLimpo = ano.replaceAll(RegExp(r'[^0-9]'), '');

    if (cnpjLimpo.length != 14) {
      _erro = 'Informe um CNPJ válido com 14 dígitos numéricos.';
      notifyListeners();
      return;
    }

    if (anoLimpo.isEmpty &&
        ((dataInicial == null || dataInicial.isEmpty) ||
            (dataFinal == null || dataFinal.isEmpty))) {
      _erro = 'Preencha o Ano ou o período (Data Inicial e Data Final).';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _erro = '';
    notifyListeners();

    try {
      _contratos = await _service.buscarContratos(
        cnpjLimpo,
        anoLimpo,
        dataInicial: dataInicial,
        dataFinal: dataFinal,
        pagina: pagina,
        porAtualizacao: porAtualizacao,
      );
      _contratosFiltrados = _contratos;
    } catch (e) {
      _erro = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filtrarResultadosLocais(String termo) {
    final busca = termo.trim().toLowerCase();
    if (busca.isEmpty) {
      _contratosFiltrados = _contratos;
    } else {
      _contratosFiltrados = _contratos.where((c) {
        return c.objetoContrato.toLowerCase().contains(busca) ||
            c.nomeFornecedor.toLowerCase().contains(busca) ||
            c.numeroContrato.toLowerCase().contains(busca) ||
            c.processo.toLowerCase().contains(busca) ||
            c.tipoContratoNome.toLowerCase().contains(busca) ||
            c.niFornecedor.toLowerCase().contains(busca) ||
            c.numeroControlePNCP.toLowerCase().contains(busca);
      }).toList();
    }
    notifyListeners();
  }
}
