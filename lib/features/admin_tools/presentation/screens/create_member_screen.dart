import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/providers/location_providers.dart';
import '../../../../shared/ui/components/components.dart';
import '../../../membership/domain/membership_models.dart';
import '../../data/members_repository.dart';
import '../../domain/member.dart';
import '../providers/members_providers.dart';

/// Screen for creating new members (Admin/Assistant)
/// Matches web behavior: /dashboard/members/new
class CreateMemberScreen extends ConsumerStatefulWidget {
  const CreateMemberScreen({super.key});

  @override
  ConsumerState<CreateMemberScreen> createState() => _CreateMemberScreenState();
}

class _CreateMemberScreenState extends ConsumerState<CreateMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  MembershipPlan? _selectedPlan;
  DateTime _membershipStartDate = DateTime.now();
  DateTime? _membershipEndDate;
  MemberStatus _status = MemberStatus.active;
  ExperienceLevel _experienceLevel = ExperienceLevel.beginner;
  bool _isLoading = false;

  final _dateFormat = DateFormat('d MMM yyyy', 'es');

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _updateEndDateFromPlan() {
    if (_selectedPlan?.durationDays != null) {
      setState(() {
        _membershipEndDate = _membershipStartDate.add(
          Duration(days: _selectedPlan!.durationDays!),
        );
      });
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _membershipStartDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
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
        _membershipStartDate = date;
      });
      _updateEndDateFromPlan();
    }
  }

  Future<void> _createMember() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPlan == null) {
      GymGoToast.error(context, 'Selecciona un plan de membresía');
      return;
    }

    // Get active location
    final activeLocation = await ref.read(adminActiveLocationProvider.future);
    if (activeLocation == null) {
      GymGoToast.error(context, 'No hay una sede activa seleccionada');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final data = CreateMemberData(
        email: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        locationId: activeLocation.id,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        currentPlanId: _selectedPlan!.id,
        membershipStartDate: _membershipStartDate,
        membershipEndDate: _membershipEndDate,
        experienceLevel: _experienceLevel,
        status: _status,
      );

      final member = await ref.read(createMemberProvider.notifier).createMember(data);

      if (member != null && mounted) {
        GymGoToast.success(context, 'Miembro creado exitosamente');
        // Refresh members list
        refreshMembers(ref);
        context.pop();
      } else if (mounted) {
        final state = ref.read(createMemberProvider);
        final error = state.error;

        String errorMessage = 'Error al crear miembro';
        if (error is CreateMemberException) {
          errorMessage = error.message;
          if (error.isPlanLimitExceeded) {
            _showPlanLimitDialog(error.message);
            return;
          }
        } else if (error != null) {
          errorMessage = error.toString();
        }

        GymGoToast.error(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPlanLimitDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GymGoColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusLg),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(GymGoSpacing.sm),
              decoration: BoxDecoration(
                color: GymGoColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.alertTriangle,
                color: GymGoColors.warning,
                size: 24,
              ),
            ),
            const SizedBox(width: GymGoSpacing.sm),
            Text(
              'Límite alcanzado',
              style: GymGoTypography.headlineSmall,
            ),
          ],
        ),
        content: Text(
          message,
          style: GymGoTypography.bodyMedium.copyWith(
            color: GymGoColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Entendido',
              style: GymGoTypography.labelMedium.copyWith(
                color: GymGoColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPlanPicker() {
    final plansAsync = ref.read(availablePlansProvider);

    plansAsync.when(
      data: (plans) {
        if (plans.isEmpty) {
          GymGoToast.info(context, 'No hay planes disponibles');
          return;
        }

        showModalBottomSheet(
          context: context,
          backgroundColor: GymGoColors.background,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(GymGoSpacing.radiusLg),
            ),
          ),
          isScrollControlled: true,
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.8,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                // Handle
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
                // Title
                Padding(
                  padding: const EdgeInsets.all(GymGoSpacing.md),
                  child: Text(
                    'Seleccionar plan',
                    style: GymGoTypography.headlineSmall,
                  ),
                ),
                const Divider(color: GymGoColors.cardBorder),
                // Plans list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: GymGoSpacing.lg),
                    itemCount: plans.length,
                    itemBuilder: (context, index) {
                      final plan = plans[index];
                      final isSelected = plan.id == _selectedPlan?.id;

                      return ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? GymGoColors.primary.withValues(alpha: 0.1)
                                : GymGoColors.surface,
                            borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                          ),
                          child: Icon(
                            LucideIcons.creditCard,
                            color: isSelected
                                ? GymGoColors.primary
                                : GymGoColors.textSecondary,
                          ),
                        ),
                        title: Text(
                          plan.name,
                          style: GymGoTypography.bodyMedium.copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : null,
                            color: isSelected ? GymGoColors.primary : null,
                          ),
                        ),
                        subtitle: Text(
                          '\$${plan.price.toStringAsFixed(0)} ${plan.currency}${plan.durationDays != null ? ' • ${plan.durationDays} días' : ''}',
                          style: GymGoTypography.labelSmall.copyWith(
                            color: GymGoColors.textTertiary,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(LucideIcons.check, color: GymGoColors.primary)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedPlan = plan;
                          });
                          _updateEndDateFromPlan();
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () {
        GymGoToast.info(context, 'Cargando planes...');
      },
      error: (e, _) {
        GymGoToast.error(context, 'Error al cargar planes');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(availablePlansProvider);
    final memberLimitAsync = ref.watch(memberLimitProvider);

    return Scaffold(
      backgroundColor: GymGoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Nuevo Miembro'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Member limit indicator
            memberLimitAsync.when(
              data: (limit) {
                if (limit.limit == -1) return const SizedBox.shrink();
                return _buildLimitIndicator(limit);
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section: Basic Info
                      _buildSectionHeader('Información básica'),
                      const SizedBox(height: GymGoSpacing.md),

                      // Full Name
                      _buildLabel('Nombre completo', required: true),
                      const SizedBox(height: GymGoSpacing.xs),
                      TextFormField(
                        controller: _fullNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDecoration(
                          hintText: 'Nombre del miembro',
                          prefixIcon: LucideIcons.user,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es obligatorio';
                          }
                          if (value.trim().length < 2) {
                            return 'El nombre debe tener al menos 2 caracteres';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: GymGoSpacing.md),

                      // Email
                      _buildLabel('Correo electrónico', required: true),
                      const SizedBox(height: GymGoSpacing.xs),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: _inputDecoration(
                          hintText: 'correo@ejemplo.com',
                          prefixIcon: LucideIcons.mail,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El correo es obligatorio';
                          }
                          final emailRegex = RegExp(
                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                          );
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Ingresa un correo válido';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: GymGoSpacing.md),

                      // Phone (optional)
                      _buildLabel('Teléfono', required: false),
                      const SizedBox(height: GymGoSpacing.xs),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration(
                          hintText: '+52 555 123 4567',
                          prefixIcon: LucideIcons.phone,
                        ),
                      ),

                      const SizedBox(height: GymGoSpacing.xl),

                      // Section: Membership
                      _buildSectionHeader('Membresía'),
                      const SizedBox(height: GymGoSpacing.md),

                      // Plan selection
                      _buildLabel('Plan', required: true),
                      const SizedBox(height: GymGoSpacing.xs),
                      _buildPlanPicker(plansAsync),

                      const SizedBox(height: GymGoSpacing.md),

                      // Start date
                      _buildLabel('Fecha de inicio', required: true),
                      const SizedBox(height: GymGoSpacing.xs),
                      _buildDatePicker(),

                      if (_membershipEndDate != null) ...[
                        const SizedBox(height: GymGoSpacing.md),
                        _buildInfoRow(
                          icon: LucideIcons.calendarCheck,
                          label: 'Fecha de vencimiento',
                          value: _dateFormat.format(_membershipEndDate!),
                        ),
                      ],

                      const SizedBox(height: GymGoSpacing.xl),

                      // Section: Additional Info (collapsed by default)
                      _buildSectionHeader('Información adicional'),
                      const SizedBox(height: GymGoSpacing.md),

                      // Experience Level
                      _buildLabel('Nivel de experiencia'),
                      const SizedBox(height: GymGoSpacing.xs),
                      _buildExperiencePicker(),

                      const SizedBox(height: GymGoSpacing.md),

                      // Status
                      _buildLabel('Estado'),
                      const SizedBox(height: GymGoSpacing.xs),
                      _buildStatusPicker(),

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

  Widget _buildLimitIndicator(MemberLimitResult limit) {
    final percentage = limit.limit > 0 ? (limit.current / limit.limit) : 0.0;
    final isNearLimit = percentage >= 0.8;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.screenHorizontal,
        vertical: GymGoSpacing.sm,
      ),
      padding: const EdgeInsets.all(GymGoSpacing.sm),
      decoration: BoxDecoration(
        color: isNearLimit
            ? GymGoColors.warning.withValues(alpha: 0.1)
            : GymGoColors.surface,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        border: Border.all(
          color: isNearLimit ? GymGoColors.warning : GymGoColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isNearLimit ? LucideIcons.alertTriangle : LucideIcons.users,
            size: 16,
            color: isNearLimit ? GymGoColors.warning : GymGoColors.textSecondary,
          ),
          const SizedBox(width: GymGoSpacing.sm),
          Expanded(
            child: Text(
              'Miembros: ${limit.current}/${limit.limit}',
              style: GymGoTypography.labelSmall.copyWith(
                color: isNearLimit ? GymGoColors.warning : GymGoColors.textSecondary,
              ),
            ),
          ),
          if (isNearLimit)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: GymGoSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: GymGoColors.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
              ),
              child: Text(
                'Casi lleno',
                style: GymGoTypography.labelSmall.copyWith(
                  color: GymGoColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GymGoTypography.labelMedium.copyWith(
        color: GymGoColors.textTertiary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildLabel(String label, {bool required = false}) {
    return Row(
      children: [
        Text(
          label,
          style: GymGoTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        if (required)
          Text(
            ' *',
            style: GymGoTypography.labelMedium.copyWith(
              color: GymGoColors.error,
            ),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GymGoTypography.bodyMedium.copyWith(
        color: GymGoColors.textTertiary,
      ),
      prefixIcon: Icon(prefixIcon, size: 20, color: GymGoColors.textSecondary),
      filled: true,
      fillColor: GymGoColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        borderSide: const BorderSide(color: GymGoColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        borderSide: const BorderSide(color: GymGoColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        borderSide: const BorderSide(color: GymGoColors.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        borderSide: const BorderSide(color: GymGoColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        borderSide: const BorderSide(color: GymGoColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.md,
        vertical: GymGoSpacing.md,
      ),
    );
  }

  Widget _buildPlanPicker(AsyncValue<List<MembershipPlan>> plansAsync) {
    return InkWell(
      onTap: plansAsync.hasValue ? _showPlanPicker : null,
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
                color: _selectedPlan != null
                    ? GymGoColors.primary.withValues(alpha: 0.1)
                    : GymGoColors.cardBorder,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.creditCard,
                size: 18,
                color: _selectedPlan != null
                    ? GymGoColors.primary
                    : GymGoColors.textSecondary,
              ),
            ),
            const SizedBox(width: GymGoSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedPlan?.name ?? 'Seleccionar plan',
                    style: GymGoTypography.bodyMedium.copyWith(
                      color: _selectedPlan != null
                          ? null
                          : GymGoColors.textSecondary,
                    ),
                  ),
                  if (_selectedPlan != null)
                    Text(
                      '\$${_selectedPlan!.price.toStringAsFixed(0)} ${_selectedPlan!.currency}',
                      style: GymGoTypography.labelSmall.copyWith(
                        color: GymGoColors.textTertiary,
                      ),
                    )
                  else
                    Text(
                      'Membresía del miembro',
                      style: GymGoTypography.labelSmall.copyWith(
                        color: GymGoColors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
            plansAsync.when(
              data: (_) => const Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: GymGoColors.textTertiary,
              ),
              loading: () => const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => const Icon(
                LucideIcons.alertCircle,
                size: 18,
                color: GymGoColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _selectStartDate,
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
            const Icon(
              LucideIcons.calendar,
              size: 20,
              color: GymGoColors.textSecondary,
            ),
            const SizedBox(width: GymGoSpacing.md),
            Expanded(
              child: Text(
                _dateFormat.format(_membershipStartDate),
                style: GymGoTypography.bodyMedium,
              ),
            ),
            const Icon(
              LucideIcons.chevronDown,
              size: 16,
              color: GymGoColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(GymGoSpacing.md),
      decoration: BoxDecoration(
        color: GymGoColors.surface,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        border: Border.all(color: GymGoColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: GymGoColors.textSecondary),
          const SizedBox(width: GymGoSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GymGoTypography.labelSmall.copyWith(
                  color: GymGoColors.textTertiary,
                ),
              ),
              Text(value, style: GymGoTypography.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExperiencePicker() {
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
        children: ExperienceLevel.values.map((level) {
          final isSelected = level == _experienceLevel;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _experienceLevel = level;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: GymGoSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? GymGoColors.primary.withValues(alpha: 0.1)
                      : null,
                  borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
                ),
                child: Text(
                  _experienceLevelLabel(level),
                  textAlign: TextAlign.center,
                  style: GymGoTypography.labelSmall.copyWith(
                    color: isSelected
                        ? GymGoColors.primary
                        : GymGoColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _experienceLevelLabel(ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.beginner:
        return 'Principiante';
      case ExperienceLevel.intermediate:
        return 'Intermedio';
      case ExperienceLevel.advanced:
        return 'Avanzado';
    }
  }

  Widget _buildStatusPicker() {
    final statuses = [MemberStatus.active, MemberStatus.inactive];

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
        children: statuses.map((status) {
          final isSelected = status == _status;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _status = status;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: GymGoSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _statusColor(status).withValues(alpha: 0.1)
                      : null,
                  borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
                ),
                child: Text(
                  _statusLabel(status),
                  textAlign: TextAlign.center,
                  style: GymGoTypography.labelSmall.copyWith(
                    color: isSelected
                        ? _statusColor(status)
                        : GymGoColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _statusLabel(MemberStatus status) {
    switch (status) {
      case MemberStatus.active:
        return 'Activo';
      case MemberStatus.inactive:
        return 'Inactivo';
      case MemberStatus.suspended:
        return 'Suspendido';
      case MemberStatus.cancelled:
        return 'Cancelado';
    }
  }

  Color _statusColor(MemberStatus status) {
    switch (status) {
      case MemberStatus.active:
        return GymGoColors.success;
      case MemberStatus.inactive:
        return GymGoColors.warning;
      case MemberStatus.suspended:
        return GymGoColors.error;
      case MemberStatus.cancelled:
        return GymGoColors.textTertiary;
    }
  }

  Widget _buildBottomButton() {
    final canSubmit = _fullNameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _selectedPlan != null &&
        !_isLoading;

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
            onPressed: canSubmit ? _createMember : null,
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
                    'Crear Miembro',
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
