class FamilyConnection {
  final String userId;
  final String displayName;
  final String username;
  final DateTime joinedAt;

  const FamilyConnection({
    required this.userId,
    required this.displayName,
    required this.username,
    required this.joinedAt,
  });

  factory FamilyConnection.fromMemberMap(Map<String, dynamic> map) {
    return FamilyConnection(
      userId: map['member_id'] as String,
      displayName: map['member_display_name'] as String,
      username: map['member_username'] as String,
      joinedAt: DateTime.parse(map['joined_at'] as String),
    );
  }

  factory FamilyConnection.fromOwnerMap(Map<String, dynamic> map) {
    return FamilyConnection(
      userId: map['owner_id'] as String,
      displayName: map['owner_display_name'] as String,
      username: map['owner_username'] as String,
      joinedAt: DateTime.parse(map['joined_at'] as String),
    );
  }

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return displayName.substring(0, displayName.length.clamp(1, 2)).toUpperCase();
  }
}
