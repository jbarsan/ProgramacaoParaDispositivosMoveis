import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/demanda_controller.dart';
import '../../controllers/viagem_controller.dart';
import '../../models/demanda_model.dart';
import '../../models/viagem_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../widgets/loading_indicator.dart';

// Aba de Resumo e Indicadores de produtividade e prazos do servidor (RF-007).
class ResumoIndicadoresView extends StatelessWidget {
  const ResumoIndicadoresView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final demandaCtrl = context.watch<DemandaController>();
    final viagemCtrl = context.watch<ViagemController>();

    if (user == null) return const LoadingIndicator();

    return StreamBuilder<List<DemandaModel>>(
      stream: demandaCtrl.streamDemandas(user),
      builder: (context, demandaSnap) {
        final demandas = demandaSnap.data ?? [];
        final emAndamento = demandas
            .where((d) => d.status == AppConstants.statusEmAndamento)
            .length;
        final pausadas = demandas
            .where((d) => d.status == AppConstants.statusPausada)
            .length;
        final concluidas = demandas
            .where((d) => d.status == AppConstants.statusConcluida)
            .length;
        final atrasadas = demandas.where((d) => d.isAtrasada).length;

        return StreamBuilder<List<ViagemModel>>(
          stream: viagemCtrl.streamViagens(user),
          builder: (context, viagemSnap) {
            final viagens = viagemSnap.data ?? [];
            final viagensAtivas = viagens
                .where(
                  (v) =>
                      v.situacao == AppConstants.viagemAgendada ||
                      v.situacao == AppConstants.viagemEmAndamento,
                )
                .length;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Olá, ${user.nome}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Resumo operacional • ${AppFormatters.formatLotacao(user.lotacao)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textSecondaryColor),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.45,
                  children: [
                    _metricCard(
                      'Em Andamento',
                      emAndamento.toString(),
                      Icons.pending_actions,
                      AppTheme.statusEmAndamento,
                    ),
                    _metricCard(
                      'Pausadas',
                      pausadas.toString(),
                      Icons.pause_circle_outline,
                      AppTheme.statusPausada,
                    ),
                    _metricCard(
                      'Concluídas',
                      concluidas.toString(),
                      Icons.check_circle_outline,
                      AppTheme.statusConcluida,
                    ),
                    _metricCard(
                      'Atrasadas',
                      atrasadas.toString(),
                      Icons.warning_amber_rounded,
                      AppTheme.statusAltaAtrasada,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.directions_car,
                      color: AppTheme.primaryColor,
                      size: 32,
                    ),
                    title: const Text(
                      'Viagens Programadas / Ativas',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: Text(
                      '$viagensAtivas',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 26),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
