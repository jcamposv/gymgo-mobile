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
import '../widgets/member_picker_field.dart';

/// Screen for creating a new payment
class CreatePaymentScreen extends ConsumerStatefulWidget {
  const CreatePaymentScreen({super.key});

  @override
  ConsumerState<CreatePaymentScreen> createState() => _CreatePaymentScreenState();
}

class _CreatePaymentScreenState extends ConsumerState<CreatePaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _referenceController = TextEditingController();

  PaymentMember? _selectedMember;
  String? _selectedPlanId;
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;
  String? _memberError;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(paymentPlansProvider);
    final createState = ref.watch(createPaymentProvider);

    return Scaffold(
      backgroundColor: GymGoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Nuevo Pago'),
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
            // Member selection with searchable picker
            MemberPickerField(
              selectedMember: _selectedMember,
              onMemberSelected: (member) {
                setState(() {
                  _selectedMember = member;
                  _memberError = null;
                });
              },
              label: 'Miembro',
              isRequired: true,
              errorText: _memberError,
            ),

            const SizedBox(height: GymGoSpacing.md),

            // Plan selection (optional)
            Text(
              'Plan de Membresía (opcional)',
              style: GymGoTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: GymGoSpacing.xs),
            plansAsync.when(
              loading: () => Container(
                padding: const EdgeInsets.all(GymGoSpacing.md),
                decoration: BoxDecoration(
                  color: GymGoColors.surface,
                  borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                  border: Border.all(color: GymGoColors.cardBorder),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: GymGoColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
              error: (_, __) => Container(
                padding: const EdgeInsets.all(GymGoSpacing.md),
                decoration: BoxDecoration(
                  color: GymGoColors.surface,
                  borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                  border: Border.all(color: GymGoColors.error),
                ),
                child: Text(
                  'Error al cargar planes',
                  style: GymGoTypography.bodyMedium.copyWith(
                    color: GymGoColors.error,
                  ),
                ),
              ),
              data: (plans) => _buildPlanDropdown(plans),
            ),

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

            // Payment method
            Text(
              'Método de Pago *',
              style: GymGoTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: GymGoSpacing.xs),
            _buildPaymentMethodSelector(),

            const SizedBox(height: GymGoSpacing.md),

            // Payment date
            Text(
              'Fecha de Pago *',
              style: GymGoTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: GymGoSpacing.xs),
            _buildDateSelector(),

            const SizedBox(height: GymGoSpacing.md),

            // Reference number
            Text(
              'Número de Referencia',
              style: GymGoTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: GymGoSpacing.xs),
            TextFormField(
              controller: _referenceController,
              decoration: InputDecoration(
                hintText: 'Ej: TRF-12345',
                prefixIcon: const Icon(LucideIcons.hash),
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
                    : _submitPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GymGoColors.primary,
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
                        'Registrar Pago',
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

  Widget _buildPlanDropdown(List<PaymentPlan> plans) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return DropdownButtonFormField<String>(
      value: _selectedPlanId,
      decoration: InputDecoration(
        hintText: 'Selecciona un plan (opcional)',
        prefixIcon: const Icon(LucideIcons.creditCard),
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
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Sin plan'),
        ),
        ...plans.map((plan) {
          return DropdownMenuItem(
            value: plan.id,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  currencyFormat.format(plan.price),
                  style: GymGoTypography.labelSmall.copyWith(
                    color: GymGoColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          _selectedPlanId = value;
          // Auto-fill amount if plan is selected
          if (value != null) {
            final plan = plans.firstWhere((p) => p.id == value);
            _amountController.text = plan.price.toStringAsFixed(2);
          }
        });
      },
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Wrap(
      spacing: GymGoSpacing.sm,
      runSpacing: GymGoSpacing.sm,
      children: PaymentMethod.values.map((method) {
        final isSelected = _selectedMethod == method;
        return InkWell(
          onTap: () {
            setState(() {
              _selectedMethod = method;
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
                  ? GymGoColors.primary.withValues(alpha: 0.1)
                  : GymGoColors.surface,
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
              border: Border.all(
                color: isSelected ? GymGoColors.primary : GymGoColors.cardBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getMethodIcon(method),
                  size: 18,
                  color: isSelected
                      ? GymGoColors.primary
                      : GymGoColors.textSecondary,
                ),
                const SizedBox(width: GymGoSpacing.xs),
                Text(
                  method.label,
                  style: GymGoTypography.labelMedium.copyWith(
                    color: isSelected
                        ? GymGoColors.primary
                        : GymGoColors.textPrimary,
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

  IconData _getMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return LucideIcons.banknote;
      case PaymentMethod.card:
        return LucideIcons.creditCard;
      case PaymentMethod.transfer:
        return LucideIcons.arrowLeftRight;
      case PaymentMethod.other:
        return LucideIcons.wallet;
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

  Future<void> _submitPayment() async {
    // Validate member selection
    if (_selectedMember == null) {
      setState(() {
        _memberError = 'Selecciona un miembro';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final dto = CreatePaymentDto(
        memberId: _selectedMember!.id,
        planId: _selectedPlanId,
        amount: double.parse(_amountController.text),
        paymentMethod: _selectedMethod,
        paymentDate: _selectedDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        referenceNumber: _referenceController.text.isEmpty
            ? null
            : _referenceController.text,
      );

      final success =
          await ref.read(createPaymentProvider.notifier).createPayment(dto);

      if (success && mounted) {
        ref.invalidate(paymentsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pago registrado exitosamente'),
            backgroundColor: GymGoColors.success,
          ),
        );
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al registrar el pago'),
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
