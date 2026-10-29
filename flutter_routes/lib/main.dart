import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Named Routes Demo',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: Colors.blue,
        ),
        useMaterial3: true,
      ),

      initialRoute: '/',
      routes: {
        '/': (context) => FirstScreen(),
        '/second': (context) => SecondScreen(),
      },
    );
  }
}

class FirstScreen extends StatelessWidget {
  const FirstScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Primeira página'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // centralizar verticalmente
          children: [
            const Text(
              'Palmeiras...',
              style: TextStyle(
                color: Colors.green,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10), // espaçamento entre o texto e o botão
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/second');
              },
              child: const Text('Ir para a segunda página'),
            ),
          ],
        ),
      ),
    );
  }
}

class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Segunda página'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // centralizar verticalmente
          children: [
            const Text(
              '...não tem mundial!!',
              style: TextStyle(
                color: Colors.pink,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10), // espaçamento entre o texto e o botão
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Voltar para a primeira página'),
            ),
          ],
        ),
      ),
    );
  }
}
