import 'package:dio/dio.dart';

class AppError {
  final String mensaje;
  final bool   esConexion;

  const AppError({required this.mensaje, this.esConexion = false});
}

AppError handleError(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const AppError(
          mensaje:     'El servidor tardó demasiado en responder. Verifica tu conexión.',
          esConexion:  true,
        );

      case DioExceptionType.connectionError:
        return const AppError(
          mensaje:     'No se pudo conectar al servidor. Verifica tu internet.',
          esConexion:  true,
        );

      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        final data   = error.response?.data;

        if (status == 401) {
          return const AppError(mensaje: 'Email o contraseña incorrectos.');
        }
        if (status == 403) {
          return const AppError(mensaje: 'No tienes permiso para realizar esta acción.');
        }
        if (status == 404) {
          return const AppError(mensaje: 'El recurso solicitado no existe.');
        }
        if (status == 503) {
          return const AppError(
            mensaje:    'El nodo de riego no está disponible. Verifica la conexión del ESP32.',
            esConexion: true,
          );
        }

        // Intenta extraer el mensaje del backend
        final backendMsg = data is Map ? data['error'] as String? : null;
        return AppError(mensaje: backendMsg ?? 'Error del servidor ($status).');

      case DioExceptionType.cancel:
        return const AppError(mensaje: 'La solicitud fue cancelada.');

      default:
        return const AppError(mensaje: 'Ocurrió un error inesperado.');
    }
  }

  return AppError(mensaje: error.toString().replaceAll('Exception: ', ''));
}