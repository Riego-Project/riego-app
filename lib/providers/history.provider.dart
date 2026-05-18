import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/valve_event.model.dart';
import '../repositories/valve.repository.dart';

final historyRepositoryProvider = Provider<ValveRepository>(
  (ref) => ValveRepository(),
);

class HistoryNotifier extends AsyncNotifier<List<ValveEventModel>> {
  @override
  Future<List<ValveEventModel>> build() async {
    return ref.read(historyRepositoryProvider).getHistory();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(historyRepositoryProvider).getHistory(),
    );
  }
}

final historyProvider =
    AsyncNotifierProvider<HistoryNotifier, List<ValveEventModel>>(
      HistoryNotifier.new,
    );
