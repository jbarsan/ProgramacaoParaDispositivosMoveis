import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../database/banco_helper.dart';
import 'logout.dart';

/// ============================================================================
/// MENU LATERAL (Drawer)
/// ============================================================================
/// Exibe informações do usuário autenticado no FirebaseAuth:
/// - Foto de perfil (photoURL ou inicial do nome como fallback)
/// - Nome do usuário logado (displayName) e e-mail
/// - Quantidade de contatos salvos no Cloud Firestore em tempo real
/// Também permite editar nome/foto de perfil e encerrar a sessão.
class MenuLateral extends StatefulWidget {
  const MenuLateral({super.key});

  @override
  State<MenuLateral> createState() => _MenuLateralState();
}

class _MenuLateralState extends State<MenuLateral> {
  // Instância do FirebaseAuth para ler e atualizar os dados do usuário logado
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Retorna o nome de exibição do usuário.
  /// Se o displayName ainda não tiver sido configurado, usa o texto antes do '@'
  /// do e-mail ou 'Usuário' como fallback.
  String _obterNomeExibicao(User? usuario) {
    final String? displayName = usuario?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final String? email = usuario?.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }

    return 'Usuário';
  }

  /// Abre um diálogo para o usuário definir ou alterar seu nome e URL da foto
  /// de perfil diretamente no FirebaseAuth.
  Future<void> _abrirDialogoEditarPerfil() async {
    final User? usuario = _auth.currentUser;
    if (usuario == null) return;

    // Controladores inicializados com os dados atuais do usuário
    final TextEditingController nomeController = TextEditingController(
      text: usuario.displayName ?? '',
    );
    final TextEditingController fotoUrlController = TextEditingController(
      text: usuario.photoURL ?? '',
    );

    try {
      await showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.manage_accounts, color: Colors.teal),
                SizedBox(width: 8),
                Text('Editar Perfil'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Campo para o nome do usuário
                  TextField(
                    controller: nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome de exibição',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Campo para a URL pública da foto de perfil
                  TextField(
                    controller: fotoUrlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'URL da foto de perfil',
                      hintText: 'https://exemplo.com/foto.jpg',
                      prefixIcon: Icon(Icons.image),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // Botão para cancelar sem salvar
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              // Botão para salvar as alterações no FirebaseAuth
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final String novoNome = nomeController.text.trim();
                  final String novaFoto = fotoUrlController.text.trim();

                  try {
                    // Atualiza nome e URL da foto no perfil do FirebaseAuth
                    await usuario.updateDisplayName(
                      novoNome.isEmpty ? null : novoNome,
                    );
                    await usuario.updatePhotoURL(
                      novaFoto.isEmpty ? null : novaFoto,
                    );
                    // Recarrega os dados locais do usuário autenticado
                    await usuario.reload();

                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();

                    // Atualiza o menu lateral para refletir os novos dados
                    if (mounted) {
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Perfil atualizado com sucesso!'),
                          backgroundColor: Colors.teal.shade700,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro ao atualizar perfil: $e'),
                          backgroundColor: Colors.red.shade700,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      );
    } finally {
      // Libera os controladores ao fechar o diálogo
      nomeController.dispose();
      fotoUrlController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtém o usuário atualmente autenticado no FirebaseAuth
    final User? usuario = _auth.currentUser;
    final String nomeUsuario = _obterNomeExibicao(usuario);
    final String emailUsuario = usuario?.email ?? '';
    final String? fotoUrl = usuario?.photoURL?.trim();
    final bool possuiFoto = fotoUrl != null && fotoUrl.isNotEmpty;
    final String inicial =
        nomeUsuario.isNotEmpty ? nomeUsuario[0].toUpperCase() : '?';

    return Drawer(
      child: Column(
        children: [
          // Cabeçalho do menu lateral com foto de perfil, nome e e-mail do usuário
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.teal),
            accountName: Text(
              nomeUsuario,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(emailUsuario),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              foregroundColor: Colors.teal,
              // Exibe a foto de perfil da URL se existir; caso contrário, mostra a inicial
              backgroundImage: possuiFoto ? NetworkImage(fotoUrl) : null,
              onBackgroundImageError: possuiFoto ? (_, _) {} : null,
              child: possuiFoto
                  ? null
                  : Text(
                      inicial,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          // Exibe em tempo real a quantidade de contatos salvos no Cloud Firestore
          StreamBuilder<int>(
            stream: BancoHelper.observarQuantidadeContatos(),
            builder: (context, snapshot) {
              // Define o texto de acordo com o estado da conexão com o Firestore
              String textoQuantidade;
              if (snapshot.connectionState == ConnectionState.waiting) {
                textoQuantidade = 'Carregando...';
              } else if (snapshot.hasError) {
                textoQuantidade = 'Indisponível';
              } else {
                final int total = snapshot.data ?? 0;
                textoQuantidade =
                    total == 1 ? '1 contato salvo' : '$total contatos salvos';
              }

              return ListTile(
                leading: const Icon(Icons.contacts, color: Colors.teal),
                title: const Text('Contatos salvos'),
                subtitle: Text(textoQuantidade),
                trailing: snapshot.hasData
                    ? CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.teal.shade50,
                        child: Text(
                          '${snapshot.data}',
                          style: TextStyle(
                            color: Colors.teal.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : null,
              );
            },
          ),

          const Divider(),

          // Opção para editar o nome de exibição e a foto de perfil do usuário
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.teal),
            title: const Text('Editar perfil'),
            onTap: _abrirDialogoEditarPerfil,
          ),

          const Spacer(),
          const Divider(),

          // Opção no rodapé do menu para encerrar a sessão chamando o método sair()
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Sair',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            onTap: () {
              // Fecha o menu lateral e executa o logout pelo método sair()
              Navigator.of(context).pop();
              const Logout().sair(context);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
