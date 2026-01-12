import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../domain/measurement.dart';
import '../providers/measurements_providers.dart';

/// Bottom sheet for adding a new measurement
/// Matches web form structure and validation
class AddMeasurementSheet extends ConsumerStatefulWidget {
  const AddMeasurementSheet({
    super.key,
    required this.memberId,
    required this.organizationId,
  });

  final String memberId;
  final String organizationId;

  @override
  ConsumerState<AddMeasurementSheet> createState() => _AddMeasurementSheetState();
}

class _AddMeasurementSheetState extends ConsumerState<AddMeasurementSheet> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _measuredAt;
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _muscleMassController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _measuredAt = DateTime.now();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _bodyFatController.dispose();
    _muscleMassController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _hasAnyValue =>
      _heightController.text.isNotEmpty ||
      _weightController.text.isNotEmpty ||
      _bodyFatController.text.isNotEmpty ||
      _muscleMassController.text.isNotEmpty ||
      _waistController.text.isNotEmpty ||
      _hipController.text.isNotEmpty;

  double? _parseDouble(String value) {
    if (value.isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '.'));
  }

  // Validation ranges matching web
  String? _validateHeight(String? value) {
    if (value == null || value.isEmpty) return null;
    final num = _parseDouble(value);
    if (num == null || num <= 0 || num > 300) {
      return 'Altura válida: 1-300 cm';
    }
    return null;
  }

  String? _validateWeight(String? value) {
    if (value == null || value.isEmpty) return null;
    final num = _parseDouble(value);
    if (num == null || num <= 0 || num > 500) {
      return 'Peso válido: 1-500 kg';
    }
    return null;
  }

  String? _validateBodyFat(String? value) {
    if (value == null || value.isEmpty) return null;
    final num = _parseDouble(value);
    if (num == null || num < 3 || num > 70) {
      return 'Grasa válida: 3-70%';
    }
    return null;
  }

  String? _validateMuscleMass(String? value) {
    if (value == null || value.isEmpty) return null;
    final num = _parseDouble(value);
    if (num == null || num <= 0 || num > 200) {
      return 'Masa válida: 1-200 kg';
    }
    return null;
  }

  String? _validateCircumference(String? value) {
    if (value == null || value.isEmpty) return null;
    final num = _parseDouble(value);
    if (num == null || num <= 0 || num > 300) {
      return 'Valor válido: 1-300 cm';
    }
    return null;
  }

  double? _calculateBmiPreview() {
    final height = _parseDouble(_heightController.text);
    final weight = _parseDouble(_weightController.text);
    if (height != null && weight != null && height > 0) {
      final heightM = height / 100;
      return weight / (heightM * heightM);
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasAnyValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa al menos un valor'),
          backgroundColor: GymGoColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final formData = MeasurementFormData(
      measuredAt: _measuredAt,
      heightCm: _parseDouble(_heightController.text),
      weightKg: _parseDouble(_weightController.text),
      bodyFatPercentage: _parseDouble(_bodyFatController.text),
      muscleMassKg: _parseDouble(_muscleMassController.text),
      waistCm: _parseDouble(_waistController.text),
      hipCm: _parseDouble(_hipController.text),
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    final result = await ref.read(measurementsNotifierProvider.notifier).addMeasurement(
          memberId: widget.memberId,
          organizationId: widget.organizationId,
          formData: formData,
        );

    setState(() => _isSubmitting = false);

    if (result != null && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medición guardada'),
          backgroundColor: GymGoColors.success,
        ),
      );
    } else if (mounted) {
      final error = ref.read(measurementsNotifierProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Error al guardar'),
          backgroundColor: GymGoColors.error,
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _measuredAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: GymGoColors.primary,
              surface: GymGoColors.cardBackground,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _measuredAt = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bmiPreview = _calculateBmiPreview();

    return Container(
      decoration: const BoxDecoration(
        color: GymGoColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Form(
            key: _formKey,
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: GymGoColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GymGoSpacing.screenHorizontal,
                    vertical: GymGoSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Nueva medición',
                        style: GymGoTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(LucideIcons.x),
                        color: GymGoColors.textSecondary,
                      ),
                    ],
                  ),
                ),

                const Divider(color: GymGoColors.cardBorder, height: 1),

                // Form content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
                    children: [
                      // Date selector
                      _SectionHeader(title: 'Fecha'),
                      const SizedBox(height: GymGoSpacing.sm),
                      InkWell(
                        onTap: _selectDate,
                        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                        child: Container(
                          padding: const EdgeInsets.all(GymGoSpacing.md),
                          decoration: BoxDecoration(
                            color: GymGoColors.inputBackground,
                            borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                            border: Border.all(color: GymGoColors.inputBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.calendar,
                                color: GymGoColors.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: GymGoSpacing.md),
                              Text(
                                _formatDate(_measuredAt),
                                style: GymGoTypography.bodyMedium,
                              ),
                              const Spacer(),
                              const Icon(
                                LucideIcons.chevronDown,
                                color: GymGoColors.textTertiary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: GymGoSpacing.lg),

                      // Body measurements section
                      _SectionHeader(title: 'Medidas corporales'),
                      const SizedBox(height: GymGoSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _MeasurementField(
                              controller: _heightController,
                              label: 'Altura',
                              unit: 'cm',
                              icon: LucideIcons.moveVertical,
                              validator: _validateHeight,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: GymGoSpacing.md),
                          Expanded(
                            child: _MeasurementField(
                              controller: _weightController,
                              label: 'Peso',
                              unit: 'kg',
                              icon: LucideIcons.scale,
                              validator: _validateWeight,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),

                      // BMI Preview
                      if (bmiPreview != null) ...[
                        const SizedBox(height: GymGoSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(GymGoSpacing.md),
                          decoration: BoxDecoration(
                            color: GymGoColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.activity,
                                color: GymGoColors.info,
                                size: 20,
                              ),
                              const SizedBox(width: GymGoSpacing.sm),
                              Text(
                                'IMC calculado: ${bmiPreview.toStringAsFixed(1)}',
                                style: GymGoTypography.bodyMedium.copyWith(
                                  color: GymGoColors.info,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: GymGoSpacing.lg),

                      // Body composition section
                      _SectionHeader(title: 'Composición corporal'),
                      const SizedBox(height: GymGoSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _MeasurementField(
                              controller: _bodyFatController,
                              label: '% Grasa',
                              unit: '%',
                              icon: LucideIcons.percent,
                              validator: _validateBodyFat,
                            ),
                          ),
                          const SizedBox(width: GymGoSpacing.md),
                          Expanded(
                            child: _MeasurementField(
                              controller: _muscleMassController,
                              label: 'Masa muscular',
                              unit: 'kg',
                              icon: LucideIcons.dumbbell,
                              validator: _validateMuscleMass,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: GymGoSpacing.lg),

                      // Circumference section
                      _SectionHeader(title: 'Circunferencias'),
                      const SizedBox(height: GymGoSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _MeasurementField(
                              controller: _waistController,
                              label: 'Cintura',
                              unit: 'cm',
                              icon: LucideIcons.circle,
                              validator: _validateCircumference,
                            ),
                          ),
                          const SizedBox(width: GymGoSpacing.md),
                          Expanded(
                            child: _MeasurementField(
                              controller: _hipController,
                              label: 'Cadera',
                              unit: 'cm',
                              icon: LucideIcons.circle,
                              validator: _validateCircumference,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: GymGoSpacing.lg),

                      // Notes section
                      _SectionHeader(title: 'Notas (opcional)'),
                      const SizedBox(height: GymGoSpacing.sm),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        style: GymGoTypography.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Observaciones adicionales...',
                          hintStyle: GymGoTypography.bodyMedium.copyWith(
                            color: GymGoColors.inputPlaceholder,
                          ),
                          filled: true,
                          fillColor: GymGoColors.inputBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                            borderSide: const BorderSide(color: GymGoColors.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                            borderSide: const BorderSide(color: GymGoColors.inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                            borderSide: const BorderSide(color: GymGoColors.primary),
                          ),
                        ),
                      ),

                      const SizedBox(height: GymGoSpacing.xl),
                    ],
                  ),
                ),

                // Submit button
                Container(
                  padding: EdgeInsets.fromLTRB(
                    GymGoSpacing.screenHorizontal,
                    GymGoSpacing.md,
                    GymGoSpacing.screenHorizontal,
                    GymGoSpacing.md + MediaQuery.of(context).padding.bottom,
                  ),
                  decoration: const BoxDecoration(
                    color: GymGoColors.cardBackground,
                    border: Border(
                      top: BorderSide(color: GymGoColors.cardBorder),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GymGoColors.primary,
                        foregroundColor: GymGoColors.background,
                        disabledBackgroundColor: GymGoColors.primary.withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: GymGoColors.background,
                              ),
                            )
                          : Text(
                              'Guardar medición',
                              style: GymGoTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: GymGoColors.background,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${dt.day} de ${months[dt.month - 1]} de ${dt.year}';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: GymGoTypography.labelSmall.copyWith(
        color: GymGoColors.textTertiary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _MeasurementField extends StatelessWidget {
  const _MeasurementField({
    required this.controller,
    required this.label,
    required this.unit,
    required this.icon,
    this.validator,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String unit;
  final IconData icon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
      ],
      style: GymGoTypography.bodyMedium,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GymGoTypography.bodySmall.copyWith(
          color: GymGoColors.textSecondary,
        ),
        suffixText: unit,
        suffixStyle: GymGoTypography.bodySmall.copyWith(
          color: GymGoColors.textTertiary,
        ),
        prefixIcon: Icon(icon, color: GymGoColors.textTertiary, size: 20),
        filled: true,
        fillColor: GymGoColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          borderSide: const BorderSide(color: GymGoColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          borderSide: const BorderSide(color: GymGoColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          borderSide: const BorderSide(color: GymGoColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          borderSide: const BorderSide(color: GymGoColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: GymGoSpacing.md,
          vertical: GymGoSpacing.md,
        ),
      ),
    );
  }
}
