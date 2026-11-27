import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'constants.dart';

// Utilitários de formatação para datas, rótulos de status, papéis,
// lotações e máscaras de entrada (SEI e CEP).
class AppFormatters {
  // Impede instanciação direta desta classe utilitária.
  AppFormatters._();

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  // Expressão regular que valida o padrão SEI `00.00.0000.0000000/xxxx-00`.
  static final RegExp _seiRegex = RegExp(
    r'^\d{2}\.\d{2}\.\d{4}\.\d{7}/\d{4}-\d{2}$',
  );

  // Expressão regular que valida o número SGP parcial `numero/ano` (1 a 7 dígitos / 4 dígitos).
  static final RegExp _sgpRegex = RegExp(r'^\d{1,7}/\d{4}$');

  // Formata um [DateTime] no padrão `dd/MM/yyyy`.
  static String formatDate(DateTime date) => _dateFormat.format(date);

  // Formata um [DateTime] no padrão `dd/MM/yyyy HH:mm`.
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);

  // Retorna a lotação formatada com sigla e nome completo do setor.
  static String formatLotacao(String? sigla) {
    if (sigla == null || sigla.trim().isEmpty) {
      return 'Sem lotação';
    }
    final nome = AppConstants.lotacoesNomes[sigla];
    if (nome == null) return sigla;
    return '$sigla - $nome';
  }

  // Valida o Número SEI no padrão `00.00.0000.0000000/xxxx-00` e impede ano futuro.
  static String? validateSei(String? value, {bool required = false}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return required ? 'Informe o número SEI.' : null;
    }
    final anoAtual = DateTime.now().year;
    if (!_seiRegex.hasMatch(trimmed)) {
      return 'Formato SEI inválido. Use 00.00.0000.0000000/$anoAtual-00';
    }
    final anoStr = trimmed.split('/').last.split('-').first;
    final anoInformado = int.tryParse(anoStr);
    if (anoInformado == null || anoInformado > anoAtual) {
      return 'O ano do SEI não pode ser maior que $anoAtual.';
    }
    return null;
  }

  // Valida o Número SGP digitado no formato `numero/ano` (até 7 dígitos e ano com 4 dígitos).
  static String? validateSgpNumero(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Informe o número SGP (ex.: 0001234/${DateTime.now().year}).';
    }
    if (!_sgpRegex.hasMatch(trimmed)) {
      return 'Use o formato numero/ano (até 7 dígitos / 4 dígitos).';
    }
    return null;
  }

  // Combina `numero/ano` (preenchendo zeros à esquerda até 7 dígitos) com a sigla
  // da lotação, gerando o padrão final `0001234/2026-ENG`.
  static String formatNumeroSgpCompleto(String numeroAno, String lotacao) {
    final parts = numeroAno.trim().split('/');
    if (parts.length != 2) return '${numeroAno.trim()}-$lotacao';
    final numPadded = parts[0].padLeft(7, '0');
    return '$numPadded/${parts[1]}-$lotacao';
  }

  // Converte o código interno do papel em um rótulo amigável para exibição.
  static String formatRole(String role) {
    switch (role) {
      case 'administrador':
        return 'Administrador Master';
      case 'coordenacao':
        return 'Coordenação';
      case 'servidor':
        return 'Servidor / Perito';
      case 'pendente':
      default:
        return 'Pendente';
    }
  }

  // Converte o status interno da demanda em texto legível.
  static String formatDemandaStatus(String status) {
    switch (status) {
      case 'nao_iniciada':
        return 'Não Iniciada';
      case 'em_andamento':
        return 'Em Andamento';
      case 'pausada':
        return 'Pausada';
      case 'concluida':
        return 'Concluída';
      default:
        return status;
    }
  }

  // Converte a prioridade interna da demanda em texto legível.
  static String formatPrioridade(String prioridade) {
    switch (prioridade) {
      case 'alta':
        return 'Alta';
      case 'normal':
        return 'Normal';
      case 'baixa':
        return 'Baixa';
      default:
        return prioridade;
    }
  }

  // Converte a situação interna da viagem em texto legível.
  static String formatViagemSituacao(String situacao) {
    switch (situacao) {
      case 'agendada':
        return 'Agendada';
      case 'em_andamento':
        return 'Em Andamento';
      case 'concluida':
        return 'Concluída';
      case 'cancelada':
        return 'Cancelada';
      default:
        return situacao;
    }
  }
}

// Formatador de entrada para Número SEI no padrão `00.00.0000.0000000/xxxx-00`.
//
// Aceita até 21 dígitos numéricos e insere automaticamente os separadores
// `.`, `/` e `-`.
class SeiInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final clipped = digits.length > 21 ? digits.substring(0, 21) : digits;

    final buffer = StringBuffer();
    for (int i = 0; i < clipped.length; i++) {
      if (i == 2 || i == 4 || i == 8) {
        buffer.write('.');
      } else if (i == 15) {
        buffer.write('/');
      } else if (i == 19) {
        buffer.write('-');
      }
      buffer.write(clipped[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Formatador de entrada para CEP brasileiro `00000-000`.
class CepInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final clipped = digits.length > 8 ? digits.substring(0, 8) : digits;

    final buffer = StringBuffer();
    for (int i = 0; i < clipped.length; i++) {
      if (i == 5) buffer.write('-');
      buffer.write(clipped[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Formatador de entrada para Número SGP no padrão `numero/ano`
// (até 7 dígitos numéricos, `/` e 4 dígitos do ano).
class SgpNumeroInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final clean = newValue.text.replaceAll(RegExp(r'[^0-9/]'), '');
    String formatted;

    if (clean.contains('/')) {
      final firstSlash = clean.indexOf('/');
      final rawNum = clean.substring(0, firstSlash).replaceAll('/', '');
      final rawAno = clean.substring(firstSlash + 1).replaceAll('/', '');
      final numClipped = rawNum.length > 7 ? rawNum.substring(0, 7) : rawNum;
      final anoClipped = rawAno.length > 4 ? rawAno.substring(0, 4) : rawAno;
      formatted = '$numClipped/$anoClipped';
    } else {
      if (clean.length > 7) {
        final numClipped = clean.substring(0, 7);
        final anoPart = clean.substring(7);
        final anoClipped = anoPart.length > 4
            ? anoPart.substring(0, 4)
            : anoPart;
        formatted = '$numClipped/$anoClipped';
      } else {
        formatted = clean;
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
