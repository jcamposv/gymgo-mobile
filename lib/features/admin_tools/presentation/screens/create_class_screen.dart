import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/components.dart';
import '../../../classes/domain/class_template.dart';
import '../../../classes/presentation/providers/templates_providers.dart';
import '../../../classes/presentation/widgets/template_picker_sheet.dart';
import '../../../classes/presentation/widgets/instructor_picker_sheet.dart';

/// Screen for creating new classes (2-step flow)
class CreateClassScreen extends ConsumerStatefulWidget {
  const CreateClassScreen({super.key});

  @override
  ConsumerState<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends ConsumerState<CreateClassScreen> {
  int _currentStep = 0;
  ClassTemplate? _selectedTemplate;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  Instructor? _selectedInstructor;
  int? _overrideCapacity;
  String? _overrideLocation;
  bool _isLoading = false;

  final _dateFormat = DateFormat('EEEE, d MMMM yyyy', 'es');

  @override
  void initState() {
    super.initState();
    // Set initial time based on template if available
  }

  void _nextStep() {
    if (_currentStep == 0 && _selectedTemplate != null && _selectedTime != null) {
      setState(() {
        _currentStep = 1;
        // Pre-fill instructor from template
        if (_selectedTemplate!.instructorId != null) {
          _loadInstructorFromTemplate();
        }
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _loadInstructorFromTemplate() async {
    if (_selectedTemplate?.instructorId == null) return;

    try {
      final repository = ref.read(templatesRepositoryProvider);
      final instructor =
          await repository.getInstructorById(_selectedTemplate!.instructorId!);
      if (instructor != null && mounted) {
        setState(() {
          _selectedInstructor = instructor;
        });
      }
    } catch (e) {
      // Silently fail - instructor can be selected manually
    }
  }

  Future<void> _selectTemplate() async {
    final template = await TemplatePickerSheet.show(
      context,
      selectedTemplate: _selectedTemplate,
    );

    if (template != null) {
      setState(() {
        _selectedTemplate = template;
        // Set time from template
        final timeParts = template.startTime.split(':');
        _selectedTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      });
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
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

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
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
        _selectedTime = time;
      });
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
    }
  }

  Future<void> _createClass() async {
    if (_selectedTemplate == null || _selectedTime == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Build the start and end times
      final startTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Calculate end time based on template duration
      final endTime = startTime.add(
        Duration(minutes: _selectedTemplate!.durationMinutes),
      );

      final dto = CreateClassDto(
        name: _selectedTemplate!.name,
        description: _selectedTemplate!.description,
        classType: _selectedTemplate!.classType,
        startTime: startTime,
        endTime: endTime,
        maxCapacity: _overrideCapacity ?? _selectedTemplate!.maxCapacity,
        waitlistEnabled: _selectedTemplate!.waitlistEnabled,
        maxWaitlist: _selectedTemplate!.maxWaitlist,
        instructorId: _selectedInstructor?.id ?? _selectedTemplate!.instructorId,
        instructorName:
            _selectedInstructor?.displayName ?? _selectedTemplate!.instructorName,
        location: _overrideLocation ?? _selectedTemplate!.location,
        bookingOpensHours: _selectedTemplate!.bookingOpensHours,
        bookingClosesMinutes: _selectedTemplate!.bookingClosesMinutes,
        cancellationDeadlineHours: _selectedTemplate!.cancellationDeadlineHours,
      );

      final success = await ref.read(createClassProvider.notifier).createClass(dto);

      if (success && mounted) {
        GymGoToast.success(context, 'Clase creada exitosamente');
        context.pop();
      } else if (mounted) {
        final error = ref.read(createClassProvider).error;
        GymGoToast.error(
          context,
          'Error al crear clase: ${error?.toString() ?? 'Intenta de nuevo'}',
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GymGoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(_currentStep == 0 ? 'Nueva Clase' : 'Confirmar Clase'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            if (_currentStep > 0) {
              _previousStep();
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step indicator
            _buildStepIndicator(),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
                child: _currentStep == 0 ? _buildStep1() : _buildStep2(),
              ),
            ),

            // Bottom button
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.screenHorizontal,
        vertical: GymGoSpacing.sm,
      ),
      child: Row(
        children: [
          _buildStepDot(0, 'Plantilla'),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep >= 1
                  ? GymGoColors.primary
                  : GymGoColors.cardBorder,
            ),
          ),
          _buildStepDot(1, 'Confirmar'),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? GymGoColors.primary : GymGoColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? GymGoColors.primary : GymGoColors.cardBorder,
              width: 2,
            ),
          ),
          child: Center(
            child: isActive && !isCurrent
                ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                : Text(
                    '${step + 1}',
                    style: GymGoTypography.labelSmall.copyWith(
                      color: isActive ? Colors.white : GymGoColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GymGoTypography.labelSmall.copyWith(
            color: isCurrent ? GymGoColors.primary : GymGoColors.textSecondary,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Template selection
        Text(
          'Plantilla',
          style: GymGoTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: GymGoSpacing.xs),

        if (_selectedTemplate != null)
          TemplateChip(
            template: _selectedTemplate!,
            onTap: _selectTemplate,
          )
        else
          _buildEmptyPickerField(
            icon: LucideIcons.layoutTemplate,
            label: 'Seleccionar plantilla',
            hint: 'Elige una plantilla de clase',
            onTap: _selectTemplate,
          ),

        const SizedBox(height: GymGoSpacing.lg),

        // Date selection
        Text(
          'Fecha',
          style: GymGoTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: GymGoSpacing.xs),
        _buildPickerField(
          icon: LucideIcons.calendar,
          value: _dateFormat.format(_selectedDate),
          onTap: _selectDate,
        ),

        const SizedBox(height: GymGoSpacing.lg),

        // Time selection
        Text(
          'Hora',
          style: GymGoTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: GymGoSpacing.xs),
        _buildPickerField(
          icon: LucideIcons.clock,
          value: _selectedTime != null
              ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
              : 'Seleccionar hora',
          onTap: _selectTime,
          isEmpty: _selectedTime == null,
        ),
      ],
    );
  }

  Widget _buildStep2() {
    if (_selectedTemplate == null) return const SizedBox.shrink();

    final effectiveCapacity = _overrideCapacity ?? _selectedTemplate!.maxCapacity;
    final effectiveLocation = _overrideLocation ?? _selectedTemplate!.location;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary card
        GymGoCard(
          padding: const EdgeInsets.all(GymGoSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: GymGoColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                    ),
                    child: const Icon(
                      LucideIcons.calendarPlus,
                      color: GymGoColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: GymGoSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedTemplate!.name,
                          style: GymGoTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_selectedTemplate!.classType != null)
                          Text(
                            _selectedTemplate!.classTypeLabel,
                            style: GymGoTypography.labelSmall.copyWith(
                              color: GymGoColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GymGoSpacing.md),
              const Divider(color: GymGoColors.cardBorder),
              const SizedBox(height: GymGoSpacing.md),

              // Date/Time
              _buildSummaryRow(
                icon: LucideIcons.calendar,
                label: 'Fecha y hora',
                value:
                    '${_dateFormat.format(_selectedDate)} a las ${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
              ),

              const SizedBox(height: GymGoSpacing.sm),

              // Duration
              _buildSummaryRow(
                icon: LucideIcons.clock,
                label: 'Duración',
                value: '${_selectedTemplate!.durationMinutes} minutos',
              ),
            ],
          ),
        ),

        const SizedBox(height: GymGoSpacing.lg),

        // Optional overrides
        Text(
          'Opciones (opcional)',
          style: GymGoTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: GymGoSpacing.xs),
        Text(
          'Puedes modificar estos valores solo para esta clase',
          style: GymGoTypography.labelSmall.copyWith(
            color: GymGoColors.textSecondary,
          ),
        ),

        const SizedBox(height: GymGoSpacing.md),

        // Instructor
        Text(
          'Instructor',
          style: GymGoTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: GymGoSpacing.xs),
        if (_selectedInstructor != null)
          InstructorChip(
            instructor: _selectedInstructor!,
            onTap: _selectInstructor,
          )
        else
          _buildEmptyPickerField(
            icon: LucideIcons.user,
            label: _selectedTemplate!.instructorName ?? 'Sin instructor',
            hint: 'Cambiar instructor',
            onTap: _selectInstructor,
          ),

        const SizedBox(height: GymGoSpacing.md),

        // Capacity
        Text(
          'Capacidad',
          style: GymGoTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: GymGoSpacing.xs),
        _buildCapacityStepper(effectiveCapacity),

        const SizedBox(height: GymGoSpacing.md),

        // Location
        Text(
          'Ubicación',
          style: GymGoTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: GymGoSpacing.xs),
        _buildLocationField(effectiveLocation),
      ],
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: GymGoColors.textTertiary),
        const SizedBox(width: GymGoSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GymGoTypography.labelSmall.copyWith(
                  color: GymGoColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: GymGoTypography.bodyMedium,
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildPickerField({
    required IconData icon,
    required String value,
    required VoidCallback onTap,
    bool isEmpty = false,
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
            Icon(icon, size: 18, color: GymGoColors.textTertiary),
            const SizedBox(width: GymGoSpacing.md),
            Expanded(
              child: Text(
                value,
                style: GymGoTypography.bodyMedium.copyWith(
                  color: isEmpty ? GymGoColors.textSecondary : null,
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

  Widget _buildCapacityStepper(int capacity) {
    return Container(
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
          Icon(LucideIcons.users, size: 18, color: GymGoColors.textTertiary),
          const SizedBox(width: GymGoSpacing.md),
          Expanded(
            child: Text(
              '$capacity lugares',
              style: GymGoTypography.bodyMedium,
            ),
          ),
          IconButton(
            onPressed: capacity > 1
                ? () {
                    setState(() {
                      _overrideCapacity = capacity - 1;
                    });
                  }
                : null,
            icon: const Icon(LucideIcons.minus),
            iconSize: 18,
            color: GymGoColors.textSecondary,
            style: IconButton.styleFrom(
              backgroundColor: GymGoColors.cardBorder,
              minimumSize: const Size(32, 32),
            ),
          ),
          const SizedBox(width: GymGoSpacing.sm),
          IconButton(
            onPressed: capacity < 500
                ? () {
                    setState(() {
                      _overrideCapacity = capacity + 1;
                    });
                  }
                : null,
            icon: const Icon(LucideIcons.plus),
            iconSize: 18,
            color: GymGoColors.textSecondary,
            style: IconButton.styleFrom(
              backgroundColor: GymGoColors.cardBorder,
              minimumSize: const Size(32, 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField(String? location) {
    final locations = ref.watch(locationsProvider);

    return InkWell(
      onTap: () => _showLocationPicker(locations.valueOrNull ?? []),
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
            Icon(LucideIcons.mapPin, size: 18, color: GymGoColors.textTertiary),
            const SizedBox(width: GymGoSpacing.md),
            Expanded(
              child: Text(
                location ?? 'Sin ubicación',
                style: GymGoTypography.bodyMedium.copyWith(
                  color: location == null ? GymGoColors.textSecondary : null,
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

  void _showLocationPicker(List<String> locations) {
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
              'Seleccionar ubicación',
              style: GymGoTypography.headlineSmall,
            ),
          ),
          if (locations.isEmpty)
            Padding(
              padding: const EdgeInsets.all(GymGoSpacing.xl),
              child: Text(
                'No hay ubicaciones disponibles',
                style: GymGoTypography.bodyMedium.copyWith(
                  color: GymGoColors.textSecondary,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: GymGoSpacing.lg),
              itemCount: locations.length,
              itemBuilder: (context, index) {
                final loc = locations[index];
                final isSelected = loc == (_overrideLocation ?? _selectedTemplate?.location);
                return ListTile(
                  leading: Icon(
                    LucideIcons.mapPin,
                    color: isSelected ? GymGoColors.primary : GymGoColors.textSecondary,
                  ),
                  title: Text(
                    loc,
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
                      _overrideLocation = loc;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          const SizedBox(height: GymGoSpacing.md),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    final canProceed = _currentStep == 0
        ? _selectedTemplate != null && _selectedTime != null
        : true;

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
            onPressed: canProceed && !_isLoading
                ? (_currentStep == 0 ? _nextStep : _createClass)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: GymGoColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: GymGoSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
              ),
              disabledBackgroundColor: GymGoColors.cardBorder,
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
                    _currentStep == 0 ? 'Siguiente' : 'Crear Clase',
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
}
