import 'package:material_ui/material_ui.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Discovery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      home: const DiscoveryPage(),
    );
  }
}

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({super.key});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _cards = [
    {
      'title': 'Bars & Hotels',
      'subtitle': '22 Lugares',
      'icon': Icons.sports_bar_outlined,
      'isHighlighted': false,
    },
    {
      'title': 'Fine Dining',
      'subtitle': '10 Lugares',
      'icon': Icons.room_service_outlined,
      'isHighlighted': false,
    },
    {
      'title': 'Cafes',
      'subtitle': '2 Lugares',
      'icon': Icons.storefront_outlined,
      'isHighlighted': false,
    },
    {
      'title': 'Nearby',
      'subtitle': '4 Lugares',
      'icon': Icons.location_on_outlined,
      'isHighlighted': true,
    },
    {
      'title': 'Fast Foods',
      'subtitle': '50 Lugares',
      'icon': Icons.fastfood_outlined,
      'isHighlighted': false,
    },
    {
      'title': 'Featured Foods',
      'subtitle': '21 Lugares',
      'icon': Icons.local_pizza_outlined,
      'isHighlighted': false,
    },
  ];

  final List<String> _bottomTitles = [
    'Home',
    'Localização',
    'Favoritos',
    'Destaques',
    'Perfil',
  ];

  // Função que realiza o link (navegação) ao clicar nos itens do BottomNavigationBar
  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      // Link do item "Localização" para a página do mapa (NearbyMapPage)
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NearbyMapPage()),
      );
    } else if (index != 0) {
      // Link dos demais itens do menu
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SimpleDetailPage(title: _bottomTitles[index]),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          'Discovery',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          itemCount: _cards.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final item = _cards[index];
            final bool isHighlighted = item['isHighlighted'] as bool;

            // Card clicável para realizar a link para outra página
            return InkWell(
              onTap: () {
                if (item['title'] == 'Nearby') {
                  // Link do card "Nearby" para a página do Google Maps (NearbyMapPage)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NearbyMapPage(),
                    ),
                  );
                } else {
                  // Link dos demais cards para a página de detalhes (SimpleDetailPage)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SimpleDetailPage(
                        title: item['title'] as String,
                        subtitle: item['subtitle'] as String,
                      ),
                    ),
                  );
                }
              },
              child: Card(
                color: isHighlighted ? Colors.amber : Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 56,
                      color: isHighlighted ? Colors.white : Colors.black87,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item['title'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isHighlighted ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['subtitle'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: isHighlighted
                            ? Colors.white70
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      // Botão de navegação
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped, // Chama a função que faz o link para a página clicada
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            label: 'Localização',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            label: 'Favoritos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            label: 'Destaques',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class SimpleDetailPage extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SimpleDetailPage({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: Colors.amber),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Página: $title',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NearbyMapPage extends StatefulWidget {
  const NearbyMapPage({super.key});

  @override
  State<NearbyMapPage> createState() => _NearbyMapPageState();
}

class _NearbyMapPageState extends State<NearbyMapPage> {
  // Inicializando o Controller do mapa
  GoogleMapController? mapController;

  // Adicionando marcadores
  Set<Marker> _marcadores = {};

  // Carregando os marcadores
  void _carregarMarcadores() {
    Set<Marker> marcoresLocal = {};

    // Criando os marcadores
    Marker markerReiDoFrango = const Marker(
      markerId: MarkerId('Rei do Frango'),
      position: LatLng(-5.076910314079212, -42.8111805980485),
      infoWindow: InfoWindow(
        title: 'Rei do Frango',
        snippet: 'Um ótimo lugar para comer frango',
      ),
    );

    Marker markerEspetosBeer = const Marker(
      markerId: MarkerId('Espetos Beer'),
      position: LatLng(-5.076087434222429, -42.81711364398176),
      infoWindow: InfoWindow(
        title: 'Espetos Beer',
        snippet: 'Um ótimo lugar para comer espetos',
      ),
    );

    Marker markerAdegaDoBoi = const Marker(
      markerId: MarkerId('Adega do Boi'),
      position: LatLng(-5.07337917848739, -42.78125205518248),
      infoWindow: InfoWindow(
        title: 'Adega do Boi',
        snippet: 'Um ótimo lugar para comer carne',
      ),
    );

    Marker markerMoinhoDePedra = const Marker(
      markerId: MarkerId('Moinho de Pedra'),
      position: LatLng(-5.060886533593194, -42.78085845653769),
      infoWindow: InfoWindow(
        title: 'Moinho de Pedra',
        snippet: 'Um ótimo lugar para comer comida nordestina',
      ),
    );

    marcoresLocal.add(markerReiDoFrango);
    marcoresLocal.add(markerEspetosBeer);
    marcoresLocal.add(markerAdegaDoBoi);
    marcoresLocal.add(markerMoinhoDePedra);

    setState(() {
      _marcadores = marcoresLocal;
    });
  } // Fim do _carregarMarcadores

  final LatLng _center = const LatLng(
    -5.0989780781783836,
    -42.786090429776586,
  ); // Coord. de casa

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  // Função para obter a localização do usuário
  void _localizacaoAtual() async {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
    );

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );

    debugPrint('Localização: $position');
  }

  // Implementando o initState
  @override
  void initState() {
    super.initState();
    _carregarMarcadores(); // Carregando os marcadores
    _localizacaoAtual(); // Carregando a localização atual
  } // Fim do initState

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurantes'),
        backgroundColor: Colors.amber,
      ),
      body: GoogleMap(
        myLocationEnabled: true, // Habilita o botão de localização
        mapType:
            MapType.normal, // Tipo de mapa: Híbrido, normal, satélite, terreno
        onMapCreated:
            _onMapCreated, // Função que é chamada quando o mapa é criado
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 11.0,
        ), // Posição inicial do mapa
        markers: _marcadores, // Adicionando os marcadores ao mapa
      ),
    );
  }
}
