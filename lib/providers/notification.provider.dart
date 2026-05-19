import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/socket.service.dart';

class AppNotification {
  final String  tipo;     // 'horario' | 'nodo_offline' | 'error'
  final String  titulo;
  final String  mensaje;
  final DateTime timestamp;

  const AppNotification({
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    required this.timestamp,
  });
}

class NotificationNotifier extends Notifier<List<AppNotification>> {
  final _socket = SocketService();

  @override
  List<AppNotification> build() {
    _listenToSocket();
    return [];
  }

  void _listenToSocket() {
    _socket.on('horario:ejecutado', (data) {
      _add(AppNotification(
        tipo:      'horario',
        titulo:    'Riego iniciado',
        mensaje:   data['nombre'] as String? ?? 'Horario ejecutado',
        timestamp: DateTime.now(),
      ));
    });

    _socket.on('horario:cerrado', (data) {
      _add(AppNotification(
        tipo:      'horario',
        titulo:    'Riego finalizado',
        mensaje:   data['nombre'] as String? ?? 'Riego completado',
        timestamp: DateTime.now(),
      ));
    });

    _socket.on('nodo:offline', (data) {
      _add(AppNotification(
        tipo:      'nodo_offline',
        titulo:    'Nodo desconectado',
        mensaje:   '${data['nombre'] ?? 'Nodo'} perdió conexión',
        timestamp: DateTime.now(),
      ));
    });
  }

  void _add(AppNotification notification) {
    state = [notification, ...state.take(49).toList()]; // máximo 50
  }

  void clear() => state = [];
}

final notificationProvider = NotifierProvider<NotificationNotifier, List<AppNotification>>(
  NotificationNotifier.new,
);

// Cantidad de notificaciones no leídas
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).length;
});