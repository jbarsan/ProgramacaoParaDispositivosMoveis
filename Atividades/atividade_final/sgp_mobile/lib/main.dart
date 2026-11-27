import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'controllers/admin_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/demanda_controller.dart';
import 'controllers/map_controller.dart';
import 'controllers/notificacao_controller.dart';
import 'controllers/viagem_controller.dart';
import 'firebase_options.dart';
import 'models/user_model.dart';
import 'utils/app_theme.dart';
import 'views/auth/aguardando_aprovacao_view.dart';
import 'views/auth/login_view.dart';
import 'views/home/main_navigation_view.dart';

// Ponto de entrada do SGP Mobile (CPPT/MPPI).
//
// Carrega variáveis de ambiente (`.env`), inicializa o Firebase e injeta
// os controllers reativos via `MultiProvider`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SgpMobileApp());
}

// Widget raiz da aplicação com tema institucional do MPPI.
class SgpMobileApp extends StatelessWidget {
  const SgpMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthController()..startListening(),
        ),
        ChangeNotifierProvider(create: (_) => AdminController()),
        ChangeNotifierProvider(create: (_) => DemandaController()),
        ChangeNotifierProvider(create: (_) => ViagemController()),
        ChangeNotifierProvider(create: (_) => MapController()),
        ChangeNotifierProvider(create: (_) => NotificacaoController()),
      ],
      child: MaterialApp(
        title: 'SGP Mobile — CPPT/MPPI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
      ),
    );
  }
}

// Portão de autenticação (`AuthGate`) responsável pelo roteamento inicial:
// - Não logado -> [LoginView]
// - Logado com `ativo == false` ou `role == 'pendente'` -> [AguardandoAprovacaoView]
// - Logado e aprovado -> [MainNavigationView]
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  // Função pura que decide qual tela exibir a partir do perfil atual.
  // Exposta como método estático para facilitar testes de widget/unidade.
  static Widget resolveHome(UserModel? user) {
    if (user == null) {
      return const LoginView();
    }
    if (!user.isAprovado) {
      return const AguardandoAprovacaoView();
    }
    return const MainNavigationView();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return resolveHome(auth.currentUser);
  }
}
