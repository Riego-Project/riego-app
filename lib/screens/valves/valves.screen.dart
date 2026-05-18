import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme/app_theme.dart';
import '../../models/valve.model.dart';
import '../../providers/valve.provider.dart';
import '../../services/socket.service.dart';
import '../../widgets/common/error_snackbar.dart';

class ValvesScreen extends ConsumerStatefulWidget {
  const ValvesScreen({super.key});

  @override
  ConsumerState<ValvesScreen> createState() => _ValvesScreenState();
}

class _ValvesScreenState extends ConsumerState<ValvesScreen> {
  @override
  void initState() {
    super.initState();
    SocketService().connect();
  }

  @override
  Widget build(BuildContext context) {
    final valvesState = ref.watch(valveProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Válvulas'),
        actions: [
          IconButton(
            icon:    const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(valveProvider.notifier).refresh(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: valvesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
              const SizedBox(height: 16),
              Text(
                e.toString().replaceAll('Exception: ', ''),
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(valveProvider.notifier).refresh(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (valves) => _ValvesList(valves: valves),
      ),
    );
  }
}

// ── Lista de válvulas ─────────────────────────────────────────────────────────
class _ValvesList extends ConsumerWidget {
  final List<ValveModel> valves;
  const _ValvesList({required this.valves});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zones = <int, List<ValveModel>>{};
    for (final v in valves) {
      zones.putIfAbsent(v.zoneId, () => []).add(v);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        // ── Botones de zona ────────────────────────────────────────────────
        Row(
          children: zones.entries.map((entry) {
            final zoneId   = entry.key;
            final zoneName = entry.value.first.zoneNombre;
            final allOpen  = entry.value.every((v) => v.isOpen);
            final isOnline = entry.value.any((v) => v.nodoOnline);

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: entry.key != zones.keys.last ? 10 : 0,
                ),
                child: _ZoneButton(
                  nombre:   zoneName,
                  isOpen:   allOpen,
                  isOnline: isOnline,
                  onTap: isOnline
                      ? () async {
                    try {
                      await ref.read(valveProvider.notifier)
                          .sendZoneCommand(zoneId, allOpen ? 'cerrar' : 'abrir');
                    } catch (e) {
                      if (context.mounted) {
                        showErrorSnackbar(context,
                            e.toString().replaceAll('Exception: ', ''));
                      }
                    }
                  }
                      : () {},
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),

        // ── Válvulas por zona ──────────────────────────────────────────────
        ...zones.entries.map((entry) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width:  3,
                    height: 14,
                    decoration: BoxDecoration(
                      color:        AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.value.first.zoneNombre.toUpperCase(),
                    style: const TextStyle(
                      color:       AppColors.textSecondary,
                      fontSize:    11,
                      fontWeight:  FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            ...entry.value.map((valve) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ValveCard(valve: valve),
            )),
            const SizedBox(height: 8),
          ],
        )),
      ],
    );
  }
}

// ── Botón de zona ─────────────────────────────────────────────────────────────
class _ZoneButton extends StatelessWidget {
  final String nombre;
  final bool   isOpen;
  final bool   isOnline;
  final VoidCallback onTap;

  const _ZoneButton({
    required this.nombre,
    required this.isOpen,
    required this.isOnline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = !isOnline
        ? AppColors.textMuted
        : isOpen ? AppColors.danger : AppColors.primary;

    return GestureDetector(
      onTap: isOnline ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isOnline ? color.withOpacity(0.5) : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              !isOnline
                  ? Icons.wifi_off_rounded
                  : isOpen
                  ? Icons.stop_circle_outlined
                  : Icons.play_circle_outline,
              color: color,
              size:  18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                !isOnline
                    ? 'Sin conexión'
                    : isOpen ? 'Cerrar $nombre' : 'Abrir $nombre',
                style: TextStyle(
                  color:      color,
                  fontWeight: FontWeight.w600,
                  fontSize:   13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card de válvula ───────────────────────────────────────────────────────────
class _ValveCard extends ConsumerWidget {
  final ValveModel valve;
  const _ValveCard({required this.valve});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen   = valve.isOpen;
    final isOnline = valve.nodoOnline;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: !isOnline
              ? AppColors.danger.withOpacity(0.3)
              : isOpen
              ? AppColors.primary.withOpacity(0.5)
              : AppColors.border,
          width: isOpen ? 1.5 : 1,
        ),
        boxShadow: isOpen
            ? [BoxShadow(
          color:      AppColors.primary.withOpacity(0.08),
          blurRadius: 12,
          offset:     const Offset(0, 4),
        )]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icono con estado
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width:  48,
              height: 48,
              decoration: BoxDecoration(
                color: isOpen
                    ? AppColors.primary.withOpacity(0.15)
                    : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      isOpen
                          ? Icons.water_drop_rounded
                          : Icons.water_drop_outlined,
                      color: isOpen ? AppColors.primary : AppColors.textMuted,
                      size:  24,
                    ),
                  ),
                  // Indicador nodo
                  Positioned(
                    bottom: 4,
                    right:  4,
                    child: Container(
                      width:  8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline
                            ? AppColors.success
                            : AppColors.danger,
                        border: Border.all(
                          color: AppColors.surface,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    valve.nombre,
                    style: const TextStyle(
                      color:      AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize:   14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        'Canal ${valve.canalRele}',
                        style: const TextStyle(
                          color:   AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const Text(
                        ' · ',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: isOpen
                              ? AppColors.primary.withOpacity(0.12)
                              : AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isOpen ? 'ABIERTA' : 'CERRADA',
                          style: TextStyle(
                            color:      isOpen
                                ? AppColors.primary
                                : AppColors.textMuted,
                            fontSize:   10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!isOnline) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Nodo sin conexión',
                      style: TextStyle(
                        color:   AppColors.danger,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Toggle
            Switch(
              value:     isOpen,
              onChanged: isOnline
                  ? (_) async {
                try {
                  await ref.read(valveProvider.notifier).sendCommand(
                    valve.valveId,
                    isOpen ? 'cerrar' : 'abrir',
                  );
                } catch (e) {
                  if (context.mounted) {
                    showErrorSnackbar(context,
                        e.toString().replaceAll('Exception: ', ''));
                  }
                }
              }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}