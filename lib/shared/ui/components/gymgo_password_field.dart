import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/gymgo_colors.dart';
import '../../../core/theme/gymgo_spacing.dart';
import '../../../core/theme/gymgo_typography.dart';

/// GymGo password field with toggle visibility
class GymGoPasswordField extends StatefulWidget {
  const GymGoPasswordField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.enabled = true,
    this.autofocus = false,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.autovalidateMode,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final bool enabled;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;

  @override
  State<GymGoPasswordField> createState() => _GymGoPasswordFieldState();
}

class _GymGoPasswordFieldState extends State<GymGoPasswordField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: GymGoTypography.labelMedium.copyWith(
              color: hasError
                  ? GymGoColors.error
                  : _isFocused
                      ? GymGoColors.primary
                      : GymGoColors.textSecondary,
            ),
          ),
          const SizedBox(height: GymGoSpacing.xs),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: _obscureText,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          autovalidateMode: widget.autovalidateMode,
          style: GymGoTypography.inputText,
          cursorColor: GymGoColors.primary,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: const Icon(
              LucideIcons.lock,
              size: GymGoSpacing.iconMd,
              color: GymGoColors.textTertiary,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? LucideIcons.eyeOff : LucideIcons.eye,
                size: GymGoSpacing.iconMd,
                color: GymGoColors.textTertiary,
              ),
              onPressed: _toggleVisibility,
              splashRadius: 20,
            ),
            errorText: null,
            counterText: '',
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: GymGoSpacing.xs),
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                size: 14,
                color: GymGoColors.error,
              ),
              const SizedBox(width: GymGoSpacing.xxs),
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: GymGoTypography.inputError,
                ),
              ),
            ],
          ),
        ] else if (widget.helperText != null) ...[
          const SizedBox(height: GymGoSpacing.xs),
          Text(
            widget.helperText!,
            style: GymGoTypography.bodySmall.copyWith(
              color: GymGoColors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }
}
