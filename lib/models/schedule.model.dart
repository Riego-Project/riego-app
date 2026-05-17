class ScheduleModel {
  final int     id;
  final String  nombre;
  final bool    activo;
  final String  tipo;        // 'ZONA' | 'VALVULA'
  final String  modo;        // 'SEMANAL' | 'FECHA_EXACTA'
  final List<int> dias;
  final DateTime? fechaExacta;
  final String  hora;
  final bool    cierreAuto;
  final int?    duracionS;
  final int?    zonaId;
  final String? zonaNombre;
  final String? valveId;
  final String? valveNombre;

  const ScheduleModel({
    required this.id,
    required this.nombre,
    required this.activo,
    required this.tipo,
    required this.modo,
    required this.dias,
    this.fechaExacta,
    required this.hora,
    required this.cierreAuto,
    this.duracionS,
    this.zonaId,
    this.zonaNombre,
    this.valveId,
    this.valveNombre,
  });

  String get objetivoNombre {
    if (tipo == 'ZONA') return zonaNombre ?? 'Zona desconocida';
    return valveNombre ?? 'Válvula desconocida';
  }

  String get duracionTexto {
    if (!cierreAuto || duracionS == null) return 'Cierre manual';
    final minutos = duracionS! ~/ 60;
    final segundos = duracionS! % 60;
    if (segundos == 0) return '$minutos min';
    return '${minutos}m ${segundos}s';
  }

  String get diasTexto {
    if (modo == 'FECHA_EXACTA') {
      if (fechaExacta == null) return '';
      return '${fechaExacta!.day}/${fechaExacta!.month}/${fechaExacta!.year}';
    }
    const nombres = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return dias.map((d) => nombres[d]).join(', ');
  }

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id:          json['id'] as int,
      nombre:      json['nombre'] as String,
      activo:      json['activo'] as bool,
      tipo:        json['tipo'] as String,
      modo:        json['modo'] as String,
      dias:        (json['dias'] as List).map((e) => e as int).toList(),
      fechaExacta: json['fechaExacta'] != null
          ? DateTime.parse(json['fechaExacta'])
          : null,
      hora:        json['hora'] as String,
      cierreAuto:  json['cierreAuto'] as bool,
      duracionS:   json['duracionS'] as int?,
      zonaId:      json['zone']?['id'] as int?,
      zonaNombre:  json['zone']?['nombre'] as String?,
      valveId:     json['valve']?['valveId'] as String?,
      valveNombre: json['valve']?['nombre'] as String?,
    );
  }
}