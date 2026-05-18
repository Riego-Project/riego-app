import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme/app_theme.dart';
import '../../models/schedule.model.dart';
import '../../providers/schedule.provider.dart';
import '../../providers/valve.provider.dart';
import '../../widgets/common/error_snackbar.dart';

class ScheduleFormScreen extends ConsumerStatefulWidget {
  final ScheduleModel? schedule; // null = crear, no-null = editar

  const ScheduleFormScreen({super.key, this.schedule});

  @override
  ConsumerState<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends ConsumerState<ScheduleFormScreen> {
  late final TextEditingController _nombreCtrl;
  late String _tipo;
  late int? _zonaId;
  late int? _valveDbId;
  late String _modo;
  late List<int> _dias;
  DateTime? _fechaExacta;
  late TimeOfDay _horaApertura;
  late bool _cierreAuto;
  TimeOfDay? _horaCierre;
  bool _loading = false;

  bool get _esEdicion => widget.schedule != null;

  @override
  void initState() {
    super.initState();
    final s = widget.schedule;
    _nombreCtrl = TextEditingController(text: s?.nombre ?? '');
    _tipo = s?.tipo ?? 'ZONA';
    _zonaId = s?.zonaId;
    _valveDbId = null; // se resuelve con valveId string → id int en build
    _modo = s?.modo ?? 'SEMANAL';
    _dias = List<int>.from(s?.dias ?? []);
    _fechaExacta = s?.fechaExacta;
    _cierreAuto = s?.cierreAuto ?? true;

    if (s != null) {
      final parts = s.hora.split(':');
      _horaApertura = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
      if (s.cierreAuto && s.duracionS != null) {
        final totalMin =
            _horaApertura.hour * 60 + _horaApertura.minute + s.duracionS! ~/ 60;
        _horaCierre = TimeOfDay(
          hour: totalMin ~/ 60 % 24,
          minute: totalMin % 60,
        );
      }
    } else {
      _horaApertura = const TimeOfDay(hour: 6, minute: 0);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  int? get _duracionS {
    if (!_cierreAuto || _horaCierre == null) return null;
    final aMin = _horaApertura.hour * 60 + _horaApertura.minute;
    final cMin = _horaCierre!.hour * 60 + _horaCierre!.minute;
    final diff = cMin - aMin;
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
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null)
      setState(() {
        if (esApertura)
          _horaApertura = picked;
        else
          _horaCierre = picked;
      });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _fechaExacta?.toLocal() ??
          DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null || !context.mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaApertura,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (hora != null)
      setState(() {
        _fechaExacta = DateTime(
          picked.year,
          picked.month,
          picked.day,
          hora.hour,
          hora.minute,
        ).toUtc();
        _horaApertura = hora;
      });
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
      showErrorSnackbar(context, 'La hora de cierre debe ser posterior');
      return;
    }

    setState(() => _loading = true);

    final data = {
      'nombre': _nombreCtrl.text.trim(),
      'tipo': _tipo,
      'zoneId': _tipo == 'ZONA' ? _zonaId : null,
      'valveId': _tipo == 'VALVULA' ? _valveDbId : null,
      'modo': _modo,
      'dias': _modo == 'SEMANAL' ? _dias : [],
      'fechaExacta': _modo == 'FECHA_EXACTA'
          ? _fechaExacta!.toIso8601String()
          : null,
      'hora': _formatTime(_horaApertura),
      'cierreAuto': _cierreAuto,
      'duracionS': _duracionS,
    };

    try {
      if (_esEdicion) {
        await ref
            .read(scheduleProvider.notifier)
            .updateSchedule(widget.schedule!.id, data);
      } else {
        await ref.read(scheduleProvider.notifier).create(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        showErrorSnackbar(context, e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final valvesState = ref.watch(valveProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Horario' : 'Nuevo Horario'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle('Nombre del horario'),
            const SizedBox(height: 8),
            _Field(
              controller: _nombreCtrl,
              hint: 'Ej: Riego mañanero Zona Norte',
            ),
            const SizedBox(height: 20),

            _SectionTitle('Programar por'),
            const SizedBox(height: 8),
            _SegmentedRow(
              options: const ['ZONA', 'VALVULA'],
              labels: const ['Zona', 'Válvula'],
              value: _tipo,
              onChanged: (v) => setState(() {
                _tipo = v;
                _zonaId = null;
                _valveDbId = null;
              }),
            ),
            const SizedBox(height: 12),

            valvesState.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text(
                'Error: $e',
                style: const TextStyle(color: AppColors.danger),
              ),
              data: (valves) {
                if (_tipo == 'ZONA') {
                  final zonas = <int, String>{};
                  for (final v in valves) zonas[v.zoneId] = v.zoneNombre;

                  // Pre-seleccionar zona si es edición
                  if (_esEdicion &&
                      _zonaId == null &&
                      widget.schedule?.zonaId != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() => _zonaId = widget.schedule!.zonaId);
                    });
                  }

                  return _Dropdown<int>(
                    hint: 'Seleccionar zona',
                    value: _zonaId,
                    items: zonas.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _zonaId = v),
                  );
                } else {
                  // Pre-seleccionar válvula si es edición
                  if (_esEdicion &&
                      _valveDbId == null &&
                      widget.schedule?.valveId != null) {
                    final match = valves
                        .where((v) => v.valveId == widget.schedule!.valveId)
                        .firstOrNull;
                    if (match != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() => _valveDbId = match.id);
                      });
                    }
                  }

                  return _Dropdown<int>(
                    hint: 'Seleccionar válvula',
                    value: _valveDbId,
                    items: valves
                        .map(
                          (v) => DropdownMenuItem(
                            value: v.id,
                            child: Text('${v.nombre} (${v.zoneNombre})'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _valveDbId = v),
                  );
                }
              },
            ),
            const SizedBox(height: 20),

            _SectionTitle('Tipo de programación'),
            const SizedBox(height: 8),
            _SegmentedRow(
              options: const ['SEMANAL', 'FECHA_EXACTA'],
              labels: const ['Semanal', 'Fecha exacta'],
              value: _modo,
              onChanged: (v) => setState(() => _modo = v),
            ),
            const SizedBox(height: 12),

            if (_modo == 'SEMANAL') ...[
              _SectionTitle('Días de la semana'),
              const SizedBox(height: 8),
              _DaySelector(
                selected: _dias,
                onChanged: (d) => setState(() => _dias = d),
              ),
            ] else ...[
              _SectionTitle('Fecha y hora'),
              const SizedBox(height: 8),
              _TimeButton(
                label: _fechaExacta != null
                    ? () {
                        final l = _fechaExacta!.toLocal();
                        return '${l.day}/${l.month}/${l.year} '
                            '${_formatTime(TimeOfDay.fromDateTime(l))}';
                      }()
                    : 'Seleccionar fecha y hora',
                icon: Icons.calendar_today_rounded,
                onTap: _pickDate,
              ),
            ],
            const SizedBox(height: 20),

            if (_modo == 'SEMANAL') ...[
              _SectionTitle('Hora de apertura'),
              const SizedBox(height: 8),
              _TimeButton(
                label: _formatTime(_horaApertura),
                icon: Icons.play_circle_outline,
                onTap: () => _pickTime(esApertura: true),
              ),
              const SizedBox(height: 20),
            ],

            _SectionTitle('Cierre'),
            const SizedBox(height: 8),
            _SegmentedRow(
              options: const ['auto', 'manual'],
              labels: const ['Automático', 'Manual'],
              value: _cierreAuto ? 'auto' : 'manual',
              onChanged: (v) => setState(() => _cierreAuto = v == 'auto'),
            ),

            if (_cierreAuto) ...[
              const SizedBox(height: 12),
              _TimeButton(
                label: _horaCierre != null
                    ? _formatTime(_horaCierre!)
                    : 'Seleccionar hora de cierre',
                icon: Icons.stop_circle_outlined,
                onTap: () => _pickTime(esApertura: false),
              ),
              if (_duracionS != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Duración: ${_duracionS! ~/ 60} minutos',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
            const SizedBox(height: 32),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _guardar,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        _esEdicion ? 'Guardar cambios' : 'Crear horario',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
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

// ── Widgets auxiliares (mismos que antes) ─────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 13,
      fontWeight: FontWeight.w600,
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
    style: const TextStyle(color: AppColors.textPrimary),
    decoration: InputDecoration(hintText: hint),
  );
}

class _SegmentedRow extends StatelessWidget {
  final List<String> options, labels;
  final String value;
  final Function(String) onChanged;

  const _SegmentedRow({
    required this.options,
    required this.labels,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(options.length, (i) {
      final sel = options[i] == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(options[i]),
          child: Container(
            margin: EdgeInsets.only(right: i < options.length - 1 ? 8 : 0),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: sel
                  ? AppColors.primary.withOpacity(0.15)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: sel ? AppColors.primary : AppColors.border,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              labels[i],
              style: TextStyle(
                color: sel ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }),
  );
}

class _DaySelector extends StatelessWidget {
  final List<int> selected;
  final Function(List<int>) onChanged;

  const _DaySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const dias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    const nums = [1, 2, 3, 4, 5, 6, 7];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final sel = selected.contains(nums[i]);
        return GestureDetector(
          onTap: () {
            final u = List<int>.from(selected);
            sel ? u.remove(nums[i]) : u.add(nums[i]);
            onChanged(u..sort());
          },
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: sel
                  ? AppColors.primary.withOpacity(0.15)
                  : AppColors.surface,
              border: Border.all(
                color: sel ? AppColors.primary : AppColors.border,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              dias[i],
              style: TextStyle(
                color: sel ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
          const Spacer(),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ],
      ),
    ),
  );
}

class _Dropdown<T> extends StatelessWidget {
  final String hint;
  final T? value;
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
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        hint: Text(hint, style: const TextStyle(color: AppColors.textMuted)),
        isExpanded: true,
        dropdownColor: AppColors.surface,
        style: const TextStyle(color: AppColors.textPrimary),
        icon: const Icon(Icons.expand_more, color: AppColors.primary),
        items: items,
        onChanged: onChanged,
      ),
    ),
  );
}
