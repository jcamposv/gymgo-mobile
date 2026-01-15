import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../domain/finance_models.dart';
import '../providers/finances_providers.dart';

/// Screen for creating a new income entry
class CreateIncomeScreen extends ConsumerStatefulWidget {
  const CreateIncomeScreen({super.key});

  @override
  ConsumerState<CreateIncomeScreen> createState() => _CreateIncomeScreenState();
}

class _CreateIncomeScreenState extends ConsumerState<CreateIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  IncomeCategory _selectedCategory = IncomeCategory.other;
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createIncomeProvider);

    return Scaffold(
      backgroundColor: GymGoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Nuevo Ingreso'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(GymGoSpacing.md),
              decoration: BoxDecoration(
                color: GymGoColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                border: Border.all(
                  color: GymGoColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.info,
                    size: 18,
                    color: GymGoColors.info,
                  ),
                  const SizedBox(width: GymGoSpacing.sm),
                  Expanded(
                    child: Text(
                      'Registra ingresos adicionales (no membresías). Los pagos de membresía se registran en la pestaña "Pagos".',
                      style: GymGoTypography.labelSmall.copyWith(
                        color: GymGoColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: GymGoSpacing.lg),

            // Description
            Text(
              'Descripción *',
              style: GymGoTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: GymGoSpacing.xs),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'Ej: Venta de suplementos',
                prefixIcon: const Icon(LucideIcons.fileText),
                filled: true,
                fillColor: GymGoColors.surface,
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
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa una descripción';
                }
                return null;
              },
            ),

            const SizedBox(height: GymGoSpacing.md),

            // Category
            Text(
              'Categoría *',
              style: GymGoTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: GymGoSpacing.xs),
            _buildCategorySelector(),

            const SizedBox(height: GymGoSpacing.md),

            // Amount
            Text(
              'Monto *',
              style: GymGoTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: GymGoSpacing.xs),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                hintText: '0.00',
                prefixIcon: const Icon(LucideIcons.dollarSign),
                filled: true,
                fillColor: GymGoColors.surface,
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
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa el monto';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Ingresa un monto válido';
                }
                return null;
              },
            ),

            const SizedBox(height: GymGoSpacing.md),

            // Income date
            Text(
              'Fecha del Ingreso *',
              style: GymGoTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: GymGoSpacing.xs),
            _buildDateSelector(),

            const SizedBox(height: GymGoSpacing.md),

            // Notes
            Text(
              'Notas',
              style: GymGoTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: GymGoSpacing.xs),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Notas adicionales...',
                filled: true,
                fillColor: GymGoColors.surface,
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
              ),
            ),

            const SizedBox(height: GymGoSpacing.xl),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (createState.isLoading || _isSubmitting)
                    ? null
                    : _submitIncome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GymGoColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                  ),
                ),
                child: createState.isLoading || _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Registrar Ingreso',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: GymGoSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: GymGoSpacing.sm,
      runSpacing: GymGoSpacing.sm,
      children: IncomeCategory.values.map((category) {
        final isSelected = _selectedCategory == category;
        return InkWell(
          onTap: () {
            setState(() {
              _selectedCategory = category;
            });
          },
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: GymGoSpacing.md,
              vertical: GymGoSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? GymGoColors.success.withValues(alpha: 0.1)
                  : GymGoColors.surface,
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
              border: Border.all(
                color: isSelected ? GymGoColors.success : GymGoColors.cardBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(category),
                  size: 16,
                  color: isSelected ? GymGoColors.success : GymGoColors.textSecondary,
                ),
                const SizedBox(width: GymGoSpacing.xs),
                Text(
                  category.label,
                  style: GymGoTypography.labelMedium.copyWith(
                    color: isSelected ? GymGoColors.success : GymGoColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateSelector() {
    final dateFormat = DateFormat('dd MMM yyyy', 'es');

    return InkWell(
      onTap: _selectDate,
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
            Icon(
              LucideIcons.calendar,
              size: 20,
              color: GymGoColors.textSecondary,
            ),
            const SizedBox(width: GymGoSpacing.sm),
            Expanded(
              child: Text(
                dateFormat.format(_selectedDate),
                style: GymGoTypography.bodyMedium,
              ),
            ),
            Icon(
              LucideIcons.chevronDown,
              size: 18,
              color: GymGoColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(IncomeCategory category) {
    switch (category) {
      case IncomeCategory.productSale:
        return LucideIcons.shoppingBag;
      case IncomeCategory.service:
        return LucideIcons.briefcase;
      case IncomeCategory.rental:
        return LucideIcons.key;
      case IncomeCategory.event:
        return LucideIcons.calendar;
      case IncomeCategory.donation:
        return LucideIcons.heart;
      case IncomeCategory.other:
        return LucideIcons.moreHorizontal;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: GymGoColors.primary,
                  onPrimary: Colors.white,
                  surface: GymGoColors.surface,
                  onSurface: GymGoColors.textPrimary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitIncome() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final dto = CreateIncomeDto(
        description: _descriptionController.text.trim(),
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        incomeDate: _selectedDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text.trim(),
      );

      final success =
          await ref.read(createIncomeProvider.notifier).createIncome(dto);

      if (success && mounted) {
        ref.invalidate(incomeListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ingreso registrado exitosamente'),
            backgroundColor: GymGoColors.success,
          ),
        );
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al registrar el ingreso'),
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
}
