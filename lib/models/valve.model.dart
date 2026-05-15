class ValveModel {
  final int     id;
  final String  valveId;
  final String  nombre;
  final int     canalRele;
  final String  estado;
  final bool    activa;
  final int     zoneId;
  final String  zoneNombre;
  final String  nodeId;
  final double? latitud;   // nuevo
  final double? longitud;  // nuevo

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
    this.latitud,
    this.longitud,
  });

  bool get isOpen => estado == 'ABIERTA';
  bool get hasLocation => latitud != null && longitud != null;

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
      latitud:    (json['latitud'] as num?)?.toDouble(),
      longitud:   (json['longitud'] as num?)?.toDouble(),
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
      latitud:    latitud,
      longitud:   longitud,
    );
  }
}