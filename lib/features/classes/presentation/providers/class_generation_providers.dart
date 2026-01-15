import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/class_generation_repository.dart';
import '../../domain/class_generation.dart';

/// Repository provider for class generation
final classGenerationRepositoryProvider =
    Provider<ClassGenerationRepository>((ref) {
  return ClassGenerationRepository(Supabase.instance.client);
});

/// Selected generation period state
final selectedGenerationPeriodProvider =
    StateProvider<GenerationPeriod>((ref) => GenerationPeriod.week);

/// Preview generation notifier
class PreviewGenerationNotifier
    extends StateNotifier<AsyncValue<GenerationPreview>> {
  PreviewGenerationNotifier(this._repository)
      : super(const AsyncValue.data(GenerationPreview(
          templatePreviews: [],
          totalToGenerate: 0,
        )));

  final ClassGenerationRepository _repository;

  Future<void> loadPreview(GenerationPeriod period) async {
    state = const AsyncValue.loading();
    try {
      final preview = await _repository.previewGeneration(period: period);
      if (preview.error != null) {
        state = AsyncValue.error(preview.error!, StackTrace.current);
      } else {
        state = AsyncValue.data(preview);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.data(GenerationPreview(
      templatePreviews: [],
      totalToGenerate: 0,
    ));
  }
}

final previewGenerationProvider =
    StateNotifierProvider<PreviewGenerationNotifier, AsyncValue<GenerationPreview>>(
        (ref) {
  final repository = ref.watch(classGenerationRepositoryProvider);
  return PreviewGenerationNotifier(repository);
});

/// Generate classes notifier
class GenerateClassesNotifier
    extends StateNotifier<AsyncValue<GenerationResult?>> {
  GenerateClassesNotifier(this._repository)
      : super(const AsyncValue.data(null));

  final ClassGenerationRepository _repository;

  Future<GenerationResult?> generate(GenerationPeriod period) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.generateClasses(period: period);
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final generateClassesProvider =
    StateNotifierProvider<GenerateClassesNotifier, AsyncValue<GenerationResult?>>(
        (ref) {
  final repository = ref.watch(classGenerationRepositoryProvider);
  return GenerateClassesNotifier(repository);
});

/// Helper to reset all generation state
void resetGenerationState(WidgetRef ref) {
  ref.read(selectedGenerationPeriodProvider.notifier).state =
      GenerationPeriod.week;
  ref.read(previewGenerationProvider.notifier).reset();
  ref.read(generateClassesProvider.notifier).reset();
}
