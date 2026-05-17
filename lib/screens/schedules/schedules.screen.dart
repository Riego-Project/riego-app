import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/schedule.model.dart';
import '../../providers/schedule.provider.dart';
import '../../widgets/common/error_snackbar.dart';
import 'schedule_form.screen.dart';

class SchedulesScreen extends ConsumerWidget {
  const SchedulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scheduleProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0f1a14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a2f20),
        title: const Text(
          'Horarios',
          style: TextStyle(color: Color(0xFF95d5b2)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF52b788)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(scheduleProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2d6a4f),
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScheduleFormScreen()),
        ).then((_) => ref.read(scheduleProvider.notifier).refresh()),
        child: const Icon(Icons.add),
      ),
      body: state.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF52b788)),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(e.toString(), style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(scheduleProvider.notifier).refresh(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (schedules) {
          if (schedules.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    color: Color(0xFF2d6a4f),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay horarios programados',
                    style: TextStyle(
                      color: Color(0xFF52b788),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Toca + para crear uno',
                    style: TextStyle(
                      color: Color(0xFF2d6a4f),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: schedules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _ScheduleCard(schedule: schedules[i]),
          );
        },
      ),
    );
  }
}

class _ScheduleCard extends ConsumerWidget {
  final ScheduleModel schedule;
  const _ScheduleCard({required this.schedule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isZona = schedule.tipo == 'ZONA';

    return Container(
      decoration: BoxDecoration(
        color:        const Color(0xFF1a2f20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: schedule.activo
              ? const Color(0xFF2d6a4f)
              : const Color(0xFF2d3a30),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            leading: Container(
              width:  44,
              height: 44,
              decoration: BoxDecoration(
                color:        schedule.activo
                    ? const Color(0xFF2d6a4f)
                    : const Color(0xFF1e2e24),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isZona
                    ? Icons.water_rounded
                    : Icons.water_drop_rounded,
                color: schedule.activo
                    ? const Color(0xFF95d5b2)
                    : const Color(0xFF3d5a47),
                size: 22,
              ),
            ),
            title: Text(
              schedule.nombre,
              style: TextStyle(
                color:      schedule.activo
                    ? const Color(0xFFd8f3dc)
                    : const Color(0xFF4a5a50),
                fontWeight: FontWeight.w600,
                fontSize:   14,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Objetivo
                  Row(
                    children: [
                      Icon(
                        isZona ? Icons.layers_rounded : Icons.water_drop_outlined,
                        size:  12,
                        color: const Color(0xFF52b788),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        schedule.objetivoNombre,
                        style: const TextStyle(
                          color:   Color(0xFF52b788),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Horario
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size:  12,
                        color: Color(0xFF52b788),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${schedule.hora} · ${schedule.diasTexto}',
                        style: const TextStyle(
                          color:   Color(0xFF52b788),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Duración
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size:  12,
                        color: Color(0xFF52b788),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        schedule.duracionTexto,
                        style: const TextStyle(
                          color:   Color(0xFF52b788),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            trailing: Switch(
              value:       schedule.activo,
              activeColor: const Color(0xFF52b788),
              inactiveThumbColor: const Color(0xFF4a5a50),
              inactiveTrackColor: const Color(0xFF2d3a30),
              onChanged: (val) async {
                try {
                  await ref.read(scheduleProvider.notifier).toggle(schedule.id, val);
                } catch (e) {
                  if (context.mounted) {
                    showErrorSnackbar(context, e.toString().replaceAll('Exception: ', ''));
                  }
                }
              },
            ),
          ),
          // Botón eliminar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _confirmDelete(context, ref),
                  icon: const Icon(
                    Icons.delete_outline,
                    size:  16,
                    color: Color(0xFF9b1c1c),
                  ),
                  label: const Text(
                    'Eliminar',
                    style: TextStyle(
                      color:   Color(0xFF9b1c1c),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a2f20),
        title: const Text(
          '¿Eliminar horario?',
          style: TextStyle(color: Color(0xFFd8f3dc)),
        ),
        content: Text(
          'Se eliminará "${schedule.nombre}" permanentemente.',
          style: const TextStyle(color: Color(0xFF52b788)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF52b788)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(scheduleProvider.notifier).delete(schedule.id);
              } catch (e) {
                if (context.mounted) {
                  showErrorSnackbar(
                    context,
                    e.toString().replaceAll('Exception: ', ''),
                  );
                }
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Color(0xFF9b1c1c)),
            ),
          ),
        ],
      ),
    );
  }
}