// Importa o pacote principal do Flutter contendo o Material Design (botões, barras, temas, etc.)
import 'package:flutter/material.dart';

// A função main() é a porta de entrada do aplicativo. Tudo começa por aqui.
void main() {
  // Inicializa e roda o widget principal do nosso aplicativo (MyApp)
  runApp(const MyApp());
}

// StatelessWidget é um widget que NÃO muda de estado, ou seja, sua interface é estática.
class MyApp extends StatelessWidget {
  // Construtor da classe que permite a otimização de performance usando o "const"
  const MyApp({super.key});

  // O método build reconstrói a tela quando o widget é inserido na árvore de componentes
  @override
  Widget build(BuildContext context) {
    // MaterialApp configura as definições globais do app (como rotas, temas e títulos)
    return MaterialApp(
      title: 'Primeiro programa', // Título que o sistema operacional lê (ex: nas telas de apps recentes)
      home: const MyHomePage(), // Define qual será a primeira tela exibida ao abrir o app
      debugShowCheckedModeBanner:
          false, // Remove a faixa vermelha de "Debug" do canto superior direito
    );
  }
}

// StatefulWidget é um widget DINÂMICO. Ele consegue atualizar a tela quando os dados mudam.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  // Cria o estado interno (_MyHomePageState) onde a mágica das atualizações acontece
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// Esta classe gerencia o estado e desenha o conteúdo visual da nossa tela principal
class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // Scaffold é a estrutura/esqueleto base de uma tela (fornece App Bar, Body, Drawer, etc.)
    return Scaffold(
      // AppBar é a barra de ferramentas localizada no topo da tela
      appBar: AppBar(
        title: const Text("App Zelda"), // Texto exibido na barra superior
        backgroundColor: Colors.blue, // Cor de fundo da barra superior
      ),

      // Drawer cria aquele menu lateral que desliza da esquerda para a direita
      drawer: Drawer(
        // ListView permite empilhar itens verticalmente e adiciona rolagem caso a tela seja pequena
        child: ListView(
          padding: EdgeInsets.zero, // Remove as margens internas padrão para preencher todo o topo
          children: [
            // Componente específico do Flutter para criar cabeçalhos de perfil de usuário
            const UserAccountsDrawerHeader(
              accountName: Text("João Carlos Barsan"), // Nome do usuário logado
              accountEmail: Text(
                "joao_barsan@teste.com.br",
              ), // E-mail do usuário logado
              currentAccountPicture: CircleAvatar(
                // Componente para criar fotos circulares
                backgroundColor:
                    Colors.white, // Cor de fundo caso a imagem falhe
                backgroundImage: AssetImage(
                  "images/garoto.png",
                ), // Caminho da foto guardada na pasta local
              ),
              decoration: BoxDecoration(
                color: Colors.blue,
              ), // Estilização e cor de fundo do cabeçalho
            ),

            // ListTile cria uma linha clicável com ícone e texto ordenados
            ListTile(
              leading: const Icon(
                Icons.account_balance_wallet,
              ), // Ícone que fica no início (esquerda)
              title: const Text("Saldo"), // Texto principal do item
              onTap: () {
                // Ação/função executada ao clicar no item. No momento está vazia.
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text("Extrato"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text("Pagamentos"),
              onTap: () {},
            ),
          ],
        ),
      ),

      // Body é o corpo principal da tela (o espaço que sobra abaixo da AppBar e acima da BottomBar)
      body: Center(
        // Center centraliza o seu componente filho tanto na horizontal quanto na vertical
        child: Column(
          children: [
            const Text("Bem-vindo à lenda de Zelda!!"),
            // Image.network(
            //   'https://im.ziffdavisinternational.com/ign_br/screenshot/default/screenshot-2_5s54.png',
            // ),
            Image.asset("images/link.png", height: 500),
          ],
        ), // Exibe o texto centralizado na tela
      ),

      // BottomNavigationBar cria uma barra de navegação com abas fixa no rodapé do app
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          // Cada item precisa obrigatoriamente de um ícone e de um rótulo (label)
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
