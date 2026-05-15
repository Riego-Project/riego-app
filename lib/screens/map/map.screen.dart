import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../models/valve.model.dart';
import '../../providers/valve.provider.dart';
import '../../widgets/common/error_snackbar.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  String? _selectedValveId;

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

          // Válvula seleccionada siempre desde el provider — se actualiza en tiempo real
          final selectedValve = _selectedValveId != null
              ? valves.where((v) => v.valveId == _selectedValveId).firstOrNull
              : null;

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
                  onTap: (_, __) => setState(() => _selectedValveId = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://mt{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
                    subdomains:  const ['0', '1', '2', '3'],
                    userAgentPackageName: 'pe.riego.app',
                  ),
                  MarkerLayer(
                    markers: withLocation.map((valve) {
                      final isSelected = valve.valveId == _selectedValveId;
                      return Marker(
                        point:  LatLng(valve.latitud!, valve.longitud!),
                        width:  isSelected ? 56 : 44,
                        height: isSelected ? 56 : 44,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedValveId = valve.valveId),
                          child: _ValveMarker(
                            valve:      valve,
                            isSelected: isSelected,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // Leyenda
              Positioned(
                top:   12,
                right: 12,
                child: _Legend(),
              ),

              // Panel de control
              if (selectedValve != null)
                Positioned(
                  bottom: 0,
                  left:   0,
                  right:  0,
                  child: _ValvePanel(
                    valve:     selectedValve,
                    onClose:   () => setState(() => _selectedValveId = null),
                    onCommand: (accion) async {
                      try {
                        await ref.read(valveProvider.notifier)
                            .sendCommand(selectedValve.valveId, accion);
                      } catch (e) {
                        if (context.mounted) {
                          showErrorSnackbar(
                            context,
                            e.toString().replaceAll('Exception: ', ''),
                          );
                        }
                      }
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

// ── Marcador ──────────────────────────────────────────────────────────────────
class _ValveMarker extends StatelessWidget {
  final ValveModel valve;
  final bool       isSelected;
  const _ValveMarker({required this.valve, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final isOpen = valve.isOpen;

    // Colores distintivos: azul agua para abierta, gris oscuro para cerrada
    final bgColor     = isOpen ? const Color(0xFF0ea5e9) : const Color(0xFF374151);
    final borderColor = isOpen ? const Color(0xFF7dd3fc) : const Color(0xFF6b7280);
    final iconColor   = isOpen ? Colors.white : const Color(0xFF9ca3af);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color:  bgColor,
        shape:  BoxShape.circle,
        border: Border.all(
          color: isSelected ? Colors.white : borderColor,
          width: isSelected ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color:      isOpen
                ? const Color(0xFF0ea5e9).withOpacity(0.5)
                : Colors.black.withOpacity(0.4),
            blurRadius: isSelected ? 12 : 6,
            spreadRadius: isSelected ? 2 : 0,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        isOpen ? Icons.water_drop : Icons.water_drop_outlined,
        color: iconColor,
        size:  isSelected ? 28 : 22,
      ),
    );
  }
}

// ── Leyenda ───────────────────────────────────────────────────────────────────
class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding:     const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:        Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendItem(color: const Color(0xFF0ea5e9), label: 'Abierta'),
          const SizedBox(height: 4),
          _LegendItem(color: const Color(0xFF374151), label: 'Cerrada'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color  color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width:  12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}

// ── Panel de control ──────────────────────────────────────────────────────────
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
              ? const Color(0xFF0ea5e9)
              : const Color(0xFF2d3a30),
        ),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.5),
            blurRadius: 16,
            offset:     const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width:  40,
                height: 40,
                decoration: BoxDecoration(
                  color:  isOpen
                      ? const Color(0xFF0ea5e9).withOpacity(0.2)
                      : const Color(0xFF2d3a30),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOpen ? Icons.water_drop : Icons.water_drop_outlined,
                  color: isOpen
                      ? const Color(0xFF0ea5e9)
                      : const Color(0xFF6b7280),
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
              // Badge de estado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:        isOpen
                      ? const Color(0xFF0ea5e9).withOpacity(0.15)
                      : const Color(0xFF374151),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOpen
                        ? const Color(0xFF0ea5e9)
                        : const Color(0xFF6b7280),
                    width: 1,
                  ),
                ),
                child: Text(
                  isOpen ? 'ABIERTA' : 'CERRADA',
                  style: TextStyle(
                    color:      isOpen
                        ? const Color(0xFF0ea5e9)
                        : const Color(0xFF9ca3af),
                    fontSize:   10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon:      const Icon(Icons.close, color: Color(0xFF52b788), size: 18),
                onPressed: onClose,
                padding:   EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width:  double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => onCommand(isOpen ? 'cerrar' : 'abrir'),
              icon: Icon(
                isOpen
                    ? Icons.stop_circle_outlined
                    : Icons.play_circle_outline,
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
                    ? const Color(0xFFdc2626)
                    : const Color(0xFF0ea5e9),
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