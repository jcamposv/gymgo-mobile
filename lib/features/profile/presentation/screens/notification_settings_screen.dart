import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/components.dart';

/// Keys for notification preferences storage
class _PrefKeys {
  static const String classNotifications = 'pref_class_notifications';
  static const String reminderNotifications = 'pref_reminder_notifications';
}

/// Notification settings screen
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _classNotifications = true;
  bool _reminderNotifications = true;
  bool _isLoading = true;
  bool _osPermissionGranted = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _checkOsPermission();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _classNotifications = prefs.getBool(_PrefKeys.classNotifications) ?? true;
      _reminderNotifications =
          prefs.getBool(_PrefKeys.reminderNotifications) ?? true;
      _isLoading = false;
    });
  }

  Future<void> _checkOsPermission() async {
    final status = await Permission.notification.status;
    setState(() {
      _osPermissionGranted = status.isGranted;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GymGoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Notificaciones'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: GymGoLoadingSpinner(size: 32),
              )
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.all(GymGoSpacing.screenHorizontal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // OS permission warning
                    if (!_osPermissionGranted) ...[
                      _buildPermissionWarning(),
                      const SizedBox(height: GymGoSpacing.lg),
                    ],

                    // Notification toggles
                    GymGoCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildToggleItem(
                            icon: LucideIcons.calendarPlus,
                            title: 'Notificaciones de clases nuevas',
                            subtitle:
                                'Recibe avisos cuando se publiquen nuevas clases',
                            value: _classNotifications,
                            onChanged: _osPermissionGranted
                                ? (value) {
                                    setState(
                                        () => _classNotifications = value);
                                    _savePreference(
                                        _PrefKeys.classNotifications, value);
                                  }
                                : null,
                            isFirst: true,
                          ),
                          const Divider(
                            height: 1,
                            indent: 56,
                            color: GymGoColors.cardBorder,
                          ),
                          _buildToggleItem(
                            icon: LucideIcons.bellRing,
                            title: 'Recordatorios',
                            subtitle:
                                'Recordatorios de pagos y clases programadas',
                            value: _reminderNotifications,
                            onChanged: _osPermissionGranted
                                ? (value) {
                                    setState(
                                        () => _reminderNotifications = value);
                                    _savePreference(
                                        _PrefKeys.reminderNotifications,
                                        value);
                                  }
                                : null,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: GymGoSpacing.xl),

                    // Info text
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: GymGoSpacing.sm),
                      child: Text(
                        'Las notificaciones te ayudan a mantenerte al tanto de las novedades de tu gimnasio.',
                        style: GymGoTypography.bodySmall.copyWith(
                          color: GymGoColors.textTertiary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPermissionWarning() {
    return Container(
      padding: const EdgeInsets.all(GymGoSpacing.md),
      decoration: BoxDecoration(
        color: GymGoColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        border: Border.all(
          color: GymGoColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.alertTriangle,
                color: GymGoColors.warning,
                size: 20,
              ),
              const SizedBox(width: GymGoSpacing.sm),
              Expanded(
                child: Text(
                  'Notificaciones desactivadas',
                  style: GymGoTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: GymGoColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: GymGoSpacing.sm),
          Text(
            'Las notificaciones están desactivadas en la configuración de tu dispositivo.',
            style: GymGoTypography.bodySmall.copyWith(
              color: GymGoColors.textSecondary,
            ),
          ),
          const SizedBox(height: GymGoSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openAppSettings,
              icon: const Icon(LucideIcons.settings, size: 16),
              label: const Text('Abrir configuración'),
              style: OutlinedButton.styleFrom(
                foregroundColor: GymGoColors.warning,
                side: BorderSide(
                  color: GymGoColors.warning.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final enabled = onChanged != null;

    return InkWell(
      onTap: enabled ? () => onChanged(!value) : null,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(GymGoSpacing.radiusLg) : Radius.zero,
        bottom: isLast ? const Radius.circular(GymGoSpacing.radiusLg) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(GymGoSpacing.md),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: enabled
                  ? GymGoColors.textSecondary
                  : GymGoColors.textTertiary,
            ),
            const SizedBox(width: GymGoSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GymGoTypography.bodyMedium.copyWith(
                      color: enabled
                          ? GymGoColors.textPrimary
                          : GymGoColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GymGoTypography.bodySmall.copyWith(
                      color: GymGoColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: GymGoSpacing.sm),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: GymGoColors.primary.withValues(alpha: 0.3),
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return GymGoColors.primary;
                }
                return GymGoColors.textTertiary;
              }),
              trackColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return GymGoColors.primary.withValues(alpha: 0.3);
                }
                return GymGoColors.cardBorder;
              }),
            ),
          ],
        ),
      ),
    );
  }
}
