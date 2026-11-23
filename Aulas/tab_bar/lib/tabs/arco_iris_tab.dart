import 'package:flutter/material.dart';

/// Classe externa que representa o conteúdo visual da aba "Arco-íris" (Tab 3).
/// Um [StatelessWidget] é suficiente para renderizar a imagem e a mensagem estática.
class ArcoIrisTab extends StatelessWidget {
  const ArcoIrisTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Centraliza todo o conteúdo da aba na tela.
    return Center(
      // Organização vertical dos widgets filhos.
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Imagem do arco-íris obtida da pasta assets/images/.
          const Image(
            image: AssetImage('assets/images/arco-iris.png'),
            height: 150, // Altura padronizada para manter consistência visual com as outras abas.
          ),

          // Espaçamento vertical entre a imagem e o container de texto.
          const SizedBox(height: 24),

          // Container com estilo visual personalizado para a mensagem do Arco-íris.
          Container(
            // Margem externa para afastamento das bordas da tela.
            margin: const EdgeInsets.symmetric(horizontal: 24),
            // Espaçamento interno entre as bordas do Container e o Text.
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            // Decoração com tons arroxeados/violetas que harmonizam com o arco-íris.
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.shade200),
            ),
            // Texto com a mensagem da aba Arco-íris.
            child: const Text(
              '....e o arco-íris surge ao léu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
