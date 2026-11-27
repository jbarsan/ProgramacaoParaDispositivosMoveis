import 'package:material_ui/material_ui.dart';

import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';

// Selo visual colorido para exibir status, prioridade ou situação (Clean UX).
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  // Cria um [StatusBadge] automaticamente a partir do status da demanda.
  factory StatusBadge.fromDemandaStatus(String status) {
    switch (status) {
      case 'concluida':
        return StatusBadge(
          label: AppFormatters.formatDemandaStatus(status),
          color: AppTheme.statusConcluida,
        );
      case 'pausada':
        return StatusBadge(
          label: AppFormatters.formatDemandaStatus(status),
          color: AppTheme.statusPausada,
        );
      case 'nao_iniciada':
        return StatusBadge(
          label: AppFormatters.formatDemandaStatus(status),
          color: AppTheme.textSecondaryColor,
        );
      case 'em_andamento':
      default:
        return StatusBadge(
          label: AppFormatters.formatDemandaStatus(status),
          color: AppTheme.statusEmAndamento,
        );
    }
  }

  // Cria um [StatusBadge] para a prioridade da demanda.
  factory StatusBadge.fromPrioridade(String prioridade) {
    switch (prioridade) {
      case 'alta':
        return StatusBadge(
          label: 'Prioridade Alta',
          color: AppTheme.statusAltaAtrasada,
        );
      case 'baixa':
        return StatusBadge(
          label: 'Prioridade Baixa',
          color: AppTheme.textSecondaryColor,
        );
      case 'normal':
      default:
        return StatusBadge(
          label: 'Prioridade Normal',
          color: AppTheme.primaryColor,
        );
    }
  }

  // Cria um [StatusBadge] para a situação da viagem.
  factory StatusBadge.fromViagemSituacao(String situacao) {
    switch (situacao) {
      case 'concluida':
        return StatusBadge(
          label: AppFormatters.formatViagemSituacao(situacao),
          color: AppTheme.statusConcluida,
        );
      case 'em_andamento':
        return StatusBadge(
          label: AppFormatters.formatViagemSituacao(situacao),
          color: AppTheme.statusEmAndamento,
        );
      case 'cancelada':
        return StatusBadge(
          label: AppFormatters.formatViagemSituacao(situacao),
          color: AppTheme.statusAltaAtrasada,
        );
      case 'agendada':
      default:
        return StatusBadge(
          label: AppFormatters.formatViagemSituacao(situacao),
          color: AppTheme.statusPausada,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
