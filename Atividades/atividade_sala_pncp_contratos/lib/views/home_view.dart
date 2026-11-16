import 'package:material_ui/material_ui.dart';

import 'abas/aba_contratos_view.dart';
import 'abas/abas_atas_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Consulta PNCP - Contratos e Atas'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.assignment_outlined),
                text: 'Contratos / Empenhos',
              ),
              Tab(
                icon: Icon(Icons.description_outlined),
                text: 'Atas de Registro de Preço',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AbaContratosView(),
            AbaAtasView(),
          ],
        ),
      ),
    );
  }
}
