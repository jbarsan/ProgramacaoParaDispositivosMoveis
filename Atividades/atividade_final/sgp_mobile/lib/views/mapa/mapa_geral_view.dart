import 'package:material_ui/material_ui.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/demanda_controller.dart';
import '../../models/demanda_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../demandas/demanda_detail_view.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/status_badge.dart';

// Mapa Geral interativo exibindo marcadores das demandas do usuário (RF-014).
class MapaGeralView extends StatelessWidget {
  const MapaGeralView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final demandaCtrl = context.watch<DemandaController>();

    if (user == null) return const LoadingIndicator();

    return StreamBuilder<List<DemandaModel>>(
      stream: demandaCtrl.streamDemandas(user),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator(message: 'Carregando mapa...');
        }

        final demandas = (snapshot.data ?? [])
            .where((d) => d.latitude != 0.0 && d.longitude != 0.0)
            .toList();

        final markers = demandas.map((d) {
          final hue = d.prioridade == AppConstants.prioridadeAlta
              ? BitmapDescriptor.hueRed
              : (d.status == AppConstants.statusConcluida
                    ? BitmapDescriptor.hueGreen
                    : BitmapDescriptor.hueAzure);

          return Marker(
            markerId: MarkerId(d.id),
            position: LatLng(d.latitude, d.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(hue),
            infoWindow: InfoWindow(
              title: d.numeroSgp,
              snippet: '${d.titulo} • ${d.municipio}',
              onTap: () => _mostrarResumoDemanda(context, d),
            ),
            onTap: () => _mostrarResumoDemanda(context, d),
          );
        }).toSet();

        final initialTarget = demandas.isNotEmpty
            ? LatLng(demandas.first.latitude, demandas.first.longitude)
            : const LatLng(AppConstants.defaultLat, AppConstants.defaultLng);

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initialTarget,
                zoom: 11,
              ),
              markers: markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Text(
                    '${demandas.length} demanda(s) georreferenciada(s) • Toque em um marcador para detalhes',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _mostrarResumoDemanda(BuildContext context, DemandaModel d) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  d.numeroSgp,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                StatusBadge.fromDemandaStatus(d.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              d.titulo,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('${d.endereco}, ${d.municipio}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DemandaDetailView(demanda: d),
                  ),
                );
              },
              child: const Text('Abrir Demanda'),
            ),
          ],
        ),
      ),
    );
  }
}
