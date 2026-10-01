import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Calculadora de Gasolina ou Álcool',
      theme: ThemeData(
        primaryColor: Colors.blue[800],
        // O ColorScheme.fromSeed cria um ColorScheme completo (cores
        // primárias, secundárias, etc.) a partir de uma cor inicial (seedColor)
        // o '!' no final é um operador de negação nula (null assertion operator).
        // Ele é usado para informar ao compilador que, embora a variável
        // _textEditeControllerGasolina.text possa ser nula teoricamente,
        // neste ponto específico do código, temos certeza absoluta de que ela
        // terá um valor válido (não será null). Se a variável for null
        // realmente, o código irá gerar um erro em tempo de execução (runtime error)
        // em vez de apenas compilar com aviso.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue[800]!),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Gasolina x Álcool'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _textEditeControllerGasolina =
      TextEditingController();
  final TextEditingController _textEditeControllerAlcool =
      TextEditingController();
  double? _eficiencia;
  String? _resultadoTexto;
  String? _erro;

  // Funções
  double _calculaEficiencia(double gasolina, double alcool) {
    return (alcool / gasolina) * 100;
  }

  void _calcular() {
    setState(() {
      _erro = null;
      _resultadoTexto = null;
      _eficiencia = null;

      // Verificando se os campos estão vazios
      if (_textEditeControllerAlcool.text.trim().isEmpty ||
          _textEditeControllerGasolina.text.trim().isEmpty) {
        _erro = 'Preencha os campos de gasolina e álcool';
        return;
      }

      // Converte o texto para número decimal (double)
      // Substitui vírgula por ponto para aceitar tanto 5.49 quanto 5,49
      double? gasolina = double.tryParse(
        _textEditeControllerGasolina.text.replaceAll(',', '.'),
      );
      double? alcool = double.tryParse(
        _textEditeControllerAlcool.text.replaceAll(',', '.'),
      );

      // Verifica se os valores são válidos
      if (gasolina == null || alcool == null || gasolina <= 0 || alcool <= 0) {
        _erro = 'Por favor, insira valores válidos maiores que zero';
        return;
      }

      // Logica de cálculo (álcool / gasolina * 100)
      double eficiencia = _calculaEficiencia(gasolina, alcool);
      _eficiencia = eficiencia;

      // Logica de decisão:
      // O álcool é mais vantajoso se custar até 70% do preço da gasolina (<= 70%)
      if (eficiencia <= 70) {
        _resultadoTexto = 'O Álcool é mais vantajoso!';
      } else {
        _resultadoTexto = 'A Gasolina é mais vantajosa!';
      }
    });
  }

  // Todo controller deve ser descartado para liberar memória
  @override
  void dispose() {
    _textEditeControllerGasolina.dispose();
    _textEditeControllerAlcool.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Imagem da bomba centralizada e acima das caixas de texto
              SvgPicture.asset(
                // SvgPicture trabalha com arquivos vetoriais (SVG)
                'assets/images/gas-station-red-pump.svg',
                height: 120, // Altura da imagem
                fit: BoxFit.contain, // Ajuste da imagem
              ),
              const SizedBox(height: 24), // Espaçamento
              // Campo do preço da gasolina
              TextField(
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Preço da gasolina (R\$)',
                  border: OutlineInputBorder(), // Estilo da borda do campo
                  prefixText: 'R\$ ', // Prefixo que aparece antes do texto
                ),
                controller: _textEditeControllerGasolina,
              ),
              const SizedBox(height: 16),

              // Campo do preço do álcool
              TextField(
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Preço do álcool (R\$)',
                  border: OutlineInputBorder(),
                  prefixText: 'R\$ ',
                ),
                controller: _textEditeControllerAlcool,
              ),
              const SizedBox(height: 20),

              // Caixa onde aparece o resultado
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _calcular, // chamando a função _calcular
                  child: const Text('Calcular', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),

              if (_erro != null) // se o erro não for nulo, ele aparece
                Text(
                  _erro!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

              // Se o resultado não for nulo, ele aparece
              // O ...[...] serve para inserir múltiplos widgets de uma só vez
              // dentro do children usando um único if, sem precisar repetir a
              // condição para cada elemento.
              if (_resultadoTexto != null && _eficiencia != null) ...[
                Card(
                  elevation: 2, // profundidade do card (sombra)
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      12,
                    ), // bordas arredondadas
                  ),

                  child: Padding(
                    padding: const EdgeInsets.all(16.0), // espaçamento interno
                    child: Column(
                      children: [
                        Text(
                          'Relação de preços: ${_eficiencia!.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Text(
                          _resultadoTexto!,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            // A expressão ?: é uma expressão condicional
                            //Ela é usada para escolher um valor com base em uma condição
                            //Se a condição _eficiencia! <= 70 for verdadeira,
                            // o valor retornado será Colors.green[700]
                            //Caso contrário, o valor retornado será Colors.blue[800]
                            color: _eficiencia! <= 70
                                ? Colors.green[700]
                                : Colors.blue[800],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
