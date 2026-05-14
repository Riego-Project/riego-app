import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  late io.Socket socket;

  SocketService._internal() {
    socket = io.io(AppConfig.socketUrl, io.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build(),
    );

    socket.onConnect((_)    => print('[WS] Conectado'));
    socket.onDisconnect((_) => print('[WS] Desconectado'));
    socket.onError((e)      => print('[WS] Error: $e'));
  }

  void connect()     => socket.connect();
  void disconnect()  => socket.disconnect();

  void on(String event, Function(dynamic) handler) {
    socket.on(event, handler);
  }

  void off(String event) {
    socket.off(event);
  }
}