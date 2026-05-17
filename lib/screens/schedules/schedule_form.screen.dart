import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/schedule.provider.dart';
import '../../providers/valve.provider.dart';
import '../../widgets/common/error_snackbar.dart';

class ScheduleFormScreen extends ConsumerStatefulWidget {
  const ScheduleFormScreen({super.key});

  @override
  ConsumerState<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends ConsumerState<ScheduleFormScreen> {
  final _nombreCtrl = TextEditingController();

  // Tipo
  String _tipo = 'ZONA';
  int?   _zonaId;
  int?   _valveDbId;

  // Modo
  String       _modo       = 'SEMANAL';
  List<int>    _dias       = [];
  DateTime?    _fechaExacta;

  // Horario
  TimeOfDay _horaApertura = const TimeOfDay(hour: 6, minute: 0);
  bool      _cierreAuto   = true;
  TimeOfDay? _horaCierre;

  bool _loading = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  int? get _duracionS {
    if (!_cierreAuto || _horaCierre == null) return null;
    final aperturaMin = _horaApertura.hour * 60 + _horaApertura.minute;
    final cierreMin   = _horaCierre!.hour * 60 + _horaCierre!.minute;
    final diff        = cierreMin - aperturaMin;
    return diff > 0 ? diff * 60 : null;
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime({required bool esApertura}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: esApertura ? _horaApertura : (_horaCierre ?? _horaApertura),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFF52b788)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (esApertura) _horaApertura = picked;
        else            _horaCierre   = picked;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context:     context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate:   DateTime.now(),
      lastDate:    DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFF52b788)),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    if (!context.mounted) return;
    final hora = await showTimePicker(
      context:     context,
      initialTime: _horaApertura,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFF52b788)),
        ),
        child: child!,
      ),
    );
    if (hora != null) {
      setState(() {
        _fechaExacta = DateTime(
          picked.year, picked.month, picked.day,
          hora.hour, hora.minute,
        );
        _horaApertura = hora;
      });
    }
  }

  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty) {
      showErrorSnackbar(context, 'El nombre es requerido');
      return;
    }
    if (_tipo == 'ZONA' && _zonaId == null) {
      showErrorSnackbar(context, 'Selecciona una zona');
      return;
    }
    if (_tipo == 'VALVULA' && _valveDbId == null) {
      showErrorSnackbar(context, 'Selecciona una válvula');
      return;
    }
    if (_modo == 'SEMANAL' && _dias.isEmpty) {
      showErrorSnackbar(context, 'Selecciona al menos un día');
      return;
    }
    if (_modo == 'FECHA_EXACTA' && _fechaExacta == null) {
      showErrorSnackbar(context, 'Selecciona la fecha y hora');
      return;
    }
    if (_cierreAuto && _duracionS == null) {
      showErrorSnackbar(context, 'La hora de cierre debe ser posterior a la apertura');
      return;
    }

    setState(() => _loading = true);

    try {
      await ref.read(scheduleProvider.notifier).create({
        'nombre':      _nombreCtrl.text.trim(),
        'tipo':        _tipo,
        'zoneId':      _tipo == 'ZONA' ? _zonaId : null,
        'valveId':     _tipo == 'VALVULA' ? _valveDbId : null,
        'modo':        _modo,
        'dias':        _modo == 'SEMANAL' ? _dias : [],
        'fechaExacta': _modo == 'FECHA_EXACTA' ? _fechaExacta!.toIso8601String() : null,
        'hora':        _formatTime(_horaApertura),
        'cierreAuto':  _cierreAuto,
        'duracionS':   _duracionS,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final valvesState = ref.watch(valveProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0f1a14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a2f20),
        title: const Text(
          'Nuevo Horario',
          style: TextStyle(color: Color(0xFF95d5b2)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF52b788)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Nombre ────────────────────────────────────────────────────
            _SectionTitle('Nombre del horario'),
            const SizedBox(height: 8),
            _Field(
              controller: _nombreCtrl,
              hint:       'Ej: Riego mañanero Zona Norte',
            ),
            const SizedBox(height: 20),

            // ── Tipo ──────────────────────────────────────────────────────
            _SectionTitle('Programar por'),
            const SizedBox(height: 8),
            _SegmentedRow(
              options: const ['ZONA', 'VALVULA'],
              labels:  const ['Zona', 'Válvula'],
              value:   _tipo,
              onChanged: (v) => setState(() { _tipo = v; _zonaId = null; _valveDbId = null; }),
            ),
            const SizedBox(height: 12),

            // Selector zona o válvula
            valvesState.when(
              loading: () => const CircularProgressIndicator(color: Color(0xFF52b788)),
              error:   (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
              data:    (valves) {
                if (_tipo == 'ZONA') {
                  // Zonas únicas
                  final zonas = <int, String>{};
                  for (final v in valves) zonas[v.zoneId] = v.zoneNombre;

                  return _Dropdown<int>(
                    hint:     'Seleccionar zona',
                    value:    _zonaId,
                    items:    zonas.entries.map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value))
                    ).toList(),
                    onChanged: (v) => setState(() => _zonaId = v),
                  );
                } else {
                  return _Dropdown<int>(
                    hint:  'Seleccionar válvula',
                    value: _valveDbId,
                    items: valves.map((v) =>
                        DropdownMenuItem(
                          value: v.id,
                          child: Text('${v.nombre} (${v.zoneNombre})'),
                        )
                    ).toList(),
                    onChanged: (v) => setState(() => _valveDbId = v),
                  );
                }
              },
            ),
            const SizedBox(height: 20),

            // ── Modo ──────────────────────────────────────────────────────
            _SectionTitle('Tipo de programación'),
            const SizedBox(height: 8),
            _SegmentedRow(
              options: const ['SEMANAL', 'FECHA_EXACTA'],
              labels:  const ['Semanal', 'Fecha exacta'],
              value:   _modo,
              onChanged: (v) => setState(() => _modo = v),
            ),
            const SizedBox(height: 12),

            if (_modo == 'SEMANAL') ...[
              _SectionTitle('Días de la semana'),
              const SizedBox(height: 8),
              _DaySelector(
                selected:  _dias,
                onChanged: (dias) => setState(() => _dias = dias),
              ),
            ] else ...[
              _SectionTitle('Fecha y hora'),
              const SizedBox(height: 8),
              _TimeButton(
                label: _fechaExacta != null
                    ? '${_fechaExacta!.day}/${_fechaExacta!.month}/${_fechaExacta!.year} ${_formatTime(TimeOfDay.fromDateTime(_fechaExacta!))}'
                    : 'Seleccionar fecha y hora',
                icon:    Icons.calendar_today_rounded,
                onTap:   _pickDate,
              ),
            ],
            const SizedBox(height: 20),

            // ── Hora de apertura ──────────────────────────────────────────
            if (_modo == 'SEMANAL') ...[
              _SectionTitle('Hora de apertura'),
              const SizedBox(height: 8),
              _TimeButton(
                label:  _formatTime(_horaApertura),
                icon:   Icons.play_circle_outline,
                onTap:  () => _pickTime(esApertura: true),
              ),
              const SizedBox(height: 20),
            ],

            // ── Cierre ────────────────────────────────────────────────────
            _SectionTitle('Cierre'),
            const SizedBox(height: 8),
            _SegmentedRow(
              options:   const ['auto', 'manual'],
              labels:    const ['Automático', 'Manual'],
              value:     _cierreAuto ? 'auto' : 'manual',
              onChanged: (v) => setState(() => _cierreAuto = v == 'auto'),
            ),

            if (_cierreAuto) ...[
              const SizedBox(height: 12),
              _TimeButton(
                label: _horaCierre != null
                    ? _formatTime(_horaCierre!)
                    : 'Seleccionar hora de cierre',
                icon:  Icons.stop_circle_outlined,
                onTap: () => _pickTime(esApertura: false),
              ),
              if (_duracionS != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Duración: ${_duracionS! ~/ 60} minutos',
                    style: const TextStyle(
                      color:   Color(0xFF52b788),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
            const SizedBox(height: 32),

            // ── Guardar ───────────────────────────────────────────────────
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2d6a4f),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Guardar horario',
                  style: TextStyle(
                    color:      Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize:   15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color:       Color(0xFF95d5b2),
      fontSize:    13,
      fontWeight:  FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _Field({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    style:      const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText:    hint,
      hintStyle:   const TextStyle(color: Color(0xFF3d5a47)),
      filled:      true,
      fillColor:   const Color(0xFF1a2f20),
      border:      OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:   BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:   const BorderSide(color: Color(0xFF52b788)),
      ),
    ),
  );
}

class _SegmentedRow extends StatelessWidget {
  final List<String> options;
  final List<String> labels;
  final String       value;
  final Function(String) onChanged;

  const _SegmentedRow({
    required this.options,
    required this.labels,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(options.length, (i) {
        final isSelected = options[i] == value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(options[i]),
            child: Container(
              margin:  EdgeInsets.only(right: i < options.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color:        isSelected
                    ? const Color(0xFF2d6a4f)
                    : const Color(0xFF1a2f20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF52b788)
                      : const Color(0xFF2d3a30),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                labels[i],
                style: TextStyle(
                  color:      isSelected
                      ? const Color(0xFF95d5b2)
                      : const Color(0xFF4a5a50),
                  fontWeight: FontWeight.w600,
                  fontSize:   13,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _DaySelector extends StatelessWidget {
  final List<int>       selected;
  final Function(List<int>) onChanged;

  const _DaySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const dias  = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    const nums  = [1, 2, 3, 4, 5, 6, 7];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final isSelected = selected.contains(nums[i]);
        return GestureDetector(
          onTap: () {
            final updated = List<int>.from(selected);
            if (isSelected) updated.remove(nums[i]);
            else             updated.add(nums[i]);
            onChanged(updated..sort());
          },
          child: Container(
            width:  38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? const Color(0xFF2d6a4f)
                  : const Color(0xFF1a2f20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF52b788)
                    : const Color(0xFF2d3a30),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              dias[i],
              style: TextStyle(
                color:      isSelected
                    ? const Color(0xFF95d5b2)
                    : const Color(0xFF4a5a50),
                fontWeight: FontWeight.bold,
                fontSize:   13,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String   label;
  final IconData icon;
  final VoidCallback onTap;

  const _TimeButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color:        const Color(0xFF1a2f20),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: const Color(0xFF2d3a30)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF52b788), size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFd8f3dc), fontSize: 14),
          ),
          const Spacer(),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF52b788),
            size:  20,
          ),
        ],
      ),
    ),
  );
}

class _Dropdown<T> extends StatelessWidget {
  final String hint;
  final T?     value;
  final List<DropdownMenuItem<T>> items;
  final Function(T?) onChanged;

  const _Dropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color:        const Color(0xFF1a2f20),
      borderRadius: BorderRadius.circular(10),
      border:       Border.all(color: const Color(0xFF2d3a30)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value:       value,
        hint:        Text(hint, style: const TextStyle(color: Color(0xFF3d5a47))),
        isExpanded:  true,
        dropdownColor: const Color(0xFF1a2f20),
        style:       const TextStyle(color: Color(0xFFd8f3dc)),
        icon:        const Icon(Icons.expand_more, color: Color(0xFF52b788)),
        items:       items,
        onChanged:   onChanged,
      ),
    ),
  );
}