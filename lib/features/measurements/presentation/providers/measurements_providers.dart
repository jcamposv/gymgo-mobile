import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/measurements_repository.dart';
import '../../domain/measurement.dart';

/// Repository provider
final measurementsRepositoryProvider = Provider<MeasurementsRepository>((ref) {
  return MeasurementsRepository(Supabase.instance.client);
});

/// Parameters for measurements query
typedef MeasurementsParams = ({String memberId, String? organizationId});

/// Provider for all measurements of the current member
/// Requires memberId and optional organizationId parameter
final memberMeasurementsProvider = FutureProvider.family<List<Measurement>, MeasurementsParams>(
  (ref, params) async {
    final repository = ref.watch(measurementsRepositoryProvider);
    return repository.getMemberMeasurements(params.memberId, organizationId: params.organizationId);
  },
);

/// Provider for latest measurement
final latestMeasurementProvider = FutureProvider.family<Measurement?, String>(
  (ref, memberId) async {
    final repository = ref.watch(measurementsRepositoryProvider);
    return repository.getLatestMeasurement(memberId);
  },
);

/// Provider for chart data (ascending order)
final measurementsChartDataProvider = FutureProvider.family<List<Measurement>, String>(
  (ref, memberId) async {
    final repository = ref.watch(measurementsRepositoryProvider);
    return repository.getMeasurementsForChart(memberId);
  },
);

/// Selected metric type for chart
final selectedMetricProvider = StateProvider<MetricType>((ref) => MetricType.weight);

/// State for measurements operations
class MeasurementsState {
  const MeasurementsState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  MeasurementsState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? error,
  }) {
    return MeasurementsState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

/// Notifier for measurement operations
class MeasurementsNotifier extends StateNotifier<MeasurementsState> {
  MeasurementsNotifier(this._repository, this._ref) : super(const MeasurementsState());

  final MeasurementsRepository _repository;
  final Ref _ref;

  /// Add a new measurement
  Future<Measurement?> addMeasurement({
    required String memberId,
    required String organizationId,
    required MeasurementFormData formData,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      final measurement = await _repository.createMeasurement(
        memberId: memberId,
        organizationId: organizationId,
        formData: formData,
        recordedById: userId,
      );

      // Invalidate related providers to refresh data
      final params = (memberId: memberId, organizationId: organizationId as String?);
      _ref.invalidate(memberMeasurementsProvider(params));
      _ref.invalidate(latestMeasurementProvider(memberId));
      _ref.invalidate(measurementsChartDataProvider(memberId));

      state = state.copyWith(isSubmitting: false);
      return measurement;
    } catch (e) {
      debugPrint('MeasurementsNotifier: Error adding measurement: $e');
      state = state.copyWith(
        isSubmitting: false,
        error: 'Error al guardar la medición',
      );
      return null;
    }
  }

  /// Update an existing measurement
  Future<Measurement?> updateMeasurement({
    required String measurementId,
    required String memberId,
    required String organizationId,
    required MeasurementFormData formData,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final measurement = await _repository.updateMeasurement(
        measurementId: measurementId,
        formData: formData,
      );

      // Invalidate related providers
      final params = (memberId: memberId, organizationId: organizationId as String?);
      _ref.invalidate(memberMeasurementsProvider(params));
      _ref.invalidate(latestMeasurementProvider(memberId));
      _ref.invalidate(measurementsChartDataProvider(memberId));

      state = state.copyWith(isSubmitting: false);
      return measurement;
    } catch (e) {
      debugPrint('MeasurementsNotifier: Error updating measurement: $e');
      state = state.copyWith(
        isSubmitting: false,
        error: 'Error al actualizar la medición',
      );
      return null;
    }
  }

  /// Delete a measurement
  Future<bool> deleteMeasurement({
    required String measurementId,
    required String memberId,
    required String organizationId,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);

    try {
      await _repository.deleteMeasurement(measurementId);

      // Invalidate related providers
      final params = (memberId: memberId, organizationId: organizationId as String?);
      _ref.invalidate(memberMeasurementsProvider(params));
      _ref.invalidate(latestMeasurementProvider(memberId));
      _ref.invalidate(measurementsChartDataProvider(memberId));

      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      debugPrint('MeasurementsNotifier: Error deleting measurement: $e');
      state = state.copyWith(
        isSubmitting: false,
        error: 'Error al eliminar la medición',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for measurements notifier
final measurementsNotifierProvider =
    StateNotifierProvider<MeasurementsNotifier, MeasurementsState>((ref) {
  final repository = ref.watch(measurementsRepositoryProvider);
  return MeasurementsNotifier(repository, ref);
});
