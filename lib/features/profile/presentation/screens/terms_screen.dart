import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';

/// Terms and Conditions screen
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GymGoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Términos y Condiciones'),
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
              Text(
                'Última actualización: Enero 2025',
                style: GymGoTypography.bodySmall.copyWith(
                  color: GymGoColors.textTertiary,
                ),
              ),
              const SizedBox(height: GymGoSpacing.lg),

              _buildSection(
                title: '1. ¿Qué es GymGo?',
                content:
                    'GymGo es una aplicación que te permite gestionar tu membresía de gimnasio, '
                    'reservar clases, ver tu progreso físico y mantenerte conectado con tu gimnasio. '
                    'Nuestro objetivo es hacer tu experiencia en el gimnasio más fácil y organizada.',
              ),

              _buildSection(
                title: '2. Tu cuenta',
                content:
                    'Al crear una cuenta en GymGo, te comprometes a:\n'
                    '• Proporcionar información verdadera y actualizada\n'
                    '• Mantener segura tu contraseña\n'
                    '• No compartir tu cuenta con otras personas\n'
                    '• Notificarnos si detectas algún uso no autorizado de tu cuenta\n\n'
                    'Eres responsable de todas las actividades que ocurran en tu cuenta.',
              ),

              _buildSection(
                title: '3. Uso de tus datos',
                content:
                    'Recopilamos información básica para que la app funcione correctamente:\n'
                    '• Tu nombre y correo electrónico para identificarte\n'
                    '• Datos de tus entrenamientos para mostrarte tu progreso\n'
                    '• Información de pagos para gestionar tu membresía\n\n'
                    'No vendemos tus datos personales a terceros. Solo compartimos información '
                    'con tu gimnasio para que puedan brindarte un mejor servicio.',
              ),

              _buildSection(
                title: '4. Pagos y membresías',
                content:
                    'Los pagos de membresía se procesan a través de tu gimnasio. GymGo solo '
                    'muestra información de tus pagos pero no procesa transacciones directamente.\n\n'
                    'Cualquier disputa sobre pagos, reembolsos o cancelaciones debe resolverse '
                    'directamente con tu gimnasio. GymGo no es responsable de las políticas '
                    'de pago de cada gimnasio.',
              ),

              _buildSection(
                title: '5. Suspensión de cuenta',
                content:
                    'Podemos suspender o cancelar tu cuenta si:\n'
                    '• Violas estos términos de uso\n'
                    '• Usas la app de forma fraudulenta\n'
                    '• Tu gimnasio nos lo solicita\n'
                    '• La cuenta permanece inactiva por mucho tiempo\n\n'
                    'Si tu cuenta es suspendida, puedes contactarnos para más información.',
              ),

              _buildSection(
                title: '6. Cambios a estos términos',
                content:
                    'Podemos actualizar estos términos de vez en cuando. Cuando hagamos cambios '
                    'importantes, te notificaremos a través de la app o por correo electrónico.\n\n'
                    'Si continúas usando GymGo después de los cambios, significa que aceptas '
                    'los nuevos términos.',
              ),

              _buildSection(
                title: '7. Contacto',
                content:
                    'Si tienes preguntas sobre estos términos o sobre cómo usamos tus datos, '
                    'puedes escribirnos a:\n\n'
                    'contact@gymgo.io\n\n'
                    'Estaremos felices de ayudarte.',
              ),

              const SizedBox(height: GymGoSpacing.xl),

              // Footer
              Center(
                child: Text(
                  'Gracias por usar GymGo',
                  style: GymGoTypography.bodyMedium.copyWith(
                    color: GymGoColors.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              const SizedBox(height: GymGoSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: GymGoSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GymGoTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: GymGoColors.primary,
            ),
          ),
          const SizedBox(height: GymGoSpacing.sm),
          Text(
            content,
            style: GymGoTypography.bodyMedium.copyWith(
              color: GymGoColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
