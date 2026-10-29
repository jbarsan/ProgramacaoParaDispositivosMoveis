import 'package:flutter/material.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        // visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final items = <Item>[
    Item(nome: "Arroz", check: true),
    Item(nome: "Feijão", check: true),
    Item(nome: "Farinha", check: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Text("OP"), // menu IconButton no canto esquerdo do appBar
        title: Text("Home"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: <Widget>[
          // menu IconButton no canto direito appBar
          Icon(Icons.local_grocery_store),
        ],
      ),

      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) {
          final item = items[index]; // para evitar a repetição
          return CheckboxListTile(
            title: Text(item.nome),
            key: Key(item.nome),
            value: item.check,
            onChanged: (value) {
              setState(() {
                item.check = value! ? true : false;
                // item.check = value ?? false;
              });
            },
          );
        },
      ),
    );
  }
}

class Item {
  String nome;
  bool check;

  Item({required this.nome, required this.check});
}
