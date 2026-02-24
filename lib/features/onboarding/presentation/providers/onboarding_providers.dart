import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../notifications/presentation/providers/inbox_providers.dart';

const _kOnboardingCompleted = 'onboarding_completed';

/// Whether the user has already completed the onboarding walkthrough.
final onboardingCompletedProvider = Provider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool(_kOnboardingCompleted) ?? false;
});

/// Marks onboarding as completed in SharedPreferences.
Future<void> completeOnboarding(WidgetRef ref) async {
  final prefs = ref.read(sharedPreferencesProvider);
  await prefs.setBool(_kOnboardingCompleted, true);
}
