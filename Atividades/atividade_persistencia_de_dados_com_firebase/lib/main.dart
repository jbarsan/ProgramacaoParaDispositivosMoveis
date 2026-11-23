import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';

import 'firebase_options.dart';
import 'screens/tela_login.dart';
import 'screens/tela_principal.dart';

Future<void> main() async {
  // Garante a inicialização dos bindings do Flutter antes de chamar o Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase com as configurações geradas pelo FlutterFire CLI
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gerenciador de Contatos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
      ),
      // Escuta em tempo real as mudanças de autenticação do FirebaseAuth:
      // - Se houver usuário autenticado, abre a TelaPrincipal (Agenda).
      // - Caso contrário, exibe a TelaLogin.
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Enquanto verifica o estado inicial de login, mostra carregamento
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Usuário autenticado -> vai para a tela principal com botão de Logout
          if (snapshot.hasData) {
            return const TelaPrincipal();
          }

          // Usuário não autenticado -> vai para a tela de Login
          return const TelaLogin();
        },
      ),
    );
  }
}
