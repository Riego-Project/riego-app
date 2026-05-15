import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/valve.model.dart';
import '../repositories/valve.repository.dart';
import '../services/socket.service.dart';

final valveRepositoryProvider = Provider<ValveRepository>((ref) => ValveRepository());

class ValveNotifier extends AsyncNotifier<List<ValveModel>> {
  final _socket = SocketService();

  @override
  Future<List<ValveModel>> build() async {
    _listenToSocket();
    return ref.read(valveRepositoryProvider).getAll();
  }

  void _listenToSocket() {
    _socket.on('nodo:offline', (data) {
      state.whenData((valves) {
        // Marcar todas las válvulas de ese nodo como offline
        final updated = valves.map((v) {
          if (v.nodeId == data['nodeId']) {
            return v.copyWith(nodoOnline: false);
          }
          return v;
        }).toList();
        state = AsyncData(updated);
      });
    });
  }

  Future<void> sendCommand(String valveId, String accion) async {
    await ref.read(valveRepositoryProvider).sendCommand(valveId, accion);
  }

  Future<void> sendZoneCommand(int zoneId, String accion) async {
    await ref.read(valveRepositoryProvider).sendZoneCommand(zoneId, accion);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
          () => ref.read(valveRepositoryProvider).getAll(),
    );
  }
}

final valveProvider = AsyncNotifierProvider<ValveNotifier, List<ValveModel>>(
  ValveNotifier.new,
);