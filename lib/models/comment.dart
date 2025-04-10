class Comment {
  final String id;
  final String userId;
  final String username;
  final String userProfilePicture;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.username,
    required this.userProfilePicture,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    try {
      // التعامل مع بيانات المستخدم
      Map<String, dynamic>? userMap;
      String userId, username, userProfilePic;
      
      if (json['user'] is Map) {
        userMap = json['user'] as Map<String, dynamic>;
        userId = userMap['_id'] ?? '';
        username = userMap['username'] ?? 'مستخدم غير معروف';
        userProfilePic = userMap['profilePicture'] ?? 'default-profile.jpg';
      } else {
        // إذا كان المستخدم مجرد ID
        userId = json['user']?.toString() ?? '';
        username = 'مستخدم غير معروف';
        userProfilePic = 'default-profile.jpg';
      }
      
      return Comment(
        id: json['_id'] ?? '',
        userId: userId,
        username: username,
        userProfilePicture: userProfilePic,
        text: json['text'] ?? '',
        createdAt: json['createdAt'] != null 
            ? DateTime.parse(json['createdAt']) 
            : DateTime.now(),
      );
    } catch (e) {
      print('خطأ في تحويل التعليق: $e');
      return Comment(
        id: '',
        userId: '',
        username: 'خطأ في التعليق',
        userProfilePicture: 'default-profile.jpg',
        text: 'حدث خطأ في عرض هذا التعليق',
        createdAt: DateTime.now(),
      );
    }
  }
  
  // تحويل التعليق إلى JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': {
        '_id': userId,
        'username': username,
        'profilePicture': userProfilePicture,
      },
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}