import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../admin/gestao_usuarios_view.dart';
import '../perfil/perfil_edit_view.dart';

// Menu lateral do servidor (`Drawer`) conforme RF-005 e `AGENTS_ARQUITETURA.md`.
//
// Exibe cabeçalho institucional `#8E1919` com avatar (asset local ou URL),
// nome, matrícula, cargo, lotação completa com sigla (truncável) e papel,
// além de atalhos para edição de perfil, Gestão de Usuários e Logout.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  // Constrói o [ImageProvider] adequado para asset local (`assets/`) ou URL remota.
  ImageProvider? _resolveAvatar(String? fotoUrl) {
    if (fotoUrl == null || fotoUrl.isEmpty) return null;
    if (fotoUrl.startsWith('assets/')) return AssetImage(fotoUrl);
    return NetworkImage(fotoUrl);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    if (user == null) {
      return const Drawer(child: SizedBox.shrink());
    }

    final avatarImage = _resolveAvatar(user.fotoUrl);

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            color: AppTheme.primaryColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white,
                  backgroundImage: avatarImage,
                  child: avatarImage == null
                      ? Text(
                          user.nome.isNotEmpty
                              ? user.nome[0].toUpperCase()
                              : 'S',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  user.nome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${user.cargo.isNotEmpty ? user.cargo : "Servidor"} • Mat. ${user.matricula.isNotEmpty ? user.matricula : "-"}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    AppFormatters.formatLotacao(user.lotacao),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Chip(
                  label: Text(
                    AppFormatters.formatRole(user.role),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  backgroundColor: AppTheme.primaryDarkColor,
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Editar Perfil e Senha'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PerfilEditView()),
              );
            },
          ),
          // Exibe Gestão de Usuários apenas para Administrador ou Coordenação.
          if (user.isGestor)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Gestão de Usuários'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GestaoUsuariosView()),
                );
              },
            ),
          const Spacer(),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(
              Icons.logout,
              color: AppTheme.statusAltaAtrasada,
            ),
            title: const Text(
              'Sair da Conta',
              style: TextStyle(color: AppTheme.statusAltaAtrasada),
            ),
            onTap: () async {
              Navigator.pop(context);
              await auth.signOut();
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
