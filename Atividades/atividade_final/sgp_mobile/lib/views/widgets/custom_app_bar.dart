import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/notificacao_controller.dart';
import '../../models/notificacao_model.dart';
import '../notificacoes/notificacoes_view.dart';

// Barra superior institucional padronizada do SGP Mobile com sino de notificações.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const CustomAppBar({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController?>()?.currentUser;
    final notifCtrl = context.watch<NotificacaoController?>();

    return AppBar(
      title: Text(title),
      actions: [
        if (user != null && notifCtrl != null)
          StreamBuilder<List<NotificacaoModel>>(
            stream: notifCtrl.streamNotificacoes(user),
            builder: (context, snapshot) {
              final naoLidas = (snapshot.data ?? [])
                  .where((n) => !n.foiLidaPor(user.uid))
                  .length;
              return IconButton(
                tooltip: 'Notificações',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificacoesView()),
                  );
                },
                icon: Badge(
                  isLabelVisible: naoLidas > 0,
                  label: Text('$naoLidas'),
                  child: const Icon(Icons.notifications_outlined),
                ),
              );
            },
          ),
        ...?actions,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
