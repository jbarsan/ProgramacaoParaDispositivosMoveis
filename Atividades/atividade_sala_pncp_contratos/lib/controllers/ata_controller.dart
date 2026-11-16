import 'package:flutter/foundation.dart';

import '../models/ata_pncp_model.dart';
import '../services/pncp_service.dart';

class AtaController extends ChangeNotifier {
  final PncpService _service;

  AtaController({PncpService? service}) : _service = service ?? PncpService();

  List<AtaPncpModel> _atas = [];
  List<AtaPncpModel> _atasFiltradas = [];
  bool _isLoading = false;
  String _erro = '';

  List<AtaPncpModel> get atas => _atasFiltradas;
  int get totalCarregadas => _atas.length;
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
      _atas = await _service.buscarAtas(
        cnpjLimpo,
        anoLimpo,
        dataInicial: dataInicial,
        dataFinal: dataFinal,
        pagina: pagina,
        porAtualizacao: porAtualizacao,
      );
      _atasFiltradas = _atas;
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
      _atasFiltradas = _atas;
    } else {
      _atasFiltradas = _atas.where((a) {
        return a.objetoContratacao.toLowerCase().contains(busca) ||
            a.numeroAtaRegistroPreco.toLowerCase().contains(busca) ||
            a.numeroControlePNCPAta.toLowerCase().contains(busca) ||
            a.nomeOrgao.toLowerCase().contains(busca) ||
            a.nomeUnidadeOrgao.toLowerCase().contains(busca) ||
            a.anoAta.toString().contains(busca);
      }).toList();
    }
    notifyListeners();
  }
}
