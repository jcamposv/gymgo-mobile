import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/branding_repository.dart';
import '../domain/gym_branding.dart';

/// Repository provider
final brandingRepositoryProvider = Provider<BrandingRepository>((ref) {
  return BrandingRepository(Supabase.instance.client);
});

/// Gym branding provider - fetches and caches branding info
final gymBrandingProvider = FutureProvider<GymBranding>((ref) async {
  final repository = ref.watch(brandingRepositoryProvider);
  return repository.getGymBranding();
});

/// Helper provider to get gym name
final gymNameProvider = Provider<String>((ref) {
  final branding = ref.watch(gymBrandingProvider);
  return branding.whenOrNull(data: (b) => b.gymName) ?? 'GymGo';
});

/// Helper provider to check if custom logo exists
final hasCustomLogoProvider = Provider<bool>((ref) {
  final branding = ref.watch(gymBrandingProvider);
  return branding.whenOrNull(data: (b) => b.hasCustomLogo) ?? false;
});

/// Helper provider to get logo URL
final logoUrlProvider = Provider<String?>((ref) {
  final branding = ref.watch(gymBrandingProvider);
  return branding.whenOrNull(data: (b) => b.logoUrl);
});
