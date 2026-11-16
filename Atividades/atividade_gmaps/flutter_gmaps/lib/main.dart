import 'package:flutter/material.dart';
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
      title: 'Lista de shoppings de Teresina',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const MyGmaps(title: 'Lista de shoppings de Teresina'),
    );
  }
}

class MyGmaps extends StatefulWidget {
  const MyGmaps({super.key, required this.title});

  final String title;

  @override
  State<MyGmaps> createState() => _MyGmapsState();
}

class _MyGmapsState extends State<MyGmaps> {
  // Inicializando o Controller do mapa
  GoogleMapController? mapController;

  // Adicionando marcadores
  Set<Marker> _marcadores = {};

  // Carregando os marcadores
  void _carregarMarcadores() async {
    Set<Marker> marcoresLocal = {};

    // Carrega o ícone personalizado
    final BitmapDescriptor icon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/icons/pin/pin.png',
    );

    // Criando os marcadores
    Marker markerRioPoti = Marker(
      markerId: MarkerId('Rio Poti'),
      position: LatLng(-5.077202384158038, -42.801704510666404),
      icon: icon, // Adicionando o ícone personalizado
      infoWindow: InfoWindow(
        title: 'Shopping Rio Poti',
        snippet: 'Um ótimo lugar para compras',
      ),
    );

    Marker markerTeresinaShopping = Marker(
      markerId: MarkerId('Teresina Shopping'),
      position: LatLng(-5.085256683404496, -42.79024928021269),
      icon: icon, // Adicionando o ícone personalizado
      infoWindow: InfoWindow(
        title: 'Teresina Shopping',
        snippet: 'Um ótimo lugar para compras',
      ),
    );

    Marker markerRiverside = Marker(
      markerId: MarkerId('Riverside'),
      position: LatLng(-5.0784999270247555, -42.79491092254587),
      icon: icon, // Adicionando o ícone personalizado
      infoWindow: InfoWindow(
        title: 'Shopping Riverside',
        snippet: 'Um ótimo lugar para compras',
      ),
    );

    marcoresLocal.add(markerRioPoti);
    marcoresLocal.add(markerTeresinaShopping);
    marcoresLocal.add(markerRiverside);

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
    // Configura os parâmetros de localização de forma atualizada
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
    );

    // Obtém a localização atual do usuário de forma atualizada
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );

    print('Localização: $position');
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
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Shoppings Maps')),
        body: GoogleMap(
          myLocationEnabled: true, // Habilita o botão de localização
          mapType: MapType
              .normal, // Tipo de mapa: Híbrido, normal, satélite, terreno
          onMapCreated:
              _onMapCreated, // Função que é chamada quando o mapa é criado
          initialCameraPosition: CameraPosition(
            target: _center,
            zoom: 11.0,
          ), // Posição inicial do mapa
          markers: _marcadores, // Adicionando os marcadores ao mapa
        ),
      ),
    );
  }
}
