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

/// Screen for creating a new class template
class CreateTemplateScreen extends ConsumerStatefulWidget {
  const CreateTemplateScreen({super.key});

  @override
  ConsumerState<CreateTemplateScreen> createState() =>
      _CreateTemplateScreenState();
}

class _CreateTemplateScreenState extends ConsumerState<CreateTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _capacityController = TextEditingController(text: '20');
  final _locationController = TextEditingController();

  bool _isLoading = false;
  bool _hasChanges = false;
  Instructor? _selectedInstructor;
  int _selectedDay = 1; // Monday by default
  String? _selectedClassType;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  void _markChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime,
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
        _startTime = time;
      });
      _markChanged();
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _endTime,
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
        _endTime = time;
      });
      _markChanged();
    }
  }

  Future<void> _selectInstructor() async {
    final instructor = await InstructorPickerSheet.show(
      context,
      selectedInstructor: _selectedInstructor,
    );

    if (instructor != null) {
      setState(() {
        _selectedInstructor = instructor;
      });
      _markChanged();
    }
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final dto = CreateTemplateDto(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        classType: _selectedClassType,
        dayOfWeek: _selectedDay,
        startTime:
            '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
        endTime:
            '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
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
      );

      final template =
          await ref.read(createTemplateProvider.notifier).createTemplate(dto);

      if (template != null && mounted) {
        GymGoToast.success(context, 'Plantilla creada correctamente');
        Navigator.of(context).pop();
      } else if (mounted) {
        final error = ref.read(createTemplateProvider).error;
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GymGoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Nueva Plantilla'),
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
                      // Name
                      _buildLabel('Nombre', isRequired: true),
                      const SizedBox(height: GymGoSpacing.xs),
                      _buildTextField(
                        controller: _nameController,
                        hint: 'Ej: Yoga Matutino',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es requerido';
                          }
                          if (value.length < 2) {
                            return 'Mínimo 2 caracteres';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: GymGoSpacing.md),

                      // Description
                      _buildLabel('Descripción'),
                      const SizedBox(height: GymGoSpacing.xs),
                      _buildTextField(
                        controller: _descriptionController,
                        hint: 'Descripción de la clase',
                        maxLines: 3,
                      ),

                      const SizedBox(height: GymGoSpacing.md),

                      // Class type
                      _buildLabel('Tipo de clase'),
                      const SizedBox(height: GymGoSpacing.xs),
                      _buildClassTypePicker(),

                      const SizedBox(height: GymGoSpacing.md),

                      // Day of week
                      _buildLabel('Día', isRequired: true),
                      const SizedBox(height: GymGoSpacing.xs),
                      _buildDayPicker(),

                      const SizedBox(height: GymGoSpacing.md),

                      // Time
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Hora inicio', isRequired: true),
                                const SizedBox(height: GymGoSpacing.xs),
                                _buildTimePicker(
                                  time: _startTime,
                                  onTap: _selectStartTime,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: GymGoSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Hora fin', isRequired: true),
                                const SizedBox(height: GymGoSpacing.xs),
                                _buildTimePicker(
                                  time: _endTime,
                                  onTap: _selectEndTime,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: GymGoSpacing.md),

                      // Capacity
                      _buildLabel('Capacidad', isRequired: true),
                      const SizedBox(height: GymGoSpacing.xs),
                      _buildTextField(
                        controller: _capacityController,
                        hint: '20',
                        keyboardType: TextInputType.number,
                        prefixIcon: LucideIcons.users,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La capacidad es requerida';
                          }
                          final num = int.tryParse(value);
                          if (num == null || num < 1) {
                            return 'Mínimo 1';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: GymGoSpacing.md),

                      // Instructor
                      _buildLabel('Instructor'),
                      const SizedBox(height: GymGoSpacing.xs),
                      if (_selectedInstructor != null)
                        InstructorChip(
                          instructor: _selectedInstructor!,
                          onTap: _selectInstructor,
                        )
                      else
                        _buildEmptyPickerField(
                          icon: LucideIcons.user,
                          label: 'Seleccionar instructor',
                          hint: 'Asignar un instructor',
                          onTap: _selectInstructor,
                        ),

                      const SizedBox(height: GymGoSpacing.md),

                      // Location
                      _buildLabel('Ubicación'),
                      const SizedBox(height: GymGoSpacing.xs),
                      _buildTextField(
                        controller: _locationController,
                        hint: 'Ej: Sala principal',
                        prefixIcon: LucideIcons.mapPin,
                      ),

                      const SizedBox(height: GymGoSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom create button
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

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
    showModalBottomSheet(
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
                      ? const Icon(LucideIcons.check, color: GymGoColors.primary)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedClassType = type;
                    });
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

  Widget _buildDayPicker() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(7, (index) {
          final isSelected = _selectedDay == index;
          return Padding(
            padding: const EdgeInsets.only(right: GymGoSpacing.sm),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedDay = index;
                });
                _markChanged();
              },
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
              child: Container(
                width: 48,
                padding: const EdgeInsets.symmetric(
                  vertical: GymGoSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? GymGoColors.primary : GymGoColors.surface,
                  borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                  border: Border.all(
                    color:
                        isSelected ? GymGoColors.primary : GymGoColors.cardBorder,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      DayOfWeek.getShortName(index),
                      style: GymGoTypography.labelMedium.copyWith(
                        color:
                            isSelected ? Colors.white : GymGoColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
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
            Icon(LucideIcons.clock, size: 18, color: GymGoColors.textTertiary),
            const SizedBox(width: GymGoSpacing.sm),
            Expanded(
              child: Text(
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                style: GymGoTypography.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPickerField({
    required IconData icon,
    required String label,
    required String hint,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(GymGoSpacing.md),
        decoration: BoxDecoration(
          color: GymGoColors.surface,
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          border: Border.all(color: GymGoColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: GymGoColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: GymGoColors.primary),
            ),
            const SizedBox(width: GymGoSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GymGoTypography.bodyMedium.copyWith(
                      color: GymGoColors.textSecondary,
                    ),
                  ),
                  Text(
                    hint,
                    style: GymGoTypography.labelSmall.copyWith(
                      color: GymGoColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: GymGoColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
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
            onPressed: _isLoading ? null : _create,
            style: ElevatedButton.styleFrom(
              backgroundColor: GymGoColors.primary,
              foregroundColor: Colors.white,
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
                    'Crear plantilla',
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

  void _showDiscardDialog() {
    showDialog(
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
