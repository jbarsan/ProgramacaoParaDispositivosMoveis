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
      title: 'Flutter Gmaps',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const MyGmaps(title: 'Flutter Gmaps'),
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

    // Criando os marcadores
    Marker markerIFPI = Marker(
      markerId: MarkerId('IFPI'),
      position: LatLng(-5.08854404619581, -42.81123803149089),
      infoWindow: InfoWindow(
        title: 'IFPI',
        snippet: 'Onde os cães correm atrás do próprio rabo',
      ),
    );

    Marker markerIFPISul = Marker(
      markerId: MarkerId('IFPISul'),
      position: LatLng(-5.101723, -42.813114),
      infoWindow: InfoWindow(
        title: 'IFPI Sul',
        snippet: 'Onde os gatos não têm rabo',
      ),
    );

    marcoresLocal.add(markerIFPI);
    marcoresLocal.add(markerIFPISul);

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
        appBar: AppBar(title: const Text('Google Maps')),
        body: GoogleMap(
          myLocationEnabled: true, // Habilita o botão de localização
          mapType: MapType
              .hybrid, // Tipo de mapa: Híbrido, normal, satélite, terreno
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
