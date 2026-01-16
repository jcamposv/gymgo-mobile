import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/components.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Help & Support screen
class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  static const String _supportEmail = 'contact@gymgo.io';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: GymGoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Ayuda y soporte'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header illustration
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: GymGoColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(GymGoSpacing.radiusXl),
                  ),
                  child: Icon(
                    LucideIcons.headphones,
                    color: GymGoColors.primary,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: GymGoSpacing.md),
              Center(
                child: Text(
                  '¿Cómo podemos ayudarte?',
                  style: GymGoTypography.headlineSmall,
                ),
              ),
              const SizedBox(height: GymGoSpacing.xs),
              Center(
                child: Text(
                  'Estamos aquí para resolver tus dudas',
                  style: GymGoTypography.bodyMedium.copyWith(
                    color: GymGoColors.textTertiary,
                  ),
                ),
              ),

              const SizedBox(height: GymGoSpacing.xl),

              // Help options
              GymGoCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _HelpItem(
                      icon: LucideIcons.bookOpen,
                      title: 'Centro de ayuda',
                      subtitle: 'Preguntas frecuentes y guías',
                      onTap: () => context.push(Routes.profileHelpCenter),
                      isFirst: true,
                    ),
                    const Divider(
                      height: 1,
                      indent: 56,
                      color: GymGoColors.cardBorder,
                    ),
                    _HelpItem(
                      icon: LucideIcons.mail,
                      title: 'Contactar soporte',
                      subtitle: _supportEmail,
                      onTap: () => _handleContactSupport(context, ref),
                      isLast: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: GymGoSpacing.xl),

              // Info text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: GymGoSpacing.sm),
                child: Text(
                  'Nuestro equipo de soporte está disponible de lunes a viernes de 9:00 a 18:00.',
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

  Future<void> _handleContactSupport(BuildContext context, WidgetRef ref) async {
    try {
      final user = ref.read(currentUserProvider);
      final userId = user?.id ?? 'No identificado';

      // Get app info
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      final platform = Platform.isIOS ? 'iOS' : 'Android';

      // Build email body
      final body = '''

---
Información del dispositivo (no borrar):
- User ID: $userId
- App Version: $appVersion
- Platform: $platform
''';

      // Encode email parameters
      final subject = Uri.encodeComponent('Soporte GymGo');
      final encodedBody = Uri.encodeComponent(body);

      final emailUri = Uri.parse(
        'mailto:$_supportEmail?subject=$subject&body=$encodedBody',
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'No se pudo abrir la aplicación de correo. '
                'Escríbenos a $_supportEmail',
              ),
              backgroundColor: GymGoColors.error,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(GymGoSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: GymGoColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(GymGoSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
            ),
          ),
        );
      }
    }
  }
}

class _HelpItem extends StatelessWidget {
  const _HelpItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst
            ? const Radius.circular(GymGoSpacing.radiusLg)
            : Radius.zero,
        bottom: isLast
            ? const Radius.circular(GymGoSpacing.radiusLg)
            : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(GymGoSpacing.md),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: GymGoColors.textSecondary,
            ),
            const SizedBox(width: GymGoSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GymGoTypography.bodyMedium,
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
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: GymGoColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
