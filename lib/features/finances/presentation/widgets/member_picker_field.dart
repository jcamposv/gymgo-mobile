import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../domain/finance_models.dart';
import 'member_list_tile.dart';
import 'member_picker_sheet.dart';

/// A form field for selecting a member
/// Shows empty state or selected member chip, and opens picker on tap
class MemberPickerField extends StatelessWidget {
  const MemberPickerField({
    super.key,
    required this.selectedMember,
    required this.onMemberSelected,
    this.label = 'Miembro',
    this.isRequired = true,
    this.errorText,
  });

  final PaymentMember? selectedMember;
  final ValueChanged<PaymentMember?> onMemberSelected;
  final String label;
  final bool isRequired;
  final String? errorText;

  Future<void> _openPicker(BuildContext context) async {
    final member = await MemberPickerSheet.show(
      context,
      selectedMember: selectedMember,
    );
    if (member != null) {
      onMemberSelected(member);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Text(
              label,
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
        ),
        const SizedBox(height: GymGoSpacing.xs),

        // Field content
        if (selectedMember != null)
          MemberChip(
            member: selectedMember!,
            onTap: () => _openPicker(context),
          )
        else
          _EmptyMemberField(
            onTap: () => _openPicker(context),
            hasError: hasError,
          ),

        // Error text
        if (hasError) ...[
          const SizedBox(height: GymGoSpacing.xs),
          Row(
            children: [
              Icon(
                LucideIcons.alertCircle,
                size: 12,
                color: GymGoColors.error,
              ),
              const SizedBox(width: 4),
              Text(
                errorText!,
                style: GymGoTypography.labelSmall.copyWith(
                  color: GymGoColors.error,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Empty state for member field
class _EmptyMemberField extends StatelessWidget {
  const _EmptyMemberField({
    required this.onTap,
    required this.hasError,
  });

  final VoidCallback onTap;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
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
          border: Border.all(
            color: hasError ? GymGoColors.error : GymGoColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            // User icon placeholder
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: GymGoColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.userPlus,
                size: 18,
                color: GymGoColors.primary,
              ),
            ),
            const SizedBox(width: GymGoSpacing.md),

            // Placeholder text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seleccionar miembro',
                    style: GymGoTypography.bodyMedium.copyWith(
                      color: GymGoColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Toca para buscar',
                    style: GymGoTypography.labelSmall.copyWith(
                      color: GymGoColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow indicator
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
}

/// Form field wrapper that integrates with Flutter form validation
class MemberPickerFormField extends FormField<PaymentMember> {
  MemberPickerFormField({
    super.key,
    PaymentMember? initialValue,
    FormFieldSetter<PaymentMember>? onSaved,
    FormFieldValidator<PaymentMember>? validator,
    bool enabled = true,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
    String label = 'Miembro',
    bool isRequired = true,
  }) : super(
          initialValue: initialValue,
          onSaved: onSaved,
          validator: validator,
          enabled: enabled,
          autovalidateMode: autovalidateMode,
          builder: (FormFieldState<PaymentMember> state) {
            return MemberPickerField(
              selectedMember: state.value,
              onMemberSelected: (member) {
                state.didChange(member);
              },
              label: label,
              isRequired: isRequired,
              errorText: state.errorText,
            );
          },
        );
}
