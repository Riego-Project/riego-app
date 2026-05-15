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
    // Confirmación de estado de válvula desde ESP32
    _socket.on('valvula:estado', (data) {
      state.whenData((valves) {
        final updated = valves.map((v) {
          if (v.valveId == data['valveId']) {
            return v.copyWith(estado: data['estado'] as String);
          }
          return v;
        }).toList();
        state = AsyncData(updated);
      });
    });

    // Nodo se desconecta
    _socket.on('nodo:offline', (data) {
      state.whenData((valves) {
        final updated = valves.map((v) {
          if (v.nodeId == data['nodeId']) {
            return v.copyWith(nodoOnline: false);
          }
          return v;
        }).toList();
        state = AsyncData(updated);
      });
    });

    // Nodo vuelve a conectarse (heartbeat)
    _socket.on('nodo:estado', (data) {
      state.whenData((valves) {
        final updated = valves.map((v) {
          if (v.nodeId == data['nodeId']) {
            return v.copyWith(nodoOnline: true);
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