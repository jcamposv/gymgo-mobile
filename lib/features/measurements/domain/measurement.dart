import 'package:equatable/equatable.dart';

/// Measurement entity matching web/backend data model
/// Table: member_measurements
class Measurement extends Equatable {
  const Measurement({
    required this.id,
    required this.memberId,
    required this.organizationId,
    required this.measuredAt,
    this.bodyHeightCm,
    this.bodyWeightKg,
    this.bodyMassIndex,
    this.bodyFatPercentage,
    this.muscleMassKg,
    this.waistCm,
    this.hipCm,
    this.chestCm,
    this.armCm,
    this.thighCm,
    this.notes,
    this.recordedById,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String memberId;
  final String organizationId;
  final DateTime measuredAt;

  // Body measurements (metric)
  final double? bodyHeightCm;
  final double? bodyWeightKg;
  final double? bodyMassIndex;

  // Body composition
  final double? bodyFatPercentage;
  final double? muscleMassKg;

  // Circumference measurements (cm)
  final double? waistCm;
  final double? hipCm;
  final double? chestCm;
  final double? armCm;
  final double? thighCm;

  // Additional
  final String? notes;
  final String? recordedById;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Calculate BMI from height and weight
  /// BMI = weight_kg / (height_cm / 100)²
  double? get calculatedBmi {
    if (bodyHeightCm != null && bodyWeightKg != null && bodyHeightCm! > 0) {
      final heightM = bodyHeightCm! / 100;
      return double.parse((bodyWeightKg! / (heightM * heightM)).toStringAsFixed(1));
    }
    return bodyMassIndex;
  }

  /// Get BMI category in Spanish
  String? get bmiCategory {
    final bmi = calculatedBmi;
    if (bmi == null) return null;
    if (bmi < 18.5) return 'Bajo peso';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Sobrepeso';
    return 'Obesidad';
  }

  factory Measurement.fromJson(Map<String, dynamic> json) {
    return Measurement(
      id: json['id'] as String,
      memberId: json['member_id'] as String,
      organizationId: json['organization_id'] as String,
      measuredAt: DateTime.parse(json['measured_at'] as String),
      bodyHeightCm: (json['body_height_cm'] as num?)?.toDouble(),
      bodyWeightKg: (json['body_weight_kg'] as num?)?.toDouble(),
      bodyMassIndex: (json['body_mass_index'] as num?)?.toDouble(),
      bodyFatPercentage: (json['body_fat_percentage'] as num?)?.toDouble(),
      muscleMassKg: (json['muscle_mass_kg'] as num?)?.toDouble(),
      waistCm: (json['waist_cm'] as num?)?.toDouble(),
      hipCm: (json['hip_cm'] as num?)?.toDouble(),
      chestCm: (json['chest_cm'] as num?)?.toDouble(),
      armCm: (json['arm_cm'] as num?)?.toDouble(),
      thighCm: (json['thigh_cm'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      recordedById: json['recorded_by_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member_id': memberId,
      'organization_id': organizationId,
      'measured_at': measuredAt.toIso8601String(),
      'body_height_cm': bodyHeightCm,
      'body_weight_kg': bodyWeightKg,
      'body_mass_index': bodyMassIndex,
      'body_fat_percentage': bodyFatPercentage,
      'muscle_mass_kg': muscleMassKg,
      'waist_cm': waistCm,
      'hip_cm': hipCm,
      'chest_cm': chestCm,
      'arm_cm': armCm,
      'thigh_cm': thighCm,
      'notes': notes,
      'recorded_by_id': recordedById,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        memberId,
        organizationId,
        measuredAt,
        bodyHeightCm,
        bodyWeightKg,
        bodyMassIndex,
        bodyFatPercentage,
        muscleMassKg,
        waistCm,
        hipCm,
        chestCm,
        armCm,
        thighCm,
        notes,
        recordedById,
        createdAt,
        updatedAt,
      ];
}

/// Form data for creating/updating measurements
/// Matches web MeasurementFormData structure
class MeasurementFormData {
  MeasurementFormData({
    required this.measuredAt,
    this.heightCm,
    this.weightKg,
    this.bodyFatPercentage,
    this.muscleMassKg,
    this.waistCm,
    this.hipCm,
    this.notes,
  });

  final DateTime measuredAt;
  final double? heightCm;
  final double? weightKg;
  final double? bodyFatPercentage;
  final double? muscleMassKg;
  final double? waistCm;
  final double? hipCm;
  final String? notes;

  /// Convert to database insert format
  Map<String, dynamic> toInsertJson({
    required String memberId,
    required String organizationId,
    String? recordedById,
  }) {
    return {
      'member_id': memberId,
      'organization_id': organizationId,
      'measured_at': measuredAt.toIso8601String(),
      if (heightCm != null) 'body_height_cm': heightCm,
      if (weightKg != null) 'body_weight_kg': weightKg,
      if (bodyFatPercentage != null) 'body_fat_percentage': bodyFatPercentage,
      if (muscleMassKg != null) 'muscle_mass_kg': muscleMassKg,
      if (waistCm != null) 'waist_cm': waistCm,
      if (hipCm != null) 'hip_cm': hipCm,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (recordedById != null) 'recorded_by_id': recordedById,
    };
  }

  /// Check if at least one measurement value is provided
  bool get hasAnyValue =>
      heightCm != null ||
      weightKg != null ||
      bodyFatPercentage != null ||
      muscleMassKg != null ||
      waistCm != null ||
      hipCm != null;
}

/// Supported metric types for charts (matches web)
enum MetricType {
  weight('Peso', 'kg', 'body_weight_kg'),
  bodyFat('% Grasa', '%', 'body_fat_percentage'),
  muscleMass('Masa muscular', 'kg', 'muscle_mass_kg'),
  bmi('IMC', '', 'bmi');

  const MetricType(this.label, this.unit, this.dataKey);

  final String label;
  final String unit;
  final String dataKey;

  /// Get value from measurement based on metric type
  double? getValue(Measurement m) {
    switch (this) {
      case MetricType.weight:
        return m.bodyWeightKg;
      case MetricType.bodyFat:
        return m.bodyFatPercentage;
      case MetricType.muscleMass:
        return m.muscleMassKg;
      case MetricType.bmi:
        return m.calculatedBmi;
    }
  }
}
