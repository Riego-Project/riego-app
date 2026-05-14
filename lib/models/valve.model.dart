class ValveModel {
  final int    id;
  final String valveId;
  final String nombre;
  final int    canalRele;
  final String estado;
  final bool   activa;
  final int    zoneId;
  final String zoneNombre;
  final String nodeId;

  const ValveModel({
    required this.id,
    required this.valveId,
    required this.nombre,
    required this.canalRele,
    required this.estado,
    required this.activa,
    required this.zoneId,
    required this.zoneNombre,
    required this.nodeId,
  });

  bool get isOpen => estado == 'ABIERTA';

  factory ValveModel.fromJson(Map<String, dynamic> json) {
    return ValveModel(
      id:         json['id'] as int,
      valveId:    json['valveId'] as String,
      nombre:     json['nombre'] as String,
      canalRele:  json['canalRele'] as int,
      estado:     json['estado'] as String,
      activa:     json['activa'] as bool,
      zoneId:     json['zone']['id'] as int,
      zoneNombre: json['zone']['nombre'] as String,
      nodeId:     json['node']['nodeId'] as String,
    );
  }

  ValveModel copyWith({ String? estado }) {
    return ValveModel(
      id:         id,
      valveId:    valveId,
      nombre:     nombre,
      canalRele:  canalRele,
      estado:     estado ?? this.estado,
      activa:     activa,
      zoneId:     zoneId,
      zoneNombre: zoneNombre,
      nodeId:     nodeId,
    );
  }
}