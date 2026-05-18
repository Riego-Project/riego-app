import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme/app_theme.dart';
import '../../models/valve_event.model.dart';
import '../../providers/history.provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Riegos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(historyProvider.notifier).refresh(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.danger,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                e.toString().replaceAll('Exception: ', ''),
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(historyProvider.notifier).refresh(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (events) {
          if (events.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    color: AppColors.textMuted,
                    size: 56,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Sin eventos registrados',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          // Agrupar por fecha
          final grouped = <String, List<ValveEventModel>>{};
          for (final e in events) {
            final key = _formatDate(e.createdAt);
            grouped.putIfAbsent(key, () => []).add(e);
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: grouped.length,
            itemBuilder: (_, i) {
              final date = grouped.keys.elementAt(i);
              final dayEvents = grouped[date]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header de fecha
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            date,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(height: 1, color: AppColors.border),
                        ),
                      ],
                    ),
                  ),

                  // Eventos del día
                  ...dayEvents.map((e) => _EventTile(event: e)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);

    if (date == today) return 'Hoy';
    if (date == today.subtract(const Duration(days: 1))) return 'Ayer';

    const meses = [
      '',
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${dt.day} ${meses[dt.month]} ${dt.year}';
  }
}

class _EventTile extends StatelessWidget {
  final ValveEventModel event;

  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final isApertura = event.esApertura;
    final color = isApertura ? AppColors.primary : AppColors.textMuted;
    final hora =
        '${event.createdAt.toLocal().hour.toString().padLeft(2, '0')}:'
        '${event.createdAt.toLocal().minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isApertura
              ? AppColors.primary.withOpacity(0.2)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // Icono
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isApertura ? Icons.water_drop_rounded : Icons.water_drop_outlined,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.valveNombre,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      event.zoneNombre,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const Text(
                      ' · ',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        event.origenTexto,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    if (event.duracionS != null) ...[
                      const Text(
                        ' · ',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      Text(
                        event.duracionTexto,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Hora + estado
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hora,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isApertura
                      ? AppColors.primary.withOpacity(0.12)
                      : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isApertura
                        ? AppColors.primary.withOpacity(0.3)
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  isApertura ? 'ABRIÓ' : 'CERRÓ',
                  style: TextStyle(
                    color: isApertura ? AppColors.primary : AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
