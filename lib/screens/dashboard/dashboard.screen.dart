import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_theme.dart';
import '../../providers/auth.provider.dart';
import '../../providers/notification.provider.dart';
import '../../providers/valve.provider.dart';
import '../notifications/notifications.screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final valvesState = ref.watch(valveProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.water_drop_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Panel de Control'),
          ],
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final count = ref.watch(unreadCountProvider);
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () =>
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        ).then(
                          (_) =>
                              ref.read(notificationProvider.notifier).clear(),
                        ),
                  ),
                  if (count > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: valvesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _DashboardContent(valves: const []),
        data: (valves) => _DashboardContent(valves: valves),
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  final List<dynamic> valves;

  const _DashboardContent({required this.valves});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final abiertas = valves.where((v) => v.isOpen).length;
    final cerradas = valves.where((v) => !v.isOpen).length;
    final nodoOnline = valves.any((v) => v.nodoOnline);
    final total = valves.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Saludo ──────────────────────────────────────────────────────
          const Text(
            'Buenos días',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 2),
          const Text(
            'Sistema de Riego',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Paltos · Ayacucho · 2 hectáreas',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 24),

          // ── KPIs ────────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  label: 'Abiertas',
                  value: '$abiertas',
                  total: '$total',
                  color: AppColors.primary,
                  icon: Icons.water_drop_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KpiCard(
                  label: 'Cerradas',
                  value: '$cerradas',
                  total: '$total',
                  color: AppColors.textMuted,
                  icon: Icons.water_drop_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KpiCard(
                  label: 'Nodo',
                  value: nodoOnline ? 'Online' : 'Offline',
                  total: null,
                  color: nodoOnline ? AppColors.success : AppColors.danger,
                  icon: nodoOnline
                      ? Icons.wifi_rounded
                      : Icons.wifi_off_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Acciones rápidas de zona ─────────────────────────────────────
          if (valves.isNotEmpty) ...[
            const Text(
              'CONTROL RÁPIDO',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            _QuickZoneControls(valves: valves),
            const SizedBox(height: 24),
          ],

          // ── Navegación ───────────────────────────────────────────────────
          const Text(
            'SECCIONES',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _NavCard(
                icon: Icons.water_drop_rounded,
                titulo: 'Válvulas',
                subtitulo: 'Control manual',
                color: AppColors.primary,
                onTap: () => context.go('/dashboard/valvulas'),
              ),
              _NavCard(
                icon: Icons.map_rounded,
                titulo: 'Mapa',
                subtitulo: 'Vista satelital',
                color: const Color(0xFF6366F1),
                onTap: () => context.go('/dashboard/mapa'),
              ),
              _NavCard(
                icon: Icons.schedule_rounded,
                titulo: 'Horarios',
                subtitulo: 'Programa horarios de riego',
                color: AppColors.warning,
                onTap: () => context.go('/dashboard/horarios'),
              ),
              _NavCard(
                icon: Icons.sensors_rounded,
                titulo: 'Sensores',
                subtitulo: 'Próximamente',
                color: AppColors.textMuted,
                onTap: null,
              ),
              _NavCard(
                icon: Icons.history_rounded,
                titulo: 'Historial',
                subtitulo: 'Eventos de riego',
                color: const Color(0xFF8B5CF6),
                onTap: () => context.go('/dashboard/historial'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── KPI Card ──────────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String? total;
  final Color color;
  final IconData icon;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              if (total != null) ...[
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '/$total',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Control rápido de zonas ───────────────────────────────────────────────────
class _QuickZoneControls extends ConsumerWidget {
  final List<dynamic> valves;

  const _QuickZoneControls({required this.valves});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zones = <int, List<dynamic>>{};
    for (final v in valves) {
      zones.putIfAbsent(v.zoneId, () => []).add(v);
    }

    return Row(
      children: zones.entries.map((entry) {
        final zoneId = entry.key;
        final zoneVals = entry.value;
        final nombre = zoneVals.first.zoneNombre as String;
        final allOpen = zoneVals.every((v) => v.isOpen);
        final isOnline = zoneVals.any((v) => v.nodoOnline);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: entry.key != zones.keys.last ? 12 : 0,
            ),
            child: GestureDetector(
              onTap: isOnline
                  ? () => ref
                        .read(valveProvider.notifier)
                        .sendZoneCommand(zoneId, allOpen ? 'cerrar' : 'abrir')
                  : null,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: allOpen
                      ? AppColors.primary.withOpacity(0.1)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: allOpen
                        ? AppColors.primary.withOpacity(0.5)
                        : AppColors.border,
                    width: allOpen ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          allOpen
                              ? Icons.water_rounded
                              : Icons.water_drop_outlined,
                          color: allOpen
                              ? AppColors.primary
                              : AppColors.textMuted,
                          size: 18,
                        ),
                        const Spacer(),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOnline
                                ? AppColors.success
                                : AppColors.offline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      nombre,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      allOpen ? 'Regando' : 'Detenido',
                      style: TextStyle(
                        color: allOpen
                            ? AppColors.primary
                            : AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? (allOpen
                                  ? AppColors.danger.withOpacity(0.15)
                                  : AppColors.primary.withOpacity(0.15))
                            : AppColors.border.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        !isOnline
                            ? 'Sin conexión'
                            : allOpen
                            ? 'Cerrar'
                            : 'Abrir',
                        style: TextStyle(
                          color: !isOnline
                              ? AppColors.textMuted
                              : allOpen
                              ? AppColors.danger
                              : AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Nav Card ──────────────────────────────────────────────────────────────────
class _NavCard extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final Color color;
  final VoidCallback? onTap;

  const _NavCard({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(
                  titulo,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
