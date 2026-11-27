import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../utils/app_theme.dart';

// Tela de cadastro de novo servidor no SGP Mobile (RF-001).
//
// Todo usuário comum cadastrado inicia com `role: pendente` e `ativo: false`,
// sendo direcionado automaticamente pelo `AuthGate` à tela de espera.
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _matriculaController = TextEditingController();
  final _cargoController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _matriculaController.dispose();
    _cargoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final ok = await auth.register(
      nome: _nomeController.text,
      email: _emailController.text,
      matricula: _matriculaController.text,
      cargo: _cargoController.text,
      password: _passwordController.text,
    );

    if (ok && mounted) {
      Navigator.pop(context);
    } else if (!ok && mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppTheme.statusAltaAtrasada,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro de Servidor')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome completo',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => (v == null || v.trim().length < 3)
                        ? 'Informe seu nome completo.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail institucional',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Informe um e-mail válido.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _matriculaController,
                    decoration: const InputDecoration(
                      labelText: 'Matrícula',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe sua matrícula.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _cargoController,
                    decoration: const InputDecoration(
                      labelText: 'Cargo / Função',
                      prefixIcon: Icon(Icons.work_outline),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe seu cargo.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Senha (mínimo 6 caracteres)',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'A senha deve ter pelo menos 6 caracteres.'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: auth.isLoading ? null : _submitRegister,
                    child: auth.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Solicitar Acesso'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
