import 'package:flutter/material.dart';

import '../database/banco_helper.dart';
import '../models/contato.dart';

/// ============================================================================
/// ABA 1: TELA / FORMULÁRIO DE CADASTRO (Armazenar)
/// ============================================================================
class AbaCadastro extends StatefulWidget {
  // Callback disparado quando um contato for salvo com sucesso
  final VoidCallback onContatoSalvo;

  const AbaCadastro({super.key, required this.onContatoSalvo});

  @override
  State<AbaCadastro> createState() => _AbaCadastroState();
}

class _AbaCadastroState extends State<AbaCadastro> {
  // Controladores de texto para ler o que o usuário digita
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Chave global para validar o formulário
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Método responsável por validar os campos e inserir no banco SQLite
  Future<void> _salvarContato() async {
    // 1. Valida se os campos não estão vazios ou com dados incorretos
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String nome = _nomeController.text.trim();
    final String email = _emailController.text.trim();

    // 2. Cria o objeto Contato e salva usando o BancoHelper
    final novoContato = Contato(nome: nome, email: email);
    await BancoHelper.inserirContato(novoContato);

    // 3. Limpa os campos após a inserção bem-sucedida
    _nomeController.clear();
    _emailController.clear();

    // 4. MENSAGEM DE CONFIRMAÇÃO DE INSERÇÃO (SnackBar)
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Contato cadastrado com sucesso!'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      // Notifica a tela principal para atualizar a lista e alternar para a aba 2
      widget.onContatoSalvo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.contact_phone_outlined,
              size: 72,
              color: Colors.teal,
            ),
            const SizedBox(height: 12),
            const Text(
              'Novo Contato',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Preencha os campos abaixo para salvar o contato na agenda.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),

            // Campo de Nome
            TextFormField(
              controller: _nomeController,
              decoration: InputDecoration(
                labelText: 'Nome Completo',
                hintText: 'Ex: Maria Francisca Barsan',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return 'Por favor, digite o nome do contato.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Campo de E-mail
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'E-mail',
                hintText: 'Ex: maria@email.com',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return 'Por favor, digite o e-mail.';
                }
                if (!valor.contains('@') || !valor.contains('.')) {
                  return 'Por favor, informe um e-mail válido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Botão Salvar
            ElevatedButton.icon(
              onPressed: _salvarContato,
              icon: const Icon(Icons.save),
              label: const Text(
                'Salvar Contato',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          ],
        ),
      ),
    );
  }
}
