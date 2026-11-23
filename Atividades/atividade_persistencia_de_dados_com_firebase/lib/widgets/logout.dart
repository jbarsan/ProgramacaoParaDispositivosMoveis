import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

/// ============================================================================
/// CLASSE LOGOUT
/// ============================================================================
/// Widget responsável por encerrar a sessão do usuário autenticado no Firebase.
/// Contém o método [sair] acionado ao clicar no botão de logout.
class Logout extends StatelessWidget {
  const Logout({super.key});

  /// Método responsável por desconectar o usuário do Firebase Authentication.
  Future<void> sair(BuildContext context) async {
    // Obtém a instância do FirebaseAuth
    final FirebaseAuth auth = FirebaseAuth.instance;

    try {
      // Encerra a sessão atual no Firebase.
      // O StreamBuilder em main.dart detectará a saída e voltará para a TelaLogin.
      await auth.signOut();
    } catch (e) {
      // Exibe mensagem caso ocorra algum erro ao tentar sair
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao sair da conta: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Botão de ícone exibido na barra superior que chama o método sair()
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Sair',
      onPressed: () => sair(context),
    );
  }
}
