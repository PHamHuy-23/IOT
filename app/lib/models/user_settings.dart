class UserSettings {
  final String userId;
  final bool pushEnabled;
  final bool healthAlerts;
  final bool dataSharing;
  final bool biometricLock;

  const UserSettings({
    required this.userId,
    this.pushEnabled = true,
    this.healthAlerts = true,
    this.dataSharing = false,
    this.biometricLock = false,
  });

  factory UserSettings.defaults(String userId) =>
      UserSettings(userId: userId);

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      userId: map['user_id'] as String,
      pushEnabled: (map['push_enabled'] as bool?) ?? true,
      healthAlerts: (map['health_alerts'] as bool?) ?? true,
      dataSharing: (map['data_sharing'] as bool?) ?? false,
      biometricLock: (map['biometric_lock'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'push_enabled': pushEnabled,
        'health_alerts': healthAlerts,
        'data_sharing': dataSharing,
        'biometric_lock': biometricLock,
        'updated_at': DateTime.now().toIso8601String(),
      };

  UserSettings copyWith({
    bool? pushEnabled,
    bool? healthAlerts,
    bool? dataSharing,
    bool? biometricLock,
  }) {
    return UserSettings(
      userId: userId,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      healthAlerts: healthAlerts ?? this.healthAlerts,
      dataSharing: dataSharing ?? this.dataSharing,
      biometricLock: biometricLock ?? this.biometricLock,
    );
  }
}
