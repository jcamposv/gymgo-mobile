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

/// Screen for creating a new expense
class CreateExpenseScreen extends ConsumerStatefulWidget {
  const CreateExpenseScreen({super.key});

  @override
  ConsumerState<CreateExpenseScreen> createState() => _CreateExpenseScreenState();
}

class _CreateExpenseScreenState extends ConsumerState<CreateExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _vendorController = TextEditingController();
  final _notesController = TextEditingController();

  ExpenseCategory _selectedCategory = ExpenseCategory.other;
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _vendorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createExpenseProvider);

    return Scaffold(
      backgroundColor: GymGoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Nuevo Gasto'),
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
                hintText: 'Ej: Pago de luz',
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

            // Expense date
            Text(
              'Fecha del Gasto *',
              style: GymGoTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: GymGoSpacing.xs),
            _buildDateSelector(),

            const SizedBox(height: GymGoSpacing.md),

            // Vendor
            Text(
              'Proveedor',
              style: GymGoTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: GymGoSpacing.xs),
            TextFormField(
              controller: _vendorController,
              decoration: InputDecoration(
                hintText: 'Ej: CFE, Telmex',
                prefixIcon: const Icon(LucideIcons.store),
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

            const SizedBox(height: GymGoSpacing.md),

            // Recurring toggle
            Container(
              padding: const EdgeInsets.all(GymGoSpacing.md),
              decoration: BoxDecoration(
                color: GymGoColors.surface,
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                border: Border.all(color: GymGoColors.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.repeat,
                    size: 20,
                    color: _isRecurring
                        ? GymGoColors.primary
                        : GymGoColors.textSecondary,
                  ),
                  const SizedBox(width: GymGoSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gasto Recurrente',
                          style: GymGoTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Marcar si es un gasto mensual/periódico',
                          style: GymGoTypography.labelSmall.copyWith(
                            color: GymGoColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isRecurring,
                    onChanged: (value) {
                      setState(() {
                        _isRecurring = value;
                      });
                    },
                    activeColor: GymGoColors.primary,
                  ),
                ],
              ),
            ),

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
                    : _submitExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GymGoColors.error,
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
                        'Registrar Gasto',
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
      children: ExpenseCategory.values.map((category) {
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
                  ? GymGoColors.error.withValues(alpha: 0.1)
                  : GymGoColors.surface,
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
              border: Border.all(
                color: isSelected ? GymGoColors.error : GymGoColors.cardBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(category),
                  size: 16,
                  color: isSelected ? GymGoColors.error : GymGoColors.textSecondary,
                ),
                const SizedBox(width: GymGoSpacing.xs),
                Text(
                  category.label,
                  style: GymGoTypography.labelMedium.copyWith(
                    color: isSelected ? GymGoColors.error : GymGoColors.textPrimary,
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

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.rent:
        return LucideIcons.home;
      case ExpenseCategory.utilities:
        return LucideIcons.zap;
      case ExpenseCategory.salaries:
        return LucideIcons.users;
      case ExpenseCategory.equipment:
        return LucideIcons.dumbbell;
      case ExpenseCategory.maintenance:
        return LucideIcons.wrench;
      case ExpenseCategory.marketing:
        return LucideIcons.megaphone;
      case ExpenseCategory.supplies:
        return LucideIcons.package;
      case ExpenseCategory.insurance:
        return LucideIcons.shield;
      case ExpenseCategory.taxes:
        return LucideIcons.landmark;
      case ExpenseCategory.other:
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

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final dto = CreateExpenseDto(
        description: _descriptionController.text.trim(),
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        expenseDate: _selectedDate,
        vendor: _vendorController.text.isEmpty ? null : _vendorController.text.trim(),
        notes: _notesController.text.isEmpty ? null : _notesController.text.trim(),
        isRecurring: _isRecurring,
      );

      final success =
          await ref.read(createExpenseProvider.notifier).createExpense(dto);

      if (success && mounted) {
        ref.invalidate(expensesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gasto registrado exitosamente'),
            backgroundColor: GymGoColors.success,
          ),
        );
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al registrar el gasto'),
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
