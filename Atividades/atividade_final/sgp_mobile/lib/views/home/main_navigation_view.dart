import 'package:material_ui/material_ui.dart';

import '../../utils/constants.dart';
import '../demandas/demandas_list_view.dart';
import '../indicadores/resumo_indicadores_view.dart';
import '../mapa/mapa_geral_view.dart';
import '../viagens/viagens_list_view.dart';
import '../widgets/app_drawer.dart';
import '../widgets/custom_app_bar.dart';

// Estrutura principal pós-aprovação com `AppDrawer` e `BottomNavigationBar`
// persistente alternando entre as 4 abas operacionais via `IndexedStack` (RF-007).
class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  int _currentIndex = 0;

  static const List<String> _titles = [
    'Demandas Periciais',
    'Viagens',
    'Mapa Geral',
    'Resumo e Indicadores',
  ];

  static const List<Widget> _pages = [
    DemandasListView(),
    ViagensListView(),
    MapaGeralView(),
    ResumoIndicadoresView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: _titles[_currentIndex]),
      drawer: const AppDrawer(),
      body: Center(
        child: ConstrainedBox(
          // Na Web, limita a largura máxima a 900px para manter ergonomia limpa.
          constraints: const BoxConstraints(
            maxWidth: AppConstants.maxWebContentWidth,
          ),
          child: IndexedStack(index: _currentIndex, children: _pages),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Demandas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car_outlined),
            activeIcon: Icon(Icons.directions_car),
            label: 'Viagens',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Indicadores',
          ),
        ],
      ),
    );
  }
}
