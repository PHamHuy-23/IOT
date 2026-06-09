class UserMedicalProfile {
  final String userId;
  final String? bloodType;
  final int? heightCm;
  final double? weightKg;
  final String? allergies;
  final String? emergencyContact;

  const UserMedicalProfile({
    required this.userId,
    this.bloodType,
    this.heightCm,
    this.weightKg,
    this.allergies,
    this.emergencyContact,
  });

  factory UserMedicalProfile.empty(String userId) =>
      UserMedicalProfile(userId: userId);

  factory UserMedicalProfile.fromMap(Map<String, dynamic> map) {
    return UserMedicalProfile(
      userId: map['user_id'] as String,
      bloodType: map['blood_type'] as String?,
      heightCm: (map['height_cm'] as num?)?.toInt(),
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      allergies: map['allergies'] as String?,
      emergencyContact: map['emergency_contact'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        if (bloodType != null) 'blood_type': bloodType,
        if (heightCm != null) 'height_cm': heightCm,
        if (weightKg != null) 'weight_kg': weightKg,
        if (allergies != null) 'allergies': allergies,
        if (emergencyContact != null) 'emergency_contact': emergencyContact,
        'updated_at': DateTime.now().toIso8601String(),
      };

  String get heightWeightDisplay {
    if (heightCm == null && weightKg == null) return 'Chưa cập nhật';
    final h = heightCm != null ? '$heightCm cm' : '—';
    final w = weightKg != null ? '${weightKg!.toStringAsFixed(1)} kg' : '—';
    return '$h  /  $w';
  }

  UserMedicalProfile copyWith({
    String? bloodType,
    int? heightCm,
    double? weightKg,
    String? allergies,
    String? emergencyContact,
  }) {
    return UserMedicalProfile(
      userId: userId,
      bloodType: bloodType ?? this.bloodType,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      allergies: allergies ?? this.allergies,
      emergencyContact: emergencyContact ?? this.emergencyContact,
    );
  }
}
