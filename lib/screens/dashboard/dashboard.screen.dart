import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth.provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f1a14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a2f20),
        title: const Text(
          'Panel de Control',
          style: TextStyle(color: Color(0xFF95d5b2)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF52b788)),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Bienvenido',
              style: TextStyle(
                color: Color(0xFF95d5b2),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sistema de riego · 2 hectáreas · Ayacucho',
              style: TextStyle(color: Color(0xFF52b788), fontSize: 14),
            ),
            const SizedBox(height: 32),
            _DashboardCard(
              icon:    Icons.water_drop_rounded,
              titulo:  'Válvulas',
              subtitulo: 'Control manual y estado en tiempo real',
              onTap:   () => context.go('/dashboard/valvulas'),
            ),
            const SizedBox(height: 16),
            _DashboardCard(
              icon:     Icons.schedule_rounded,
              titulo:   'Horarios',
              subtitulo: 'Programar riegos automáticos',
              onTap:    () => context.go('/dashboard/horarios'),
            ),
            const SizedBox(height: 16),
            _DashboardCard(
              icon:     Icons.sensors_rounded,
              titulo:   'Sensores',
              subtitulo: 'Humedad de suelo · pH del agua',
              onTap:    () {}, // fase 2
              disabled: true,
            ),
            const SizedBox(height: 16),
            _DashboardCard(
              icon:     Icons.map_rounded,
              titulo:   'Mapa',
              subtitulo: 'Ver válvulas en vista satelital',
              onTap:    () => context.go('/dashboard/mapa'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String   titulo;
  final String   subtitulo;
  final VoidCallback onTap;
  final bool     disabled;

  const _DashboardCard({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: Material(
        color: const Color(0xFF1a2f20),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap:        disabled ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding:      const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:        const Color(0xFF2d6a4f),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF95d5b2), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          color: Color(0xFF95d5b2),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitulo,
                        style: const TextStyle(
                          color: Color(0xFF52b788),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!disabled)
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFF52b788),
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}