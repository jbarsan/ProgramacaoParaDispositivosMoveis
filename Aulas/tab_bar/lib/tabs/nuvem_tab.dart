import 'package:flutter/material.dart';

/// Classe externa que representa o conteúdo visual da aba "Nuvem" (Tab 1).
/// Um [StatelessWidget] é utilizado pois esta tela apenas exibe conteúdo estático
/// (imagem e texto), sem necessidade de gerenciar estado interno dinâmico.
class NuvemTab extends StatelessWidget {
  const NuvemTab({super.key});

  @override
  Widget build(BuildContext context) {
    // O widget Center centraliza todo o conteúdo no espaço disponível da tela.
    return Center(
      // A Column organiza seus filhos de forma vertical (em coluna).
      child: Column(
        // Alinha os elementos verticalmente no centro da coluna.
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Exibe a imagem dos assets configurada no pubspec.yaml.
          const Image(
            image: AssetImage('assets/images/cloud.png'),
            height: 150, // Define a altura da imagem para manter proporção visual.
          ),

          // SizedBox é utilizado para criar um espaçamento fixo entre a imagem e o container de texto.
          const SizedBox(height: 24),

          // Container com decoração para destacar o texto com estilo de cartão.
          Container(
            // Margem externa para afastar o container das laterais da tela.
            margin: const EdgeInsets.symmetric(horizontal: 24),
            // Espaçamento interno entre a borda do Container e o Text.
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            // Decoração visual: cor de fundo suave, borda colorida e cantos arredondados.
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            // Widget Text que exibe a mensagem poética da aba Nuvem.
            child: const Text(
              'A nuvem flutua sem parar, formas de sonhos vem mostrar....',
              textAlign: TextAlign.center, // Centraliza o texto dentro do container.
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
