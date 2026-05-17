import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/schedule.model.dart';
import '../repositories/schedule.repository.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>(
      (ref) => ScheduleRepository(),
);

class ScheduleNotifier extends AsyncNotifier<List<ScheduleModel>> {
  @override
  Future<List<ScheduleModel>> build() async {
    return ref.read(scheduleRepositoryProvider).getAll();
  }

  Future<void> create(Map<String, dynamic> data) async {
    await ref.read(scheduleRepositoryProvider).create(data);
    await refresh();
  }

  Future<void> toggle(int id, bool activo) async {
    await ref.read(scheduleRepositoryProvider).toggle(id, activo);
    state.whenData((schedules) {
      final updated = schedules.map((s) {
        if (s.id == id) {
          return ScheduleModel(
            id:          s.id,
            nombre:      s.nombre,
            activo:      activo,
            tipo:        s.tipo,
            modo:        s.modo,
            dias:        s.dias,
            fechaExacta: s.fechaExacta,
            hora:        s.hora,
            cierreAuto:  s.cierreAuto,
            duracionS:   s.duracionS,
            zonaId:      s.zonaId,
            zonaNombre:  s.zonaNombre,
            valveId:     s.valveId,
            valveNombre: s.valveNombre,
          );
        }
        return s;
      }).toList();
      state = AsyncData(updated);
    });
  }

  Future<void> delete(int id) async {
    await ref.read(scheduleRepositoryProvider).delete(id);
    state.whenData((schedules) {
      state = AsyncData(schedules.where((s) => s.id != id).toList());
    });
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
          () => ref.read(scheduleRepositoryProvider).getAll(),
    );
  }
}

final scheduleProvider = AsyncNotifierProvider<ScheduleNotifier, List<ScheduleModel>>(
  ScheduleNotifier.new,
);