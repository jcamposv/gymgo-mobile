import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../domain/benchmark.dart';
import '../providers/benchmarks_providers.dart';
import 'exercise_picker.dart';

/// Bottom sheet for adding a new PR entry
class AddPRSheet extends ConsumerStatefulWidget {
  const AddPRSheet({
    super.key,
    this.preselectedExerciseId,
    required this.onSuccess,
  });

  final String? preselectedExerciseId;
  final VoidCallback onSuccess;

  @override
  ConsumerState<AddPRSheet> createState() => _AddPRSheetState();
}

class _AddPRSheetState extends ConsumerState<AddPRSheet> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _repsController = TextEditingController();
  final _setsController = TextEditingController();
  final _rpeController = TextEditingController();
  final _notesController = TextEditingController();

  ExerciseOption? _selectedExercise;
  BenchmarkUnit _selectedUnit = BenchmarkUnit.kg;
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _valueController.dispose();
    _repsController.dispose();
    _setsController.dispose();
    _rpeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: GymGoColors.primary,
              onPrimary: GymGoColors.background,
              surface: GymGoColors.surface,
              onSurface: GymGoColors.textPrimary,
            ),
            dialogBackgroundColor: GymGoColors.cardBackground,
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedExercise == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un ejercicio'),
          backgroundColor: GymGoColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final formData = BenchmarkFormData(
        exerciseId: _selectedExercise!.id,
        value: double.parse(_valueController.text),
        unit: _selectedUnit,
        reps: _repsController.text.isNotEmpty ? int.parse(_repsController.text) : null,
        sets: _setsController.text.isNotEmpty ? int.parse(_setsController.text) : null,
        rpe: _rpeController.text.isNotEmpty ? double.parse(_rpeController.text) : null,
        achievedAt: _selectedDate,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      final result = await ref.read(benchmarkActionsProvider.notifier).createBenchmark(formData);

      if (result != null && mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.isPr ? '¡Nuevo PR registrado!' : 'Registro guardado',
            ),
            backgroundColor: result.isPr ? GymGoColors.primary : GymGoColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: GymGoColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final exerciseOptionsAsync = ref.watch(exerciseOptionsProvider);

    // Handle preselected exercise
    if (widget.preselectedExerciseId != null && _selectedExercise == null) {
      exerciseOptionsAsync.whenData((options) {
        final preselected = options.firstWhere(
          (e) => e.id == widget.preselectedExerciseId,
          orElse: () => options.first,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _selectedExercise == null) {
            setState(() {
              _selectedExercise = preselected;
            });
          }
        });
      });
    }

    return Container(
      decoration: const BoxDecoration(
        color: GymGoColors.cardBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GymGoSpacing.radiusXl),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: GymGoColors.cardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: GymGoSpacing.lg),

                  // Header
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: GymGoColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
                        ),
                        child: const Icon(
                          LucideIcons.trophy,
                          color: GymGoColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: GymGoSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Registrar PR',
                            style: GymGoTypography.headlineSmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Agrega un nuevo record personal',
                            style: GymGoTypography.bodySmall.copyWith(
                              color: GymGoColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: GymGoSpacing.xl),

                  // Exercise picker
                  _buildLabel('Ejercicio *'),
                  const SizedBox(height: GymGoSpacing.xs),
                  exerciseOptionsAsync.when(
                    data: (options) => ExercisePicker(
                      options: options,
                      selectedOption: _selectedExercise,
                      onSelected: (exercise) {
                        setState(() {
                          _selectedExercise = exercise;
                        });
                      },
                    ),
                    loading: () => Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: GymGoColors.surface,
                        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: GymGoColors.primary,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    error: (_, __) => const Text('Error loading exercises'),
                  ),
                  const SizedBox(height: GymGoSpacing.lg),

                  // Value and Unit row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Value
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Valor *'),
                            const SizedBox(height: GymGoSpacing.xs),
                            _buildTextField(
                              controller: _valueController,
                              hint: '0',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Requerido';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Número inválido';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: GymGoSpacing.md),
                      // Unit
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Unidad'),
                            const SizedBox(height: GymGoSpacing.xs),
                            _buildUnitDropdown(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: GymGoSpacing.lg),

                  // Reps, Sets, RPE row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Reps'),
                            const SizedBox(height: GymGoSpacing.xs),
                            _buildTextField(
                              controller: _repsController,
                              hint: 'Ej: 5',
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: GymGoSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Sets'),
                            const SizedBox(height: GymGoSpacing.xs),
                            _buildTextField(
                              controller: _setsController,
                              hint: 'Ej: 3',
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: GymGoSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('RPE'),
                            const SizedBox(height: GymGoSpacing.xs),
                            _buildTextField(
                              controller: _rpeController,
                              hint: '1-10',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                              ],
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final rpe = double.tryParse(value);
                                  if (rpe == null || rpe < 1 || rpe > 10) {
                                    return '1-10';
                                  }
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: GymGoSpacing.lg),

                  // Date picker
                  _buildLabel('Fecha'),
                  const SizedBox(height: GymGoSpacing.xs),
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: GymGoSpacing.md,
                        vertical: GymGoSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: GymGoColors.surface,
                        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.calendar,
                            color: GymGoColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: GymGoSpacing.sm),
                          Text(
                            _formatDate(_selectedDate),
                            style: GymGoTypography.bodyMedium,
                          ),
                          const Spacer(),
                          const Icon(
                            LucideIcons.chevronDown,
                            color: GymGoColors.textTertiary,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: GymGoSpacing.lg),

                  // Notes
                  _buildLabel('Notas'),
                  const SizedBox(height: GymGoSpacing.xs),
                  _buildTextField(
                    controller: _notesController,
                    hint: 'Notas opcionales...',
                    maxLines: 3,
                    maxLength: 500,
                  ),
                  const SizedBox(height: GymGoSpacing.xl),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GymGoColors.primary,
                        foregroundColor: GymGoColors.background,
                        padding: const EdgeInsets.symmetric(
                          vertical: GymGoSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                        ),
                        disabledBackgroundColor: GymGoColors.primary.withValues(alpha: 0.5),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: GymGoColors.background,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Guardar PR',
                              style: GymGoTypography.buttonLarge,
                            ),
                    ),
                  ),
                  const SizedBox(height: GymGoSpacing.xxl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GymGoTypography.labelMedium.copyWith(
        color: GymGoColors.textSecondary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      maxLength: maxLength,
      style: GymGoTypography.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GymGoTypography.bodyMedium.copyWith(
          color: GymGoColors.textTertiary,
        ),
        filled: true,
        fillColor: GymGoColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          borderSide: BorderSide.none,
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
        counterText: '',
      ),
    );
  }

  Widget _buildUnitDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: GymGoSpacing.md),
      decoration: BoxDecoration(
        color: GymGoColors.surface,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<BenchmarkUnit>(
          value: _selectedUnit,
          isExpanded: true,
          dropdownColor: GymGoColors.surfaceElevated,
          icon: const Icon(
            LucideIcons.chevronDown,
            color: GymGoColors.textTertiary,
            size: 18,
          ),
          style: GymGoTypography.bodyMedium,
          items: BenchmarkUnit.values.map((unit) {
            return DropdownMenuItem(
              value: unit,
              child: Text(unit.displayLabel),
            );
          }).toList(),
          onChanged: (unit) {
            if (unit != null) {
              setState(() {
                _selectedUnit = unit;
              });
            }
          },
        ),
      ),
    );
  }
}
