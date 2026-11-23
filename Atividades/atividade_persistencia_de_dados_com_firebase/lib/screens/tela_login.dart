import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

// ============================================================================
// TELA DE LOGIN
// ============================================================================
// Estrutura principal (Scaffold) exibida quando o usuário não está autenticado.
// O corpo (body) desta tela recebe a classe [Login].
class TelaLogin extends StatelessWidget {
  const TelaLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra superior da tela de login
      appBar: AppBar(
        title: const Text('Acesso ao Sistema'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      // Adiciona a classe Login ao body da tela de login
      body: const Login(),
    );
  }
}

// ============================================================================
// CLASSE LOGIN (Formulário e Autenticação com FirebaseAuth)
// ============================================================================
// Responsável pelos campos de e-mail e senha, pelos controladores de texto,
// pela instância do FirebaseAuth e pelo método de autenticação.
class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // Instância do FirebaseAuth usada para autenticar o usuário no Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Chave global para validar os campos do formulário
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controladores para capturar o e-mail e a senha digitados pelo usuário
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  // Controla o estado de carregamento durante a requisição ao Firebase
  bool _carregando = false;

  // Controla se a senha está oculta ou visível no campo de texto
  bool _ocultarSenha = true;

  @override
  void dispose() {
    // Libera os recursos dos controladores quando o widget for descartado
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  /// Método de autenticação com o Firebase usando e-mail e senha.
  /// Se [criarConta] for true, cria um novo usuário no Firebase Authentication.
  Future<void> _autenticar({bool criarConta = false}) async {
    // Valida o formulário antes de enviar os dados ao Firebase
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Ativa o indicador de carregamento
    setState(() => _carregando = true);

    final String email = _emailController.text.trim();
    final String senha = _senhaController.text.trim();

    try {
      if (criarConta) {
        // Cria uma nova conta no Firebase Authentication
        await _auth.createUserWithEmailAndPassword(
          email: email,
          password: senha,
        );
      } else {
        // Realiza o login de um usuário já cadastrado no Firebase Authentication
        await _auth.signInWithEmailAndPassword(email: email, password: senha);
      }
      // Após autenticar com sucesso, o StreamBuilder no main.dart
      // redireciona automaticamente para a TelaPrincipal.
    } on FirebaseAuthException catch (e) {
      // Traduz os códigos de erro mais comuns do FirebaseAuth para português
      String mensagem = 'Erro na autenticação: ${e.message ?? e.code}';
      if (e.code == 'user-not-found') {
        mensagem = 'Usuário não encontrado para este e-mail.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        mensagem = 'E-mail ou senha inválidos.';
      } else if (e.code == 'invalid-email') {
        mensagem = 'O formato do e-mail informado é inválido.';
      } else if (e.code == 'email-already-in-use') {
        mensagem = 'Este e-mail já está cadastrado.';
      } else if (e.code == 'weak-password') {
        mensagem = 'A senha deve ter pelo menos 6 caracteres.';
      }

      // Exibe a mensagem de erro caso a tela ainda esteja montada
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensagem),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Trata qualquer outro erro inesperado
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro inesperado ao autenticar: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      // Desativa o indicador de carregamento ao finalizar
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ícone ilustrativo no topo do formulário
              const Icon(Icons.lock_outline, size: 72, color: Colors.teal),
              const SizedBox(height: 12),

              // Título da tela
              const Text(
                'Login',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Subtítulo informativo
              const Text(
                'Informe seu e-mail e senha para acessar a agenda de contatos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),

              // Campo de texto para o E-mail
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'E-mail',
                  hintText: 'Ex: usuario@email.com',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Por favor, digite seu e-mail.';
                  }
                  if (!valor.contains('@') || !valor.contains('.')) {
                    return 'Por favor, informe um e-mail válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo de texto para a Senha
              TextFormField(
                controller: _senhaController,
                obscureText: _ocultarSenha,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  hintText: 'Digite sua senha',
                  prefixIcon: const Icon(Icons.lock),
                  // Botão para alternar a visibilidade da senha
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultarSenha ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _ocultarSenha = !_ocultarSenha);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Por favor, digite sua senha.';
                  }
                  if (valor.trim().length < 6) {
                    return 'A senha deve ter no mínimo 6 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Botão principal para realizar login no Firebase
              ElevatedButton.icon(
                onPressed: _carregando ? null : () => _autenticar(),
                icon: _carregando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.login),
                label: Text(
                  _carregando ? 'Entrando...' : 'Entrar',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Botão secundário para criar uma nova conta no Firebase
              TextButton(
                onPressed: _carregando
                    ? null
                    : () => _autenticar(criarConta: true),
                child: const Text('Não tem conta? Cadastrar-se'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
