class User {
  final String id;
  final String username;
  final String email;
  final String profilePicture;
  final String bio;
  final List<String> followers;
  final List<String> following;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.profilePicture,
    required this.bio,
    required this.followers,
    required this.following,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      return User(
        id: json['_id'] ?? '',
        username: json['username'] ?? '',
        email: json['email'] ?? '',
        profilePicture: json['profilePicture'] ?? 'default-profile.jpg',
        bio: json['bio'] ?? '',
        followers: List<String>.from(json['followers'] ?? []),
        following: List<String>.from(json['following'] ?? []),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
      );
    } catch (e) {
      print('خطأ في تحويل المستخدم: $e');
      return User(
        id: json['_id'] ?? '',
        username: 'مستخدم غير معروف',
        email: '',
        profilePicture: 'default-profile.jpg',
        bio: '',
        followers: [],
        following: [],
        createdAt: DateTime.now(),
      );
    }
  }
}