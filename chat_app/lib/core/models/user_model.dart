class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String avatarUrl;
  final bool isOnline;
  final DateTime lastSeen;

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.avatarUrl = '',
    this.isOnline = false,
    required this.lastSeen,
  });

  // --- Firebase pattern (commented for demo) ---
  // factory UserModel.fromFirestore(DocumentSnapshot doc) {
  //   final data = doc.data() as Map<String, dynamic>;
  //   return UserModel(
  //     uid: doc.id,
  //     displayName: data['displayName'],
  //     email: data['email'],
  //     avatarUrl: data['avatarUrl'] ?? '',
  //     isOnline: data['isOnline'] ?? false,
  //     lastSeen: (data['lastSeen'] as Timestamp).toDate(),
  //   );
  // }
  //
  // Map<String, dynamic> toFirestore() => {
  //   'displayName': displayName,
  //   'email': email,
  //   'avatarUrl': avatarUrl,
  //   'isOnline': isOnline,
  //   'lastSeen': Timestamp.fromDate(lastSeen),
  // };

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      displayName: map['displayName'] as String,
      email: map['email'] as String,
      avatarUrl: map['avatarUrl'] as String? ?? '',
      isOnline: map['isOnline'] as bool? ?? false,
      lastSeen: DateTime.parse(map['lastSeen'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'avatarUrl': avatarUrl,
        'isOnline': isOnline,
        'lastSeen': lastSeen.toIso8601String(),
      };

  UserModel copyWith({bool? isOnline, DateTime? lastSeen}) {
    return UserModel(
      uid: uid,
      displayName: displayName,
      email: email,
      avatarUrl: avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }
}
