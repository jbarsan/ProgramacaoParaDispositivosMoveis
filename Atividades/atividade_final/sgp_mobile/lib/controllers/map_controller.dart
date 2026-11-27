import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/location_service.dart';

// Controller responsável pelo estado de geolocalização, busca de endereços
// e cálculo de rotas no Google Maps (RF-014, RF-015 e RF-016).
class MapController extends ChangeNotifier {
  final LocationService _locationService;

  LatLng? _currentLocation;
  RouteResult? _currentRoute;
  bool _isLoading = false;
  String? _errorMessage;

  MapController({LocationService? locationService})
    : _locationService = locationService ?? LocationService();

  LatLng? get currentLocation => _currentLocation;
  RouteResult? get currentRoute => _currentRoute;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Obtém a posição GPS atual do dispositivo/navegador.
  Future<LatLng?> fetchCurrentLocation() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentLocation = await _locationService.getCurrentLocation();
      _errorMessage = null;
      return _currentLocation;
    } catch (e) {
      _currentRoute = null;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Busca coordenadas a partir de um endereço estruturado (sem complementos).
  Future<GeocodingResult?> searchStructuredAddress({
    required String logradouro,
    String? numero,
    String? bairro,
    required String cidade,
    required String estado,
    String? cep,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _locationService.searchStructuredAddress(
        logradouro: logradouro,
        numero: numero,
        bairro: bairro,
        cidade: cidade,
        estado: estado,
        cep: cep,
      );
      if (result == null) {
        _errorMessage =
            'Endereço não encontrado. Verifique os dados informados.';
      } else {
        _errorMessage = null;
      }
      return result;
    } catch (e) {
      _errorMessage = 'Erro ao buscar endereço: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Busca coordenadas a partir de um endereço textual (RF-015).
  Future<GeocodingResult?> searchAddress(String address) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _locationService.searchAddress(address);
      if (result == null) {
        _errorMessage =
            'Endereço não encontrado. Verifique os dados informados.';
      } else {
        _errorMessage = null;
      }
      return result;
    } catch (e) {
      _errorMessage = 'Erro ao buscar endereço: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Obtém endereço e coordenadas a partir de um ponto clicado no mapa.
  Future<GeocodingResult> reverseGeocode(LatLng point) async {
    return _locationService.reverseGeocode(point);
  }

  // Calcula a rota da posição atual até [destination] (RF-016).
  Future<RouteResult?> calculateRouteTo(LatLng destination) async {
    _isLoading = true;
    notifyListeners();
    try {
      final origin =
          _currentLocation ?? await _locationService.getCurrentLocation();
      _currentLocation = origin;
      _currentRoute = await _locationService.getRoute(
        origin: origin,
        destination: destination,
      );
      _errorMessage = null;
      return _currentRoute;
    } catch (e) {
      _currentRoute = null;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Limpa a rota atualmente traçada.
  void clearRoute() {
    _currentRoute = null;
    notifyListeners();
  }
}
