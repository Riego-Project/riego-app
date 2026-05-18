import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../config/theme/app_theme.dart';
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
  LatLng? _center;

  void _centerMap() {
    if (_center != null) {
      _mapController.move(_center!, 19);
    }
  }

  @override
  Widget build(BuildContext context) {
    final valvesState = ref.watch(valveProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de Válvulas')),
      body: valvesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
        data: (valves) {
          final withLocation = valves.where((v) => v.hasLocation).toList();

          if (withLocation.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off_rounded,
                    color: AppColors.textMuted,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No hay válvulas con ubicación',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          _center = LatLng(
            withLocation.map((v) => v.latitud!).reduce((a, b) => a + b) /
                withLocation.length,
            withLocation.map((v) => v.longitud!).reduce((a, b) => a + b) /
                withLocation.length,
          );

          final selectedValve = _selectedValveId != null
              ? valves.where((v) => v.valveId == _selectedValveId).firstOrNull
              : null;

          return Stack(
            children: [
              // ── Mapa ───────────────────────────────────────────────────
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _center!,
                  initialZoom: 19,
                  maxZoom: 22,
                  onTap: (_, __) => setState(() => _selectedValveId = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://mt{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
                    subdomains: const ['0', '1', '2', '3'],
                    userAgentPackageName: 'pe.riego.app',
                  ),
                  MarkerLayer(
                    markers: withLocation.map((valve) {
                      final isSelected = valve.valveId == _selectedValveId;
                      return Marker(
                        point: LatLng(valve.latitud!, valve.longitud!),
                        width: isSelected ? 60 : 46,
                        height: isSelected ? 60 : 46,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedValveId = valve.valveId),
                          child: _ValveMarker(
                            valve: valve,
                            isSelected: isSelected,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // ── Leyenda ────────────────────────────────────────────────
              Positioned(top: 12, right: 12, child: _Legend()),

              // ── Botón centrar ──────────────────────────────────────────
              Positioned(
                bottom: selectedValve != null ? 200 : 24,
                right: 16,
                child: Column(
                  children: [
                    _MapButton(
                      icon: Icons.my_location_rounded,
                      tooltip: 'Centrar válvulas',
                      onTap: _centerMap,
                    ),
                  ],
                ),
              ),

              // ── Panel de válvula seleccionada ──────────────────────────
              if (selectedValve != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _ValvePanel(
                    valve: selectedValve,
                    onClose: () => setState(() => _selectedValveId = null),
                    onCommand: (accion) async {
                      try {
                        await ref
                            .read(valveProvider.notifier)
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

// ── Botón flotante del mapa ───────────────────────────────────────────────────
class _MapButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MapButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
      ),
    );
  }
}

// ── Marcador de válvula ───────────────────────────────────────────────────────
class _ValveMarker extends StatelessWidget {
  final ValveModel valve;
  final bool isSelected;

  const _ValveMarker({required this.valve, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final isOpen = valve.isOpen;
    final bgColor = isOpen ? AppColors.primary : const Color(0xFF334155);
    final glowColor = isOpen
        ? AppColors.primary.withOpacity(0.4)
        : Colors.black.withOpacity(0.3);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? Colors.white : bgColor.withOpacity(0.6),
          width: isSelected ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: isSelected ? 16 : 8,
            spreadRadius: isSelected ? 3 : 0,
          ),
        ],
      ),
      child: Icon(
        isOpen ? Icons.water_drop_rounded : Icons.water_drop_outlined,
        color: Colors.white,
        size: isSelected ? 28 : 22,
      ),
    );
  }
}

// ── Leyenda ───────────────────────────────────────────────────────────────────
class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendItem(color: AppColors.primary, label: 'Abierta'),
          const SizedBox(height: 4),
          _LegendItem(color: const Color(0xFF334155), label: 'Cerrada'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
        ),
      ],
    );
  }
}

// ── Panel de control inferior ─────────────────────────────────────────────────
class _ValvePanel extends StatelessWidget {
  final ValveModel valve;
  final VoidCallback onClose;
  final Function(String) onCommand;

  const _ValvePanel({
    required this.valve,
    required this.onClose,
    required this.onCommand,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = valve.isOpen;
    final isOnline = valve.nodoOnline;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOpen ? AppColors.primary.withOpacity(0.4) : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isOpen
                      ? AppColors.primary.withOpacity(0.15)
                      : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isOpen ? Icons.water_drop_rounded : Icons.water_drop_outlined,
                  color: isOpen ? AppColors.primary : AppColors.textMuted,
                  size: 22,
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
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${valve.zoneNombre} · Canal ${valve.canalRele}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOpen
                      ? AppColors.primary.withOpacity(0.12)
                      : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isOpen ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  isOpen ? 'ABIERTA' : 'CERRADA',
                  style: TextStyle(
                    color: isOpen ? AppColors.primary : AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: isOnline
                  ? () => onCommand(isOpen ? 'cerrar' : 'abrir')
                  : null,
              icon: Icon(
                isOpen ? Icons.stop_circle_outlined : Icons.play_circle_outline,
              ),
              label: Text(
                !isOnline
                    ? 'Nodo sin conexión'
                    : isOpen
                    ? 'Cerrar válvula'
                    : 'Abrir válvula',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: !isOnline
                    ? AppColors.border
                    : isOpen
                    ? AppColors.danger
                    : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
