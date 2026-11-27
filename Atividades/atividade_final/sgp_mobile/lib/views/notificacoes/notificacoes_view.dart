import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/notificacao_controller.dart';
import '../../models/notificacao_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../widgets/loading_indicator.dart';

// Tela de listagem de Notificações in-app para servidores e gestores.
class NotificacoesView extends StatelessWidget {
  const NotificacoesView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final notifCtrl = context.watch<NotificacaoController>();

    if (user == null) return const Scaffold(body: LoadingIndicator());

    return Scaffold(
      appBar: AppBar(title: const Text('Notificações')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.maxWebContentWidth,
          ),
          child: StreamBuilder<List<NotificacaoModel>>(
            stream: notifCtrl.streamNotificacoes(user),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingIndicator(
                  message: 'Carregando notificações...',
                );
              }
              final lista = snapshot.data ?? [];
              if (lista.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhuma notificação até o momento.',
                    style: TextStyle(color: AppTheme.textSecondaryColor),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: lista.length,
                itemBuilder: (context, index) {
                  final n = lista[index];
                  final lida = n.foiLidaPor(user.uid);
                  return Card(
                    color: lida
                        ? AppTheme.surfaceIceColor
                        : AppTheme.primaryColor.withValues(alpha: 0.06),
                    child: ListTile(
                      leading: Icon(
                        n.tipo == 'viagem'
                            ? Icons.directions_car
                            : Icons.assignment,
                        color: lida
                            ? AppTheme.textSecondaryColor
                            : AppTheme.primaryColor,
                      ),
                      title: Text(
                        n.titulo,
                        style: TextStyle(
                          fontWeight: lida ? FontWeight.w500 : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(n.mensagem),
                          const SizedBox(height: 4),
                          Text(
                            AppFormatters.formatDateTime(n.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                      trailing: lida
                          ? null
                          : const Icon(
                              Icons.circle,
                              size: 10,
                              color: AppTheme.primaryColor,
                            ),
                      onTap: () {
                        if (!lida) {
                          notifCtrl.marcarComoLida(n.id, user.uid);
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
