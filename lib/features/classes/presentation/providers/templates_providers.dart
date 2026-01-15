import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/templates_repository.dart';
import '../../domain/class_template.dart';

/// Repository provider for templates
final templatesRepositoryProvider = Provider<TemplatesRepository>((ref) {
  return TemplatesRepository(Supabase.instance.client);
});

// =============================================================================
// TEMPLATES PROVIDERS
// =============================================================================

/// Search query for templates
final templateSearchQueryProvider = StateProvider<String>((ref) => '');

/// Day filter for templates
final templateDayFilterProvider = StateProvider<int?>((ref) => null);

/// Class type filter for templates
final templateTypeFilterProvider = StateProvider<String?>((ref) => null);

/// Templates list provider
final templatesProvider = FutureProvider<List<ClassTemplate>>((ref) async {
  final repository = ref.watch(templatesRepositoryProvider);
  final searchQuery = ref.watch(templateSearchQueryProvider);
  final dayFilter = ref.watch(templateDayFilterProvider);
  final typeFilter = ref.watch(templateTypeFilterProvider);

  return repository.getTemplates(
    searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
    dayOfWeek: dayFilter,
    classType: typeFilter,
  );
});

/// Single template provider
final templateByIdProvider =
    FutureProvider.family<ClassTemplate?, String>((ref, templateId) async {
  final repository = ref.watch(templatesRepositoryProvider);
  return repository.getTemplateById(templateId);
});

/// Update template notifier
class UpdateTemplateNotifier extends StateNotifier<AsyncValue<ClassTemplate?>> {
  UpdateTemplateNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  final TemplatesRepository _repository;
  final Ref _ref;

  Future<bool> updateTemplate(String templateId, UpdateTemplateDto dto) async {
    state = const AsyncValue.loading();
    try {
      final template = await _repository.updateTemplate(templateId, dto);
      state = AsyncValue.data(template);
      // Invalidate templates list
      _ref.invalidate(templatesProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final updateTemplateProvider =
    StateNotifierProvider<UpdateTemplateNotifier, AsyncValue<ClassTemplate?>>(
        (ref) {
  final repository = ref.watch(templatesRepositoryProvider);
  return UpdateTemplateNotifier(repository, ref);
});

/// Create template notifier
class CreateTemplateNotifier extends StateNotifier<AsyncValue<ClassTemplate?>> {
  CreateTemplateNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  final TemplatesRepository _repository;
  final Ref _ref;

  Future<ClassTemplate?> createTemplate(CreateTemplateDto dto) async {
    state = const AsyncValue.loading();
    try {
      final template = await _repository.createTemplate(dto);
      state = AsyncValue.data(template);
      // Invalidate templates list
      _ref.invalidate(templatesProvider);
      return template;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final createTemplateProvider =
    StateNotifierProvider<CreateTemplateNotifier, AsyncValue<ClassTemplate?>>(
        (ref) {
  final repository = ref.watch(templatesRepositoryProvider);
  return CreateTemplateNotifier(repository, ref);
});

/// Delete template notifier
class DeleteTemplateNotifier extends StateNotifier<AsyncValue<void>> {
  DeleteTemplateNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  final TemplatesRepository _repository;
  final Ref _ref;

  Future<bool> deleteTemplate(String templateId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteTemplate(templateId);
      state = const AsyncValue.data(null);
      // Invalidate templates list
      _ref.invalidate(templatesProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final deleteTemplateProvider =
    StateNotifierProvider<DeleteTemplateNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(templatesRepositoryProvider);
  return DeleteTemplateNotifier(repository, ref);
});

/// Toggle template status notifier
class ToggleTemplateStatusNotifier
    extends StateNotifier<AsyncValue<ClassTemplate?>> {
  ToggleTemplateStatusNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  final TemplatesRepository _repository;
  final Ref _ref;

  Future<bool> toggle(String templateId, {required bool isActive}) async {
    state = const AsyncValue.loading();
    try {
      final template = await _repository.toggleTemplateStatus(
        templateId,
        isActive: isActive,
      );
      state = AsyncValue.data(template);
      // Invalidate templates list
      _ref.invalidate(templatesProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final toggleTemplateStatusProvider = StateNotifierProvider<
    ToggleTemplateStatusNotifier, AsyncValue<ClassTemplate?>>((ref) {
  final repository = ref.watch(templatesRepositoryProvider);
  return ToggleTemplateStatusNotifier(repository, ref);
});

// =============================================================================
// INSTRUCTORS PROVIDERS
// =============================================================================

/// Instructor search query
final instructorSearchQueryProvider = StateProvider<String>((ref) => '');

/// All instructors provider
final instructorsProvider = FutureProvider<List<Instructor>>((ref) async {
  final repository = ref.watch(templatesRepositoryProvider);
  return repository.getInstructors();
});

/// Instructor search results provider
final instructorSearchResultsProvider =
    FutureProvider<List<Instructor>>((ref) async {
  final repository = ref.watch(templatesRepositoryProvider);
  final query = ref.watch(instructorSearchQueryProvider);

  if (query.isEmpty) {
    return repository.getInstructors();
  }

  return repository.getInstructors(searchQuery: query);
});

/// Recent instructors cache
class RecentInstructorsNotifier extends StateNotifier<List<Instructor>> {
  RecentInstructorsNotifier() : super([]);

  static const int maxRecent = 5;

  void addInstructor(Instructor instructor) {
    final updated = state.where((i) => i.id != instructor.id).toList();
    updated.insert(0, instructor);
    if (updated.length > maxRecent) {
      updated.removeRange(maxRecent, updated.length);
    }
    state = updated;
  }

  void clear() {
    state = [];
  }
}

final recentInstructorsProvider =
    StateNotifierProvider<RecentInstructorsNotifier, List<Instructor>>((ref) {
  return RecentInstructorsNotifier();
});

// =============================================================================
// LOCATIONS PROVIDERS
// =============================================================================

/// Available locations provider
final locationsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(templatesRepositoryProvider);
  return repository.getLocations();
});

// =============================================================================
// CREATE CLASS PROVIDERS
// =============================================================================

/// Create class notifier
class CreateClassNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  CreateClassNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  final TemplatesRepository _repository;
  final Ref _ref;

  Future<bool> createClass(CreateClassDto dto) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.createClass(dto);
      state = AsyncValue.data(result);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final createClassProvider = StateNotifierProvider<CreateClassNotifier,
    AsyncValue<Map<String, dynamic>?>>((ref) {
  final repository = ref.watch(templatesRepositoryProvider);
  return CreateClassNotifier(repository, ref);
});

/// Selected template for class creation
final selectedTemplateProvider = StateProvider<ClassTemplate?>((ref) => null);

/// Selected date for class creation
final selectedClassDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

/// Selected time for class creation (hour:minute)
final selectedClassTimeProvider = StateProvider<String?>((ref) => null);

/// Override instructor for class creation
final overrideInstructorProvider = StateProvider<Instructor?>((ref) => null);

/// Override capacity for class creation
final overrideCapacityProvider = StateProvider<int?>((ref) => null);

/// Override location for class creation
final overrideLocationProvider = StateProvider<String?>((ref) => null);

/// Reset all class creation state
void resetCreateClassState(WidgetRef ref) {
  ref.read(selectedTemplateProvider.notifier).state = null;
  ref.read(selectedClassDateProvider.notifier).state = DateTime.now();
  ref.read(selectedClassTimeProvider.notifier).state = null;
  ref.read(overrideInstructorProvider.notifier).state = null;
  ref.read(overrideCapacityProvider.notifier).state = null;
  ref.read(overrideLocationProvider.notifier).state = null;
  ref.read(createClassProvider.notifier).reset();
}
