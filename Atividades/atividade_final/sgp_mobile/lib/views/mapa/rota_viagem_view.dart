import 'package:material_ui/material_ui.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/map_controller.dart';
import '../../utils/app_theme.dart';

// Tela de cálculo e exibição de rota entre a localização atual (GPS)
// e o destino da demanda ou viagem selecionada (RF-016).
class RotaViagemView extends StatefulWidget {
  final String tituloDestino;
  final String enderecoDestino;
  final LatLng destino;

  const RotaViagemView({
    super.key,
    required this.tituloDestino,
    required this.enderecoDestino,
    required this.destino,
  });

  @override
  State<RotaViagemView> createState() => _RotaViagemViewState();
}

class _RotaViagemViewState extends State<RotaViagemView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapController>().calculateRouteTo(widget.destino);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapCtrl = context.watch<MapController>();
    final route = mapCtrl.currentRoute;
    final origin = mapCtrl.currentLocation;

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('destino'),
        position: widget.destino,
        infoWindow: InfoWindow(
          title: widget.tituloDestino,
          snippet: widget.enderecoDestino,
        ),
      ),
      if (origin != null)
        Marker(
          markerId: const MarkerId('origem'),
          position: origin,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'Sua localização atual'),
        ),
    };

    final polylines = <Polyline>{
      if (route != null && route.points.isNotEmpty)
        Polyline(
          polylineId: const PolylineId('rota_sgp'),
          points: route.points,
          color: AppTheme.primaryColor,
          width: 5,
        ),
    };

    return Scaffold(
      appBar: AppBar(title: Text(widget.tituloDestino)),
      body: Column(
        children: [
          if (mapCtrl.isLoading) const LinearProgressIndicator(),
          if (mapCtrl.errorMessage != null)
            Container(
              width: double.infinity,
              color: AppTheme.statusPausada.withValues(alpha: 0.15),
              padding: const EdgeInsets.all(10),
              child: Text(
                mapCtrl.errorMessage!,
                style: const TextStyle(color: AppTheme.statusPausada),
              ),
            ),
          if (route != null)
            Container(
              width: double.infinity,
              color: AppTheme.surfaceIceColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.route, color: AppTheme.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        route.distanceText,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        route.durationText,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.destino,
                zoom: 12,
              ),
              markers: markers,
              polylines: polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
        ],
      ),
    );
  }
}
