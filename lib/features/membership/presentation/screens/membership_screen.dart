import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/membership_models.dart';
import '../providers/membership_providers.dart';
import '../widgets/membership_status_card.dart';
import '../widgets/plan_info_card.dart';

/// Main membership screen showing current status
class MembershipScreen extends ConsumerWidget {
  const MembershipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipAsync = ref.watch(membershipNotifierProvider);
    final gymContactAsync = ref.watch(gymContactInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Membresía'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial de pagos',
            onPressed: () => context.push('/membership/payments'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(membershipNotifierProvider);
          ref.invalidate(gymContactInfoProvider);
        },
        child: membershipAsync.when(
          data: (membership) {
            if (membership == null) {
              return _buildNoMembershipView(context);
            }
            return _buildMembershipContent(
              context,
              ref,
              membership,
              gymContactAsync,
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => _buildErrorView(context, ref, error),
        ),
      ),
    );
  }

  Widget _buildMembershipContent(
    BuildContext context,
    WidgetRef ref,
    MembershipInfo membership,
    AsyncValue<Map<String, String?>> gymContactAsync,
  ) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status card
        MembershipStatusCard(membership: membership),

        const SizedBox(height: 16),

        // Plan info card
        if (membership.planName != null) ...[
          PlanInfoCard(membership: membership),
          const SizedBox(height: 16),
        ],

        // Actions section
        if (membership.status == MembershipStatus.expired ||
            membership.status == MembershipStatus.expiringSoon) ...[
          _buildRenewalSection(context, gymContactAsync),
          const SizedBox(height: 16),
        ],

        // Payment history link
        Card(
          child: ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Historial de Pagos'),
            subtitle: const Text('Ver todos tus pagos anteriores'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/membership/payments'),
          ),
        ),

        const SizedBox(height: 16),

        // Contact section
        gymContactAsync.when(
          data: (contact) => _buildContactSection(context, contact),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildRenewalSection(
    BuildContext context,
    AsyncValue<Map<String, String?>> gymContactAsync,
  ) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.autorenew,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Renovar Membresía',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Contacta al gimnasio para renovar tu membresía y seguir disfrutando de todos los beneficios.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            gymContactAsync.when(
              data: (contact) => _buildContactButtons(context, contact),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error al cargar contacto'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButtons(
    BuildContext context,
    Map<String, String?> contact,
  ) {
    final buttons = <Widget>[];

    if (contact['whatsapp'] != null) {
      buttons.add(
        ElevatedButton.icon(
          icon: const Icon(Icons.chat),
          label: const Text('WhatsApp'),
          onPressed: () => _launchWhatsApp(contact['whatsapp']!),
        ),
      );
    }

    if (contact['phone'] != null) {
      buttons.add(
        OutlinedButton.icon(
          icon: const Icon(Icons.phone),
          label: const Text('Llamar'),
          onPressed: () => _launchPhone(contact['phone']!),
        ),
      );
    }

    if (buttons.isEmpty) {
      return const Text('Contacta al gimnasio directamente.');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: buttons,
    );
  }

  Widget _buildContactSection(
    BuildContext context,
    Map<String, String?> contact,
  ) {
    if (contact.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Necesitas ayuda?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (contact['name'] != null)
              Text(
                contact['name']!,
                style: theme.textTheme.bodyLarge,
              ),
            const SizedBox(height: 8),
            if (contact['email'] != null)
              _buildContactRow(
                Icons.email_outlined,
                contact['email']!,
                () => _launchEmail(contact['email']!),
              ),
            if (contact['phone'] != null)
              _buildContactRow(
                Icons.phone_outlined,
                contact['phone']!,
                () => _launchPhone(contact['phone']!),
              ),
            if (contact['whatsapp'] != null)
              _buildContactRow(
                Icons.chat_outlined,
                'WhatsApp',
                () => _launchWhatsApp(contact['whatsapp']!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(text),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMembershipView(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_membership_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin información de membresía',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'No se encontró información de tu membresía. Contacta al gimnasio para más información.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, WidgetRef ref, Object error) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(membershipNotifierProvider),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
