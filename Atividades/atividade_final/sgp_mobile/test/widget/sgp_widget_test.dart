import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sgp_mobile/controllers/auth_controller.dart';
import 'package:sgp_mobile/main.dart';
import 'package:sgp_mobile/models/user_model.dart';
import 'package:sgp_mobile/utils/app_theme.dart';
import 'package:sgp_mobile/views/auth/aguardando_aprovacao_view.dart';
import 'package:sgp_mobile/views/auth/login_view.dart';
import 'package:sgp_mobile/views/home/main_navigation_view.dart';
import 'package:sgp_mobile/views/widgets/app_drawer.dart';

/// Dublê de [AuthController] em memória para testes de widget sem Firebase real.
class FakeAuthController extends ChangeNotifier implements AuthController {
  final UserModel? _user;

  FakeAuthController([this._user]);

  @override
  UserModel? get currentUser => _user;

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Testes de widget obrigatórios cobrindo Login, Aguardando Aprovação e Drawer.
void main() {
  testWidgets('Renderiza LoginView com campos de e-mail, senha e botão Google',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthController>(
        create: (_) => FakeAuthController(null),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginView(),
        ),
      ),
    );

    expect(find.text('SGP Mobile'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Entrar com Google'), findsOneWidget);
    expect(find.text('Cadastre-se'), findsOneWidget);
  });

  testWidgets('Exibe AguardandoAprovacaoView para perfis pendentes/inativos',
      (tester) async {
    final pendente = UserModel(
      uid: 'u-pendente',
      nome: 'Carlos Pendente',
      email: 'carlos@mppi.mp.br',
      matricula: '4321',
      cargo: 'Perito',
      role: 'pendente',
      ativo: false,
      createdAt: DateTime(2026, 11, 24),
    );

    // Verifica também o roteamento do AuthGate.
    expect(AuthGate.resolveHome(null), isA<LoginView>());
    expect(AuthGate.resolveHome(pendente), isA<AguardandoAprovacaoView>());
    expect(
      AuthGate.resolveHome(pendente.copyWith(role: 'servidor', ativo: true)),
      isA<MainNavigationView>(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthController>(
        create: (_) => FakeAuthController(pendente),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AguardandoAprovacaoView(),
        ),
      ),
    );

    expect(
      find.text('Aguardando Autorização da Coordenação'),
      findsOneWidget,
    );
    expect(find.text('Atualizar Status'), findsOneWidget);
  });

  testWidgets(
      'AppDrawer exibe Gestão de Usuários apenas para Administrador/Coordenação',
      (tester) async {
    final servidor = UserModel(
      uid: 's1',
      nome: 'Ana Servidora',
      email: 'ana@mppi.mp.br',
      matricula: '100',
      cargo: 'Perita',
      lotacao: 'PSI',
      role: 'servidor',
      ativo: true,
      createdAt: DateTime(2026, 11, 24),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthController>(
        create: (_) => FakeAuthController(servidor),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: AppDrawer()),
        ),
      ),
    );
    expect(find.text('Gestão de Usuários'), findsNothing);

    final coordenador = servidor.copyWith(role: 'coordenacao');
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthController>(
        key: const ValueKey('coordenador_provider'),
        create: (_) => FakeAuthController(coordenador),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: AppDrawer()),
        ),
      ),
    );
    expect(find.text('Gestão de Usuários'), findsOneWidget);
  });
}
