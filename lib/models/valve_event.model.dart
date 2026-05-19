class ValveEventModel {
  final int id;
  final String accion;
  final String origen;
  final bool confirmado;
  final int? duracionS;
  final DateTime createdAt;
  final String valveId;
  final String valveNombre;
  final String zoneNombre;

  const ValveEventModel({
    required this.id,
    required this.accion,
    required this.origen,
    required this.confirmado,
    this.duracionS,
    required this.createdAt,
    required this.valveId,
    required this.valveNombre,
    required this.zoneNombre,
  });

  bool get esApertura => accion == 'ABRIR';

  String get duracionTexto {
    if (duracionS == null) return '';
    final m = duracionS! ~/ 60;
    final s = duracionS! % 60;
    if (m == 0) return '${s}s';
    if (s == 0) return '${m}m';
    return '${m}m ${s}s';
  }

  String get origenTexto {
    switch (origen) {
      case 'MANUAL':
        return 'Manual';
      case 'HORARIO':
        return 'Horario';
      case 'SENSOR':
        return 'Sensor';
      default:
        return 'Sistema';
    }
  }

  factory ValveEventModel.fromJson(Map<String, dynamic> json) {
    return ValveEventModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      accion: json['accion'] as String,
      origen: json['origen'] as String,
      confirmado: json['confirmado'] as bool,
      duracionS: json['duracionS'] as int?,
      createdAt: DateTime.parse(json['createdAt']),
      valveId: json['valve']['valveId'] as String,
      valveNombre: json['valve']['nombre'] as String,
      zoneNombre: json['valve']['zone']['nombre'] as String,
    );
  }
}
