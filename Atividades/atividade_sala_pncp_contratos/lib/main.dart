import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'controllers/ata_controller.dart';
import 'controllers/contrato_controller.dart';
import 'views/home_view.dart';

void main() {
  runApp(const MeuApp());
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ContratoController()),
        ChangeNotifierProvider(create: (_) => AtaController()),
      ],
      child: MaterialApp(
        title: 'Gestor PNCP - Contratos e ARP',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue[900]!,
          ),
          useMaterial3: true,
        ),
        home: const HomeView(),
      ),
    );
  }
}
