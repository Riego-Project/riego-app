import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../models/valve.model.dart';
import '../../providers/valve.provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  ValveModel? _selectedValve;

  @override
  Widget build(BuildContext context) {
    final valvesState = ref.watch(valveProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0f1a14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a2f20),
        title: const Text(
          'Mapa de Válvulas',
          style: TextStyle(color: Color(0xFF95d5b2)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF52b788)),
      ),
      body: valvesState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF52b788)),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
        ),
        data: (valves) {
          final withLocation = valves.where((v) => v.hasLocation).toList();

          if (withLocation.isEmpty) {
            return const Center(
              child: Text(
                'No hay válvulas con ubicación configurada',
                style: TextStyle(color: Color(0xFF52b788)),
              ),
            );
          }

          final center = LatLng(
            withLocation.map((v) => v.latitud!).reduce((a, b) => a + b) / withLocation.length,
            withLocation.map((v) => v.longitud!).reduce((a, b) => a + b) / withLocation.length,
          );

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom:   19,
                  maxZoom:       22,
                  onTap: (_, __) => setState(() => _selectedValve = null),
                ),
                children: [
                  // Capa satelital de ESRI (gratuita)
                  TileLayer(
                    urlTemplate: 'https://mt{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
                    subdomains: const ['0', '1', '2', '3'],
                    userAgentPackageName: 'pe.riego.app',
                  ),
                  // Marcadores de válvulas
                  MarkerLayer(
                    markers: withLocation.map((valve) {
                      return Marker(
                        point:  LatLng(valve.latitud!, valve.longitud!),
                        width:  48,
                        height: 48,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedValve = valve),
                          child: _ValveMarker(valve: valve),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // Panel inferior con info de válvula seleccionada
              if (_selectedValve != null)
                Positioned(
                  bottom: 0,
                  left:   0,
                  right:  0,
                  child: _ValvePanel(
                    valve: _selectedValve!,
                    onClose: () => setState(() => _selectedValve = null),
                    onCommand: (accion) async {
                      await ref.read(valveProvider.notifier)
                          .sendCommand(_selectedValve!.valveId, accion);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Marcador de válvula ───────────────────────────────────────────────────────
class _ValveMarker extends StatelessWidget {
  final ValveModel valve;
  const _ValveMarker({required this.valve});

  @override
  Widget build(BuildContext context) {
    final isOpen = valve.isOpen;
    return Container(
      decoration: BoxDecoration(
        color: isOpen
            ? const Color(0xFF52b788)
            : const Color(0xFF1a2f20),
        shape: BoxShape.circle,
        border: Border.all(
          color: isOpen
              ? const Color(0xFF95d5b2)
              : const Color(0xFF52b788),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        isOpen ? Icons.water_drop : Icons.water_drop_outlined,
        color: isOpen ? Colors.white : const Color(0xFF52b788),
        size: 24,
      ),
    );
  }
}

// ── Panel inferior de control ─────────────────────────────────────────────────
class _ValvePanel extends StatelessWidget {
  final ValveModel       valve;
  final VoidCallback     onClose;
  final Function(String) onCommand;

  const _ValvePanel({
    required this.valve,
    required this.onClose,
    required this.onCommand,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = valve.isOpen;

    return Container(
      margin:  const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        const Color(0xFF1a2f20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOpen
              ? const Color(0xFF52b788)
              : const Color(0xFF2d3a30),
        ),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset:     const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:        isOpen
                      ? const Color(0xFF52b788).withOpacity(0.2)
                      : const Color(0xFF2d3a30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isOpen ? Icons.water_drop : Icons.water_drop_outlined,
                  color: isOpen
                      ? const Color(0xFF52b788)
                      : const Color(0xFF4a5a50),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      valve.nombre,
                      style: const TextStyle(
                        color:      Color(0xFFd8f3dc),
                        fontWeight: FontWeight.bold,
                        fontSize:   15,
                      ),
                    ),
                    Text(
                      '${valve.zoneNombre} · Canal ${valve.canalRele}',
                      style: const TextStyle(
                        color:   Color(0xFF52b788),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:        isOpen
                      ? const Color(0xFF52b788).withOpacity(0.2)
                      : const Color(0xFF2d3a30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOpen ? 'ABIERTA' : 'CERRADA',
                  style: TextStyle(
                    color:      isOpen
                        ? const Color(0xFF52b788)
                        : const Color(0xFF4a5a50),
                    fontSize:   11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon:    const Icon(Icons.close, color: Color(0xFF52b788), size: 18),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width:  double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => onCommand(isOpen ? 'cerrar' : 'abrir'),
              icon: Icon(
                isOpen ? Icons.stop_circle_outlined : Icons.play_circle_outline,
                color: Colors.white,
              ),
              label: Text(
                isOpen ? 'Cerrar válvula' : 'Abrir válvula',
                style: const TextStyle(
                  color:      Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isOpen
                    ? const Color(0xFF9b1c1c)
                    : const Color(0xFF2d6a4f),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}