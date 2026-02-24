import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/components.dart';
import '../../../classes/domain/class_template.dart';
import '../../../classes/presentation/providers/templates_providers.dart';
import '../../../classes/presentation/widgets/instructor_picker_sheet.dart';

/// Helper class for time block state
class _TimeBlock {
  _TimeBlock({required this.start, required this.end});

  TimeOfDay start;
  TimeOfDay end;

  int get startMinutes => start.hour * 60 + start.minute;
  int get endMinutes => end.hour * 60 + end.minute;

  String get startFormatted =>
      '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
  String get endFormatted =>
      '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

  bool overlaps(_TimeBlock other) {
    return startMinutes < other.endMinutes && endMinutes > other.startMinutes;
  }
}

/// Screen for creating class templates in batch
class CreateTemplateScreen extends ConsumerStatefulWidget {
  const CreateTemplateScreen({super.key});

  @override
  ConsumerState<CreateTemplateScreen> createState() =>
      _CreateTemplateScreenState();
}

class _CreateTemplateScreenState extends ConsumerState<CreateTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController(text: '20');
  final _locationController = TextEditingController();

  bool _isLoading = false;
  bool _hasChanges = false;
  Instructor? _selectedInstructor;
  String? _selectedClassType;

  // Batch state
  List<_TimeBlock> _timeBlocks = [
    _TimeBlock(
      start: const TimeOfDay(hour: 9, minute: 0),
      end: const TimeOfDay(hour: 10, minute: 0),
    ),
  ];
  Set<int> _selectedDays = {1, 2, 3, 4, 5}; // Mon-Fri default

  int get _totalTemplates => _timeBlocks.length * _selectedDays.length;

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  // ─── Time block management ──────────────────────────────────────────

  void _addTimeBlock() {
    final last = _timeBlocks.last;
    setState(() {
      _timeBlocks.add(_TimeBlock(
        start: TimeOfDay(hour: last.end.hour, minute: last.end.minute),
        end: TimeOfDay(
          hour: (last.end.hour + 1).clamp(0, 23),
          minute: last.end.minute,
        ),
      ));
    });
    _markChanged();
  }

  void _removeTimeBlock(int index) {
    if (_timeBlocks.length <= 1) return;
    setState(() => _timeBlocks.removeAt(index));
    _markChanged();
  }

  Future<void> _selectBlockTime(int index, {required bool isStart}) async {
    final block = _timeBlocks[index];
    final time = await showTimePicker(
      context: context,
      initialTime: isStart ? block.start : block.end,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: GymGoColors.primary,
              surface: GymGoColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        if (isStart) {
          _timeBlocks[index].start = time;
        } else {
          _timeBlocks[index].end = time;
        }
      });
      _markChanged();
    }
  }

  // ─── Day selection ──────────────────────────────────────────────────

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
    _markChanged();
  }

  // ─── Instructor picker ──────────────────────────────────────────────

  Future<void> _selectInstructor() async {
    final instructor = await InstructorPickerSheet.show(
      context,
      selectedInstructor: _selectedInstructor,
    );

    if (instructor != null) {
      setState(() => _selectedInstructor = instructor);
      _markChanged();
    }
  }

  // ─── Validation ─────────────────────────────────────────────────────

  String? _validateTimeBlocks() {
    for (var i = 0; i < _timeBlocks.length; i++) {
      final block = _timeBlocks[i];
      if (block.endMinutes <= block.startMinutes) {
        return 'Horario ${i + 1}: la hora fin debe ser mayor a la hora inicio';
      }
    }
    // Check overlaps
    for (var i = 0; i < _timeBlocks.length; i++) {
      for (var j = i + 1; j < _timeBlocks.length; j++) {
        if (_timeBlocks[i].overlaps(_timeBlocks[j])) {
          return 'Los horarios ${i + 1} y ${j + 1} se traslapan';
        }
      }
    }
    return null;
  }

  // ─── Create batch ───────────────────────────────────────────────────

  Future<void> _createBatch() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDays.isEmpty) {
      GymGoToast.error(context, 'Selecciona al menos un día');
      return;
    }

    final timeError = _validateTimeBlocks();
    if (timeError != null) {
      GymGoToast.error(context, timeError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dtos = <CreateTemplateDto>[];

      for (final day in _selectedDays.toList()..sort()) {
        for (final block in _timeBlocks) {
          dtos.add(CreateTemplateDto(
            name: _nameController.text.trim(),
            classType: _selectedClassType,
            dayOfWeek: day,
            startTime: block.startFormatted,
            endTime: block.endFormatted,
            maxCapacity: int.tryParse(_capacityController.text) ?? 20,
            waitlistEnabled: true,
            maxWaitlist: 5,
            instructorId: _selectedInstructor?.id,
            instructorName: _selectedInstructor?.displayName,
            location: _locationController.text.trim().isEmpty
                ? null
                : _locationController.text.trim(),
            bookingOpensHours: 168,
            bookingClosesMinutes: 60,
            cancellationDeadlineHours: 2,
            isActive: true,
          ));
        }
      }

      final count = await ref
          .read(batchCreateTemplatesProvider.notifier)
          .createBatch(dtos);

      if (count != null && mounted) {
        GymGoToast.success(
          context,
          '$count plantilla${count == 1 ? '' : 's'} creada${count == 1 ? '' : 's'}',
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        final error = ref.read(batchCreateTemplatesProvider).error;
        GymGoToast.error(
          context,
          'Error: ${error?.toString() ?? 'Intenta de nuevo'}',
        );
      }
    } catch (e) {
      if (mounted) {
        GymGoToast.error(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GymGoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Crear Plantillas'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            if (_hasChanges) {
              _showDiscardDialog();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Name ──
                      _buildLabel('Nombre', isRequired: true),
                      const SizedBox(height: GymGoSpacing.xs),
                      _buildTextField(
                        controller: _nameController,
                        hint: 'Ej: Crossfit Mañana',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es requerido';
                          }
                          if (value.trim().length < 2) {
                            return 'Mínimo 2 caracteres';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: GymGoSpacing.md),

                      // ── Class type ──
                      _buildLabel('Tipo de clase'),
                      const SizedBox(height: GymGoSpacing.xs),
                      _buildClassTypePicker(),

                      const SizedBox(height: GymGoSpacing.lg),

                      // ── Time blocks ──
                      _buildLabel('Horarios', isRequired: true),
                      const SizedBox(height: GymGoSpacing.xs),
                      ..._buildTimeBlocksList(),
                      const SizedBox(height: GymGoSpacing.sm),
                      _buildAddTimeBlockButton(),

                      const SizedBox(height: GymGoSpacing.lg),

                      // ── Days ──
                      _buildLabel('Aplicar a', isRequired: true),
                      const SizedBox(height: GymGoSpacing.xs),
                      _buildMultiDayPicker(),

                      const SizedBox(height: GymGoSpacing.lg),

                      // ── Capacity + Instructor row ──
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Capacidad', isRequired: true),
                                const SizedBox(height: GymGoSpacing.xs),
                                _buildTextField(
                                  controller: _capacityController,
                                  hint: '20',
                                  keyboardType: TextInputType.number,
                                  prefixIcon: LucideIcons.users,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Requerido';
                                    }
                                    final num = int.tryParse(value);
                                    if (num == null || num < 1) {
                                      return 'Mínimo 1';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: GymGoSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Instructor'),
                                const SizedBox(height: GymGoSpacing.xs),
                                _buildInstructorButton(),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: GymGoSpacing.md),

                      // ── Location ──
                      _buildLabel('Ubicación'),
                      const SizedBox(height: GymGoSpacing.xs),
                      _buildTextField(
                        controller: _locationController,
                        hint: 'Ej: Sala principal',
                        prefixIcon: LucideIcons.mapPin,
                      ),

                      const SizedBox(height: GymGoSpacing.lg),

                      // ── Summary ──
                      if (_selectedDays.isNotEmpty && _timeBlocks.isNotEmpty)
                        _buildSummary(),

                      const SizedBox(height: GymGoSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom button
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  // ─── Reusable builders ──────────────────────────────────────────────

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          text,
          style: GymGoTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (isRequired)
          Text(
            ' *',
            style: GymGoTypography.labelMedium.copyWith(
              color: GymGoColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    IconData? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: GymGoTypography.bodyMedium,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: (_) => _markChanged(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GymGoTypography.bodyMedium.copyWith(
          color: GymGoColors.textTertiary,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: GymGoColors.textTertiary)
            : null,
        filled: true,
        fillColor: GymGoColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: GymGoSpacing.md,
          vertical: GymGoSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          borderSide: BorderSide(color: GymGoColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          borderSide: BorderSide(color: GymGoColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          borderSide: const BorderSide(color: GymGoColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          borderSide: const BorderSide(color: GymGoColors.error),
        ),
      ),
    );
  }

  Widget _buildClassTypePicker() {
    return InkWell(
      onTap: () => _showClassTypePicker(),
      borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: GymGoSpacing.md,
          vertical: GymGoSpacing.md,
        ),
        decoration: BoxDecoration(
          color: GymGoColors.surface,
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          border: Border.all(color: GymGoColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.tag, size: 18, color: GymGoColors.textTertiary),
            const SizedBox(width: GymGoSpacing.md),
            Expanded(
              child: Text(
                _selectedClassType != null
                    ? ClassType.getLabel(_selectedClassType!)
                    : 'Seleccionar tipo',
                style: GymGoTypography.bodyMedium.copyWith(
                  color: _selectedClassType != null
                      ? null
                      : GymGoColors.textSecondary,
                ),
              ),
            ),
            Icon(
              LucideIcons.chevronDown,
              size: 16,
              color: GymGoColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  void _showClassTypePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: GymGoColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GymGoSpacing.radiusLg),
        ),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: GymGoSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: GymGoColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(GymGoSpacing.md),
            child: Text(
              'Tipo de clase',
              style: GymGoTypography.headlineSmall,
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: GymGoSpacing.lg),
              itemCount: ClassType.all.length,
              itemBuilder: (context, index) {
                final type = ClassType.all[index];
                final isSelected = type == _selectedClassType;
                return ListTile(
                  leading: Icon(
                    LucideIcons.tag,
                    color: isSelected
                        ? GymGoColors.primary
                        : GymGoColors.textSecondary,
                  ),
                  title: Text(
                    ClassType.getLabel(type),
                    style: GymGoTypography.bodyMedium.copyWith(
                      color: isSelected ? GymGoColors.primary : null,
                      fontWeight: isSelected ? FontWeight.w600 : null,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(LucideIcons.check,
                          color: GymGoColors.primary)
                      : null,
                  onTap: () {
                    setState(() => _selectedClassType = type);
                    _markChanged();
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker({
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: GymGoSpacing.sm,
          vertical: GymGoSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: GymGoColors.surface,
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          border: Border.all(color: GymGoColors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.clock, size: 14, color: GymGoColors.textTertiary),
            const SizedBox(width: GymGoSpacing.xs),
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: GymGoTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Time blocks list ───────────────────────────────────────────────

  List<Widget> _buildTimeBlocksList() {
    return List.generate(_timeBlocks.length, (index) {
      final block = _timeBlocks[index];
      return Padding(
        padding: const EdgeInsets.only(bottom: GymGoSpacing.sm),
        child: GymGoCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GymGoSpacing.md,
              vertical: GymGoSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTimePicker(
                    time: block.start,
                    onTap: () => _selectBlockTime(index, isStart: true),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: GymGoSpacing.sm),
                  child: Text(
                    '—',
                    style: GymGoTypography.bodyMedium.copyWith(
                      color: GymGoColors.textTertiary,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildTimePicker(
                    time: block.end,
                    onTap: () => _selectBlockTime(index, isStart: false),
                  ),
                ),
                if (_timeBlocks.length > 1)
                  IconButton(
                    icon: Icon(
                      LucideIcons.trash2,
                      size: 18,
                      color: GymGoColors.error.withValues(alpha: 0.7),
                    ),
                    onPressed: () => _removeTimeBlock(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildAddTimeBlockButton() {
    return InkWell(
      onTap: _addTimeBlock,
      borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: GymGoSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          border: Border.all(
            color: GymGoColors.primary.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.plus, size: 16, color: GymGoColors.primary),
            const SizedBox(width: GymGoSpacing.xs),
            Text(
              'Agregar horario',
              style: GymGoTypography.labelMedium.copyWith(
                color: GymGoColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Multi-day picker ───────────────────────────────────────────────

  Widget _buildMultiDayPicker() {
    return Wrap(
      spacing: GymGoSpacing.sm,
      runSpacing: GymGoSpacing.sm,
      children: List.generate(7, (index) {
        final isSelected = _selectedDays.contains(index);
        return InkWell(
          onTap: () => _toggleDay(index),
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          child: Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: GymGoSpacing.sm),
            decoration: BoxDecoration(
              color: isSelected ? GymGoColors.primary : GymGoColors.surface,
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
              border: Border.all(
                color:
                    isSelected ? GymGoColors.primary : GymGoColors.cardBorder,
              ),
            ),
            child: Center(
              child: Text(
                DayOfWeek.getShortName(index),
                style: GymGoTypography.labelMedium.copyWith(
                  color: isSelected ? Colors.white : GymGoColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ─── Instructor button ──────────────────────────────────────────────

  Widget _buildInstructorButton() {
    return InkWell(
      onTap: _selectInstructor,
      borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: GymGoSpacing.md,
          vertical: GymGoSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: GymGoColors.surface,
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          border: Border.all(color: GymGoColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.user, size: 18, color: GymGoColors.textTertiary),
            const SizedBox(width: GymGoSpacing.sm),
            Expanded(
              child: Text(
                _selectedInstructor?.displayName ?? 'Seleccionar',
                style: GymGoTypography.bodyMedium.copyWith(
                  color: _selectedInstructor != null
                      ? null
                      : GymGoColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 14,
              color: GymGoColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Summary ────────────────────────────────────────────────────────

  Widget _buildSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GymGoSpacing.md),
      decoration: BoxDecoration(
        color: GymGoColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        border: Border.all(
          color: GymGoColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.info, size: 18, color: GymGoColors.primary),
          const SizedBox(width: GymGoSpacing.sm),
          Expanded(
            child: Text(
              '${_timeBlocks.length} horario${_timeBlocks.length == 1 ? '' : 's'}'
              ' × ${_selectedDays.length} día${_selectedDays.length == 1 ? '' : 's'}'
              ' = $_totalTemplates plantilla${_totalTemplates == 1 ? '' : 's'}',
              style: GymGoTypography.bodyMedium.copyWith(
                color: GymGoColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom button ──────────────────────────────────────────────────

  Widget _buildBottomButton() {
    final canCreate = _totalTemplates > 0;
    return Container(
      padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
      decoration: BoxDecoration(
        color: GymGoColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_isLoading || !canCreate) ? null : _createBatch,
            style: ElevatedButton.styleFrom(
              backgroundColor: GymGoColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  GymGoColors.primary.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(vertical: GymGoSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    canCreate
                        ? 'Generar $_totalTemplates plantilla${_totalTemplates == 1 ? '' : 's'}'
                        : 'Selecciona días y horarios',
                    style: GymGoTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ─── Discard dialog ─────────────────────────────────────────────────

  void _showDiscardDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GymGoColors.surface,
        title: const Text('Descartar cambios'),
        content: const Text('¿Deseas descartar los cambios sin guardar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GymGoColors.error,
            ),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
  }
}
