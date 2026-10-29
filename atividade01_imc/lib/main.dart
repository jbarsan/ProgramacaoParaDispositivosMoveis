import 'package:flutter/material.dart';

// Função principal: Ponto de entrada de toda aplicação Flutter/Dart.
void main() {
  runApp(const ImcApp());
}

/// Widget principal do aplicativo.
/// É um StatelessWidget porque as configurações globais do app (como tema e título)
/// não mudam dinamicamente após a inicialização.
class ImcApp extends StatelessWidget {
  const ImcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Título do aplicativo (usado pelo sistema operacional)
      title: 'Calculadora de IMC',
      // Remove a faixa de "DEBUG" no canto superior direito
      debugShowCheckedModeBanner: false,
      // Define a cor primária e o tema do aplicativo
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
        // Garante suporte ao padrão Material 3 mantendo a cor azul claro
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlue,
          primary: Colors.lightBlue,
        ),
        useMaterial3: false, // Mantém a estética clássica do Material Design conforme a aula
      ),
      // Define a tela inicial do aplicativo
      home: const Home(),
    );
  }
}

/// Tela Principal da Calculadora de IMC.
/// É um StatefulWidget porque a interface precisa mudar quando o usuário
/// calcula o IMC ou reinicia os dados (o texto do resultado muda).
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // ==========================================
  // VARIÁVEIS E CONTROLADORES
  // ==========================================

  // Controladores para capturar o texto digitado nos campos de texto
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();

  // Variável que armazena o texto exibido no resultado
  String _infoText = "Informe seus dados!";

  // ==========================================
  // FUNÇÕES
  // ==========================================

  /// Função responsável por reiniciar os campos e a mensagem na tela.
  void _resetFields() {
    // Limpa o texto dos campos de entrada
    weightController.clear();
    heightController.clear();

    // setState notifica o Flutter de que o estado mudou e a tela deve ser redesenhada
    setState(() {
      _infoText = "Informe seus dados!";
    });
  }

  /// Função responsável por validar os dados e calcular o IMC.
  void _calculate() {
    setState(() {
      // 1. Verifica se os campos estão vazios
      if (weightController.text.trim().isEmpty ||
          heightController.text.trim().isEmpty) {
        _infoText = "Insira seus dados!";
        return; // Interrompe a execução da função se faltar algum dado
      }

      // 2. Converte o texto para número decimal (double)
      // Substitui vírgula por ponto para aceitar tanto "73.5" quanto "73,5"
      double? weight = double.tryParse(
        weightController.text.replaceAll(',', '.'),
      );
      double? height = double.tryParse(
        heightController.text.replaceAll(',', '.'),
      );

      // 3. Verifica se os valores são números válidos e maiores que zero
      if (weight == null || height == null || weight <= 0 || height <= 0) {
        _infoText = "Insira valores válidos!";
        return;
      }

      // 4. Cálculo do IMC:
      // A altura é informada em centímetros (cm), então dividimos por 100 para ter em metros (m).
      // Fórmula: IMC = peso / (altura * altura)
      double heightInMeters = height / 100.0;
      double imc = weight / (heightInMeters * heightInMeters);

      // 5. Estrutura condicional (if / else if / else) para classificar o IMC
      // toStringAsPrecision(4) formata o número com 4 algarismos significativos (ex: 22.04)
      if (imc < 18.6) {
        _infoText = "Abaixo do Peso (${imc.toStringAsPrecision(4)})";
      } else if (imc >= 18.6 && imc < 24.9) {
        _infoText = "Peso Ideal (${imc.toStringAsPrecision(4)})";
      } else if (imc >= 24.9 && imc < 29.9) {
        _infoText = "Levemente Acima do Peso (${imc.toStringAsPrecision(4)})";
      } else if (imc >= 29.9 && imc < 34.9) {
        _infoText = "Obesidade Grau I (${imc.toStringAsPrecision(4)})";
      } else if (imc >= 34.9 && imc < 39.9) {
        _infoText = "Obesidade Grau II (${imc.toStringAsPrecision(4)})";
      } else {
        _infoText = "Obesidade Grau III (${imc.toStringAsPrecision(4)})";
      }
    });
  }

  // ==========================================
  // CONSTRUÇÃO DA INTERFACE (UI)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    // O Scaffold fornece a estrutura visual básica da tela (AppBar, Body, etc.)
    return Scaffold(
      backgroundColor: Colors.white,

      // Barra superior do aplicativo
      appBar: AppBar(
        title: const Text(
          "Calculadora de IMC",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.lightBlue,
        actions: [
          // Botão de reiniciar os dados no canto superior direito
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: "Reiniciar dados",
            onPressed: _resetFields,
          ),
        ],
      ),

      // SingleChildScrollView permite rolar a tela quando o teclado virtual aparece,
      // evitando erros de estouro de tela (overflow).
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          // Alinha os widgets ao centro horizontalmente e estica na largura
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ícone de usuário centralizado no topo
            const Padding(
              padding: EdgeInsets.only(top: 20.0, bottom: 20.0),
              child: Icon(
                Icons.person_outline,
                size: 120.0,
                color: Colors.lightBlue,
              ),
            ),

            // Campo de entrada para o Peso
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.lightBlue, fontSize: 25.0),
              decoration: const InputDecoration(
                labelText: "Peso (kg)",
                labelStyle: TextStyle(color: Colors.lightBlue, fontSize: 20.0),
                // Linha inferior verde quando focado
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.lightBlue, width: 2.0),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.lightBlue),
                ),
              ),
            ),

            const SizedBox(height: 10.0),

            // Campo de entrada para a Altura
            TextField(
              controller: heightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.lightBlue, fontSize: 25.0),
              decoration: const InputDecoration(
                labelText: "Altura (cm)",
                labelStyle: TextStyle(color: Colors.lightBlue, fontSize: 20.0),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.lightBlue, width: 2.0),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.lightBlue),
                ),
              ),
            ),

            const SizedBox(height: 20.0),

            // Botão "Calcular"
            SizedBox(
              height: 50.0,
              child: ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue,
                  elevation: 2.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
                child: const Text(
                  "Calcular",
                  style: TextStyle(color: Colors.white, fontSize: 25.0),
                ),
              ),
            ),

            const SizedBox(height: 15.0),

            // Texto com o resultado ou mensagem informativa
            Text(
              _infoText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.lightBlue,
                fontSize: 22.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
