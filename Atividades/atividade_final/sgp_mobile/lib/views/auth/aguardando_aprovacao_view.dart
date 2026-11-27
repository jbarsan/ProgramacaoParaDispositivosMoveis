import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../utils/app_theme.dart';

// Tela de bloqueio exibida para usuários recém-cadastrados com `ativo == false`
// ou `role == 'pendente'` (RF-004).
class AguardandoAprovacaoView extends StatelessWidget {
  const AguardandoAprovacaoView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acesso Pendente'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => auth.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.hourglass_top_rounded,
                  size: 72,
                  color: AppTheme.statusPausada,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aguardando Autorização da Coordenação',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Olá, ${user?.nome ?? "Servidor"}. Seu cadastro foi recebido e aguarda aprovação da Coordenação da CPPT/MPPI.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondaryColor),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: auth.isLoading
                      ? null
                      : () => auth.refreshProfile(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Atualizar Status'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => auth.signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair da Conta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
