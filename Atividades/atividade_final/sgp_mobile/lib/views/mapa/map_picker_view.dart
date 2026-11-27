import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../controllers/map_controller.dart';
import '../../services/location_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

// Tela interativa para o usuário clicar em um ponto no Google Maps,
// visualizar as coordenadas e o endereço correspondente e confirmar
// o preenchimento na demanda.
class MapPickerView extends StatefulWidget {
  final LatLng? initialPoint;

  const MapPickerView({super.key, this.initialPoint});

  @override
  State<MapPickerView> createState() => _MapPickerViewState();
}

class _MapPickerViewState extends State<MapPickerView> {
  late LatLng _selectedPoint;
  GeocodingResult? _resolvedResult;
  bool _loadingAddress = false;

  @override
  void initState() {
    super.initState();
    _selectedPoint =
        widget.initialPoint ??
        const LatLng(AppConstants.defaultLat, AppConstants.defaultLng);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolvePoint(_selectedPoint);
    });
  }

  Future<void> _resolvePoint(LatLng point) async {
    setState(() {
      _selectedPoint = point;
      _loadingAddress = true;
    });
    final res = await context.read<MapController>().reverseGeocode(point);
    if (!mounted) return;
    setState(() {
      _resolvedResult = res;
      _loadingAddress = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecionar Ponto no Mapa')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedPoint,
              zoom: 14,
            ),
            onTap: _resolvePoint,
            markers: {
              Marker(
                markerId: const MarkerId('ponto_selecionado'),
                position: _selectedPoint,
                infoWindow: InfoWindow(
                  title: 'Ponto selecionado',
                  snippet:
                      '${_selectedPoint.latitude.toStringAsFixed(5)}, ${_selectedPoint.longitude.toStringAsFixed(5)}',
                ),
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Toque no mapa para marcar o local exato:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Coordenadas: ${_selectedPoint.latitude.toStringAsFixed(6)}, ${_selectedPoint.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_loadingAddress)
                      const LinearProgressIndicator()
                    else
                      Text(
                        _resolvedResult?.formattedAddress ??
                            'Obtendo endereço...',
                        style: const TextStyle(fontSize: 13),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(
                  context,
                  _resolvedResult ??
                      GeocodingResult(
                        latitude: _selectedPoint.latitude,
                        longitude: _selectedPoint.longitude,
                        formattedAddress:
                            '${_selectedPoint.latitude.toStringAsFixed(5)}, ${_selectedPoint.longitude.toStringAsFixed(5)}',
                      ),
                );
              },
              icon: const Icon(Icons.check),
              label: const Text('Usar Estas Coordenadas e Endereço'),
            ),
          ),
        ],
      ),
    );
  }
}
