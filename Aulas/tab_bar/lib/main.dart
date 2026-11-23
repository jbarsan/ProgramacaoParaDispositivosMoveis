import 'package:flutter/material.dart';

// Importação das classes externas criadas para representar o conteúdo de cada aba.
import 'tabs/arco_iris_tab.dart';
import 'tabs/nuvem_tab.dart';
import 'tabs/sol_tab.dart';

/// Ponto de entrada principal da aplicação Flutter.
void main() {
  runApp(const MyApp());
}

/// Widget raiz da aplicação.
/// Define configurações globais como tema e a tela inicial (home).
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter TabBar',
      // Desativa o banner de "DEBUG" no canto superior direito da tela.
      debugShowCheckedModeBanner: false,
      // Define a paleta de cores principal a partir de uma cor semente (deepPurple).
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
        ), // Aplica a centralização em todas as AppBar.
      ),
      home: const MyHomePage(title: 'Poema: Nuvem Branca'),
    );
  }
}

/// Tela principal do aplicativo.
/// É um [StatefulWidget] porque gerencia o estado da navegação entre abas
/// e responde dinamicamente a interações do usuário.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

/// Estado da tela principal.
/// Utiliza o mixin [SingleTickerProviderStateMixin] para fornecer o 'vsync'
/// necessário para o funcionamento do controlador de animação das abas ([TabController]).
class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  // Controlador responsável por sincronizar o TabBar, TabBarView e BottomNavigationBar.
  late TabController _tabController;

  // Lista com os versos de cada estrofe do poema.
  final List<String> _mensagens = const <String>[
    'A nuvem flutua sem parar,\nformas de sonhos vem mostrar.',
    'O Sol sorri de lá do céu.',
    'E o arco-íris surge ao léu.',
  ];

  @override
  void initState() {
    super.initState();
    // Inicializa o TabController com 3 abas, associando o 'vsync' a esta classe.
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    // Libera a memória alocada pelo controlador ao destruir o widget.
    _tabController.dispose();
    super.dispose();
  }

  /// Exibe um diálogo simples (AlertDialog) com o poema completo reunido.
  void _exibirPoemaCompleto() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Poema: Nuvem Branca', textAlign: TextAlign.center),
          content: Text(
            _mensagens.join('\n\n'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, height: 1.4),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Fecha o diálogo
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  /// Exibe uma mensagem informativa sobre a atividade.
  void _exibirSobre() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Atividade de Dispositivos Móveis: TabBar'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Exibe uma mensagem rápida de interação poética.
  void _curtirPoema() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Você curtiu este belo poema! ❤️'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold fornece a estrutura visual da tela (AppBar, Body, FAB e BottomAppBar).
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // TabBar para alternar entre as 3 abas poéticas no topo.
        bottom: TabBar(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(icon: Icon(Icons.cloud_outlined), text: 'Nuvem'),
            Tab(icon: Icon(Icons.brightness_5_sharp), text: 'Sol'),
            Tab(icon: Icon(Icons.looks), text: 'Arco-íris'),
          ],
        ),
      ),

      // TabBarView renderiza o conteúdo da aba selecionada (Nuvem, Sol ou Arco-íris).
      body: TabBarView(
        controller: _tabController,
        children: const <Widget>[
          NuvemTab(), // Aba 0: Imagem da nuvem + estrofe
          SolTab(), // Aba 1: Imagem do sol + estrofe
          ArcoIrisTab(), // Aba 2: Imagem do arco-íris + estrofe
        ],
      ),

      // Botão Flutuante (FAB) posicionado no centro da barra inferior.
      // Ao ser clicado, chama a função _exibirPoemaCompleto().
      floatingActionButton: FloatingActionButton(
        onPressed: _exibirPoemaCompleto,
        tooltip: 'Ler Poema Completo',
        child: const Icon(Icons.menu_book),
      ),

      // Centraliza e encaixa o botão flutuante no recorte da BottomAppBar.
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Barra inferior (BottomAppBar) com formato recortado (notched) para o FAB.
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(), // Recorte arredondado para o botão
        notchMargin: 8.0, // Espaçamento entre o botão e o recorte da barra
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            // Botão da esquerda: Informações sobre o poema/trabalho
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'Sobre',
              onPressed: _exibirSobre,
            ),

            // Espaço reservado no centro para o botão flutuante não sobrepor os ícones
            const SizedBox(width: 48),

            // Botão da direita: Curtir o poema
            IconButton(
              icon: const Icon(Icons.favorite_border),
              tooltip: 'Curtir',
              onPressed: _curtirPoema,
            ),
          ],
        ),
      ),
    );
  } // build
} // _MyHomePageState
