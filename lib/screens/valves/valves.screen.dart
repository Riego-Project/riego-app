import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/valve.provider.dart';
import '../../models/valve.model.dart';
import '../../services/socket.service.dart';

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
      backgroundColor: const Color(0xFF0f1a14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a2f20),
        title: const Text(
          'Válvulas',
          style: TextStyle(color: Color(0xFF95d5b2)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF52b788)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(valveProvider.notifier).refresh(),
          ),
        ],
      ),
      body: valvesState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF52b788)),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error: $e',
                style: const TextStyle(color: Colors.red),
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

class _ValvesList extends ConsumerWidget {
  final List<ValveModel> valves;
  const _ValvesList({required this.valves});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Agrupar por zona
    final zones = <int, List<ValveModel>>{};
    for (final v in valves) {
      zones.putIfAbsent(v.zoneId, () => []).add(v);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Botones de zona completa
        Row(
          children: zones.entries.map((entry) {
            final zoneId    = entry.key;
            final zoneName  = entry.value.first.zoneNombre;
            final allOpen   = entry.value.every((v) => v.isOpen);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _ZoneButton(
                  nombre:  zoneName,
                  isOpen:  allOpen,
                  onTap: () => ref.read(valveProvider.notifier).sendZoneCommand(
                    zoneId,
                    allOpen ? 'cerrar' : 'abrir',
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Válvulas individuales por zona
        ...zones.entries.map((entry) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                entry.value.first.zoneNombre,
                style: const TextStyle(
                  color: Color(0xFF52b788),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ...entry.value.map((valve) => _ValveCard(valve: valve)),
            const SizedBox(height: 8),
          ],
        )),
      ],
    );
  }
}

class _ZoneButton extends StatelessWidget {
  final String nombre;
  final bool   isOpen;
  final VoidCallback onTap;

  const _ZoneButton({
    required this.nombre,
    required this.isOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isOpen
            ? const Color(0xFF9b1c1c)
            : const Color(0xFF2d6a4f),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Icon(
            isOpen ? Icons.stop_circle_outlined : Icons.play_circle_outline,
            color: Colors.white,
          ),
          const SizedBox(height: 4),
          Text(
            isOpen ? 'Cerrar $nombre' : 'Abrir $nombre',
            style: const TextStyle(color: Colors.white, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ValveCard extends ConsumerWidget {
  final ValveModel valve;
  const _ValveCard({required this.valve});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen = valve.isOpen;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color:        const Color(0xFF1a2f20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOpen
              ? const Color(0xFF52b788)
              : const Color(0xFF2d3a30),
          width: isOpen ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width:  48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOpen
                ? const Color(0xFF52b788).withOpacity(0.2)
                : const Color(0xFF2d3a30),
          ),
          child: Icon(
            isOpen ? Icons.water_drop : Icons.water_drop_outlined,
            color: isOpen
                ? const Color(0xFF52b788)
                : const Color(0xFF4a5a50),
          ),
        ),
        title: Text(
          valve.nombre,
          style: const TextStyle(
            color: Color(0xFFd8f3dc),
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Canal ${valve.canalRele} · ${valve.nodeId}',
          style: const TextStyle(
            color: Color(0xFF52b788),
            fontSize: 12,
          ),
        ),
        trailing: Switch(
          value:          isOpen,
          activeColor:    const Color(0xFF52b788),
          inactiveThumbColor: const Color(0xFF4a5a50),
          inactiveTrackColor: const Color(0xFF2d3a30),
          onChanged: (_) => ref.read(valveProvider.notifier).sendCommand(
            valve.valveId,
            isOpen ? 'cerrar' : 'abrir',
          ),
        ),
      ),
    );
  }
}