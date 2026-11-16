import 'package:flutter/material.dart';

import 'aba_cadastro.dart';
import 'aba_consulta.dart';

/// ============================================================================
/// TELA PRINCIPAL: ESTRUTURA COM ABAS (TabBar & TabBarView)
/// ============================================================================
class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal>
    with SingleTickerProviderStateMixin {
  // Controlador para alternar entre as duas abas
  late TabController _tabController;

  // Chave global para conseguir chamar o método recarregarContatos da AbaConsulta
  final GlobalKey<AbaConsultaState> _consultaKey =
      GlobalKey<AbaConsultaState>();

  @override
  void initState() {
    super.initState();
    // 2 abas: [0] Cadastrar e [1] Consultar
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Chamado automaticamente quando um contato é salvo na Aba 1
  void _aoSalvarContato() {
    // 1. Recarrega os contatos na Aba 2
    _consultaKey.currentState?.recarregarContatos();

    // 2. Transiciona suavemente para a Aba 2 (Consultar)
    _tabController.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda de Contatos'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 2,
        // BARRA DE ABAS
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3.0,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.person_add), text: 'Cadastrar'),
            Tab(icon: Icon(Icons.people), text: 'Consultar'),
          ],
        ),
      ),
      // CONTEÚDO DAS ABAS
      body: TabBarView(
        controller: _tabController,
        children: [
          // ABA 1: Formulário de Inserção
          AbaCadastro(onContatoSalvo: _aoSalvarContato),

          // ABA 2: Lista com Consulta, Alterar e Excluir
          AbaConsulta(key: _consultaKey),
        ],
      ),
    );
  }
}
