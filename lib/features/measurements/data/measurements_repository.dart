import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/measurement.dart';

/// Repository for managing member measurements
/// Mirrors web API: measurement.actions.ts
class MeasurementsRepository {
  MeasurementsRepository(this._client);

  final SupabaseClient _client;

  /// Get all measurements for a member
  /// Sorted by measured_at descending (newest first)
  Future<List<Measurement>> getMemberMeasurements(String memberId, {String? organizationId}) async {
    try {
      debugPrint('MeasurementsRepository: Fetching measurements for memberId: $memberId, orgId: $organizationId');

      var query = _client
          .from('member_measurements')
          .select()
          .eq('member_id', memberId);

      if (organizationId != null) {
        query = query.eq('organization_id', organizationId);
      }

      final response = await query.order('measured_at', ascending: false);

      debugPrint('MeasurementsRepository: Got ${(response as List).length} measurements');

      return response
          .map((json) => Measurement.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('MeasurementsRepository: Error fetching measurements: $e');
      rethrow;
    }
  }

  /// Get the latest measurement for a member
  Future<Measurement?> getLatestMeasurement(String memberId) async {
    try {
      final response = await _client
          .from('member_measurements')
          .select()
          .eq('member_id', memberId)
          .order('measured_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return Measurement.fromJson(response);
    } catch (e) {
      debugPrint('MeasurementsRepository: Error fetching latest measurement: $e');
      rethrow;
    }
  }

  /// Create a new measurement
  Future<Measurement> createMeasurement({
    required String memberId,
    required String organizationId,
    required MeasurementFormData formData,
    String? recordedById,
  }) async {
    try {
      final insertData = formData.toInsertJson(
        memberId: memberId,
        organizationId: organizationId,
        recordedById: recordedById,
      );

      // Calculate BMI if height and weight provided
      if (formData.heightCm != null && formData.weightKg != null) {
        final heightM = formData.heightCm! / 100;
        final bmi = formData.weightKg! / (heightM * heightM);
        insertData['body_mass_index'] = double.parse(bmi.toStringAsFixed(1));
      }

      final response = await _client
          .from('member_measurements')
          .insert(insertData)
          .select()
          .single();

      debugPrint('MeasurementsRepository: Measurement created successfully');
      return Measurement.fromJson(response);
    } catch (e) {
      debugPrint('MeasurementsRepository: Error creating measurement: $e');
      rethrow;
    }
  }

  /// Update an existing measurement
  Future<Measurement> updateMeasurement({
    required String measurementId,
    required MeasurementFormData formData,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'measured_at': formData.measuredAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Only include non-null values
      if (formData.heightCm != null) updateData['body_height_cm'] = formData.heightCm;
      if (formData.weightKg != null) updateData['body_weight_kg'] = formData.weightKg;
      if (formData.bodyFatPercentage != null) {
        updateData['body_fat_percentage'] = formData.bodyFatPercentage;
      }
      if (formData.muscleMassKg != null) updateData['muscle_mass_kg'] = formData.muscleMassKg;
      if (formData.waistCm != null) updateData['waist_cm'] = formData.waistCm;
      if (formData.hipCm != null) updateData['hip_cm'] = formData.hipCm;
      if (formData.notes != null) updateData['notes'] = formData.notes;

      // Recalculate BMI if height and weight provided
      if (formData.heightCm != null && formData.weightKg != null) {
        final heightM = formData.heightCm! / 100;
        final bmi = formData.weightKg! / (heightM * heightM);
        updateData['body_mass_index'] = double.parse(bmi.toStringAsFixed(1));
      }

      final response = await _client
          .from('member_measurements')
          .update(updateData)
          .eq('id', measurementId)
          .select()
          .single();

      debugPrint('MeasurementsRepository: Measurement updated successfully');
      return Measurement.fromJson(response);
    } catch (e) {
      debugPrint('MeasurementsRepository: Error updating measurement: $e');
      rethrow;
    }
  }

  /// Delete a measurement
  Future<void> deleteMeasurement(String measurementId) async {
    try {
      await _client
          .from('member_measurements')
          .delete()
          .eq('id', measurementId);

      debugPrint('MeasurementsRepository: Measurement deleted successfully');
    } catch (e) {
      debugPrint('MeasurementsRepository: Error deleting measurement: $e');
      rethrow;
    }
  }

  /// Get measurements for chart (sorted ascending by date)
  Future<List<Measurement>> getMeasurementsForChart(
    String memberId, {
    int limit = 30,
  }) async {
    try {
      final response = await _client
          .from('member_measurements')
          .select()
          .eq('member_id', memberId)
          .order('measured_at', ascending: true)
          .limit(limit);

      return (response as List)
          .map((json) => Measurement.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('MeasurementsRepository: Error fetching chart data: $e');
      rethrow;
    }
  }
}
