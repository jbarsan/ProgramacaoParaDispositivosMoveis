import 'dart:convert';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_routes/google_maps_routes.dart';
import 'package:http/http.dart' as http;

import '../utils/constants.dart';

// Resultado da busca de um endereço (Geocoding direto ou reverso).
class GeocodingResult {
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String logradouro;
  final String numero;
  final String bairro;
  final String cidade;
  final String estado;
  final String cep;

  const GeocodingResult({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    this.logradouro = '',
    this.numero = '',
    this.bairro = '',
    this.cidade = '',
    this.estado = '',
    this.cep = '',
  });
}

// Resultado do cálculo de rota entre origem e destino.
class RouteResult {
  final List<LatLng> points;
  final String distanceText;
  final String durationText;

  const RouteResult({
    required this.points,
    required this.distanceText,
    required this.durationText,
  });
}

// Serviço de geolocalização (GPS), busca de endereços e cálculo de rotas
// utilizando `geocoding`, `geolocator` e `google_maps_routes`.
class LocationService {
  // Formata um endereço estruturado no padrão recomendado para geocodificação:
  // `"Logradouro, número, Bairro, Cidade - Estado, CEP, Brasil"`
  //
  // Remove complementos (ex.: Apto, Bloco, Fundos) e o prefixo literal `"CEP "`
  // para evitar falhas (`NoResultFoundException`) no pacote `geocoding`.
  static String formatAddressForGeocoding({
    required String logradouro,
    String? numero,
    String? bairro,
    required String cidade,
    required String estado,
    String? cep,
  }) {
    final parts = <String>[];
    if (logradouro.trim().isNotEmpty) {
      parts.add(logradouro.trim());
    }
    if (numero != null && numero.trim().isNotEmpty) {
      parts.add(numero.trim());
    }
    if (bairro != null && bairro.trim().isNotEmpty) {
      parts.add(bairro.trim());
    }
    if (cidade.trim().isNotEmpty && estado.trim().isNotEmpty) {
      parts.add('${cidade.trim()} - ${estado.trim()}');
    } else if (cidade.trim().isNotEmpty) {
      parts.add(cidade.trim());
    }
    if (cep != null && cep.trim().isNotEmpty) {
      parts.add(cep.trim());
    }
    parts.add('Brasil');
    return parts.join(', ');
  }

  // Obtém a localização atual do dispositivo (Android) ou navegador (Web).
  Future<LatLng> getCurrentLocation() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('O serviço de localização (GPS) está desativado.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permissão de localização negada pelo usuário.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Permissão de localização negada permanentemente. Habilite nas configurações.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return LatLng(position.latitude, position.longitude);
  }

  // Busca coordenadas tentando do formato mais completo para fallbacks mais simples
  // (sem bairro/CEP e apenas pelo CEP), evitando `NoResultFoundException`.
  Future<GeocodingResult?> searchStructuredAddress({
    required String logradouro,
    String? numero,
    String? bairro,
    required String cidade,
    required String estado,
    String? cep,
  }) async {
    // 1. Tentativa completa: "Logradouro, número, Bairro, Cidade - UF, CEP, Brasil"
    final completo = formatAddressForGeocoding(
      logradouro: logradouro,
      numero: numero,
      bairro: bairro,
      cidade: cidade,
      estado: estado,
      cep: cep,
    );
    final resCompleto = await searchAddress(completo);
    if (resCompleto != null) return resCompleto;

    // 2. Tentativa intermediária sem bairro e CEP: "Logradouro, número, Cidade - UF, Brasil"
    final semBairro = formatAddressForGeocoding(
      logradouro: logradouro,
      numero: numero,
      cidade: cidade,
      estado: estado,
    );
    if (semBairro != completo) {
      final resSemBairro = await searchAddress(semBairro);
      if (resSemBairro != null) return resSemBairro;
    }

    // 3. Tentativa apenas pelo CEP: "00000-000, Brasil"
    if (cep != null && cep.trim().isNotEmpty) {
      final resCep = await searchAddress('${cep.trim()}, Brasil');
      if (resCep != null) return resCep;
    }

    return null;
  }

  // Converte uma string única de endereço (separada por vírgulas) em coordenadas.
  //
  // No Android usa `locationFromAddress()` do pacote `geocoding`; na Web ou como
  // fallback consulta a Google Geocoding REST API utilizando a chave do `.env`.
  Future<GeocodingResult?> searchAddress(String address) async {
    // Remove prefixo "CEP " caso venha em string livre para aumentar precisão.
    final normalized = address
        .replaceAll(RegExp(r'\bCEP\s*', caseSensitive: false), '')
        .trim();
    if (normalized.isEmpty) return null;

    if (!kIsWeb) {
      try {
        final locations = await geo.Geocoding().locationFromAddress(normalized);
        if (locations.isNotEmpty) {
          final first = locations.first;
          return GeocodingResult(
            latitude: first.latitude,
            longitude: first.longitude,
            formattedAddress: normalized,
          );
        }
      } catch (_) {
        // Segue para fallback HTTP caso o geocoder nativo lance NoResultFoundException.
      }
    }

    final apiKey = AppConstants.googleMapsApiKey;
    if (apiKey.isEmpty || apiKey == 'sua_chave_google_maps_aqui') {
      return null;
    }

    final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'address': normalized,
      'key': apiKey,
      'language': 'pt-BR',
      'region': 'br',
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;

    final first = results.first as Map<String, dynamic>;
    final geometry = first['geometry'] as Map<String, dynamic>;
    final loc = geometry['location'] as Map<String, dynamic>;

    return GeocodingResult(
      latitude: (loc['lat'] as num).toDouble(),
      longitude: (loc['lng'] as num).toDouble(),
      formattedAddress: (first['formatted_address'] as String?) ?? normalized,
    );
  }

  // Converte coordenadas geográficas (`lat`, `lng`) em endereço estruturado.
  Future<GeocodingResult> reverseGeocode(LatLng point) async {
    if (!kIsWeb) {
      try {
        final placemarks = await geo.Geocoding().placemarkFromCoordinates(
          point.latitude,
          point.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final logradouro = p.thoroughfare ?? '';
          final numero = p.subThoroughfare ?? '';
          final bairro = p.subLocality ?? '';
          final cidade = p.locality ?? p.subAdministrativeArea ?? '';
          final estado = p.administrativeArea ?? '';
          final cep = p.postalCode ?? '';
          final formatted = [
            if (logradouro.isNotEmpty)
              numero.isNotEmpty ? '$logradouro, $numero' : logradouro,
            if (bairro.isNotEmpty) bairro,
            if (cidade.isNotEmpty) cidade,
            if (estado.isNotEmpty) estado,
          ].join(', ');

          return GeocodingResult(
            latitude: point.latitude,
            longitude: point.longitude,
            formattedAddress: formatted.isNotEmpty
                ? formatted
                : '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
            logradouro: logradouro,
            numero: numero,
            bairro: bairro,
            cidade: cidade,
            estado: estado,
            cep: cep,
          );
        }
      } catch (_) {
        // Segue para fallback HTTP.
      }
    }

    final apiKey = AppConstants.googleMapsApiKey;
    if (apiKey.isEmpty || apiKey == 'sua_chave_google_maps_aqui') {
      return GeocodingResult(
        latitude: point.latitude,
        longitude: point.longitude,
        formattedAddress:
            'Lat: ${point.latitude.toStringAsFixed(5)}, Lng: ${point.longitude.toStringAsFixed(5)}',
      );
    }

    try {
      final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
        'latlng': '${point.latitude},${point.longitude}',
        'key': apiKey,
        'language': 'pt-BR',
      });
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>?;
        if (results != null && results.isNotEmpty) {
          final first = results.first as Map<String, dynamic>;
          final comps = (first['address_components'] as List<dynamic>?) ?? [];
          String getComp(String type, {bool short = false}) {
            for (final c in comps) {
              final map = c as Map<String, dynamic>;
              final types = (map['types'] as List<dynamic>?) ?? [];
              if (types.contains(type)) {
                return (short ? map['short_name'] : map['long_name'])
                        as String? ??
                    '';
              }
            }
            return '';
          }

          return GeocodingResult(
            latitude: point.latitude,
            longitude: point.longitude,
            formattedAddress:
                (first['formatted_address'] as String?) ??
                '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
            logradouro: getComp('route'),
            numero: getComp('street_number'),
            bairro: getComp('sublocality_level_1').isNotEmpty
                ? getComp('sublocality_level_1')
                : getComp('sublocality'),
            cidade: getComp('administrative_area_level_2'),
            estado: getComp('administrative_area_level_1', short: true),
            cep: getComp('postal_code'),
          );
        }
      }
    } catch (_) {
      // Retorna apenas coordenadas se a API falhar.
    }

    return GeocodingResult(
      latitude: point.latitude,
      longitude: point.longitude,
      formattedAddress:
          'Lat: ${point.latitude.toStringAsFixed(5)}, Lng: ${point.longitude.toStringAsFixed(5)}',
    );
  }

  // Calcula e traça a rota entre [origin] e [destination] usando a biblioteca
  // `google_maps_routes` (`MapsRoutes` e `DistanceCalculator`).
  //
  // Caso a API Key não esteja configurada ou a API retorne vazio, utiliza
  // traçado geodésico aproximado (linha reta) como fallback.
  Future<RouteResult> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final apiKey = AppConstants.googleMapsApiKey;
    final calculator = DistanceCalculator();

    if (apiKey.isNotEmpty && apiKey != 'sua_chave_google_maps_aqui') {
      try {
        final mapsRoutes = MapsRoutes();
        await mapsRoutes.drawRoute(
          [origin, destination],
          'rota_sgp',
          const Color(0xFF8E1919),
          apiKey,
          travelMode: TravelModes.driving,
        );

        final routePoints = mapsRoutes.routes
            .expand((polyline) => polyline.points)
            .toList();

        if (routePoints.isNotEmpty) {
          final distanceText = calculator.calculateRouteDistance(
            routePoints,
            decimals: 1,
          );
          final km = double.tryParse(distanceText.split(' ').first) ?? 0.0;
          final estimatedMinutes = (km / 60.0 * 60).round();

          return RouteResult(
            points: routePoints,
            distanceText: distanceText,
            durationText: estimatedMinutes >= 60
                ? '${estimatedMinutes ~/ 60}h ${estimatedMinutes % 60}min (est.)'
                : '$estimatedMinutes min (est.)',
          );
        }
      } catch (_) {
        // Segue para fallback geodésico em caso de indisponibilidade/CORS.
      }
    }

    final fallbackPoints = [origin, destination];
    final distanceText = calculator.calculateRouteDistance(
      fallbackPoints,
      decimals: 1,
    );
    final km = double.tryParse(distanceText.split(' ').first) ?? 0.0;
    final estimatedMinutes = (km / 60.0 * 60).round();

    return RouteResult(
      points: fallbackPoints,
      distanceText: '$distanceText (aprox.)',
      durationText: estimatedMinutes >= 60
          ? '${estimatedMinutes ~/ 60}h ${estimatedMinutes % 60}min (est.)'
          : '$estimatedMinutes min (est.)',
    );
  }
}
