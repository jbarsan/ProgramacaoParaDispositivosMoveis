import 'package:flutter/material.dart';

/// Classe externa que representa o conteúdo visual da aba "Sol" (Tab 2).
/// Um [StatelessWidget] é utilizado pois a aba exibe conteúdo puramente estático.
class SolTab extends StatelessWidget {
  const SolTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Centraliza o conteúdo da aba no centro da tela.
    return Center(
      // Organiza a imagem, o espaçamento e o texto verticalmente.
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Imagem do sol carregada a partir dos assets locais.
          const Image(
            image: AssetImage('assets/images/sun.png'),
            height: 150, // Altura padronizada para manter consistência entre as abas.
          ),

          // Espaçamento vertical entre a imagem e o container de texto.
          const SizedBox(height: 24),

          // Container estilizado para destacar a mensagem do Sol.
          Container(
            // Margem externa para não encostar nas bordas horizontais da tela.
            margin: const EdgeInsets.symmetric(horizontal: 24),
            // Espaçamento interno (padding) ao redor do texto.
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            // Decoração com tons de amarelo/âmbar para combinar com o tema de Sol.
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            // Texto que exibe a mensagem poética da aba Sol.
            child: const Text(
              '....o Sol sorri de lá do céu....',
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
