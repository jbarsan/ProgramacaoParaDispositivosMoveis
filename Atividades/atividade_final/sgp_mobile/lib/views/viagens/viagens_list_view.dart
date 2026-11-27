import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/viagem_controller.dart';
import '../../models/viagem_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/status_badge.dart';
import 'viagem_detail_view.dart';
import 'viagem_form_view.dart';

// Tela de listagem de Viagens e deslocamentos periciais (RF-013).
class ViagensListView extends StatelessWidget {
  const ViagensListView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final viagemCtrl = context.watch<ViagemController>();

    if (user == null) {
      return const LoadingIndicator();
    }

    return Scaffold(
      body: StreamBuilder<List<ViagemModel>>(
        stream: viagemCtrl.streamViagens(user),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(message: 'Carregando viagens...');
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar viagens: ${snapshot.error}'),
            );
          }

          final viagens = snapshot.data ?? [];
          if (viagens.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma viagem cadastrada.',
                style: TextStyle(color: AppTheme.textSecondaryColor),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: viagens.length,
            itemBuilder: (context, index) {
              final v = viagens[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViagemDetailView(viagem: v),
                      ),
                    );
                  },
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          v.destinoCidade,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      StatusBadge.fromViagemSituacao(v.situacao),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        'Portaria: ${v.numeroPortaria} (SEI ${v.seiPortaria})',
                      ),
                      Text('Solicitante: ${v.unidadeSolicitante}'),
                      const SizedBox(height: 4),
                      Text(
                        'Ida: ${AppFormatters.formatDate(v.dataIda)} • Retorno: ${AppFormatters.formatDate(v.dataRetorno)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ViagemFormView()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova Viagem'),
      ),
    );
  }
}
