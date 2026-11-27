import 'package:material_ui/material_ui.dart';

import '../../controllers/demanda_controller.dart';

// Diálogo modal que exige justificativa textual obrigatória para pausar
// uma demanda em andamento (RF-010).
class PausaDialog extends StatefulWidget {
  const PausaDialog({super.key});

  // Exibe o diálogo e retorna a justificativa validada, ou `null` se cancelado.
  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (_) => const PausaDialog(),
    );
  }

  @override
  State<PausaDialog> createState() => _PausaDialogState();
}

class _PausaDialogState extends State<PausaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _justificativaController = TextEditingController();

  @override
  void dispose() {
    _justificativaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pausar Demanda'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informe o motivo da pausa. Esta justificativa será registrada na linha do tempo da demanda.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _justificativaController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Justificativa obrigatória',
                hintText: 'Ex.: Aguardando documentação complementar da promotoria...',
              ),
              validator: DemandaController.validarJustificativaPausa,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _justificativaController.text.trim());
            }
          },
          child: const Text('Confirmar Pausa'),
        ),
      ],
    );
  }
}
