import 'comment.dart';

class Post {
  final String id;
  final String userId;
  final String username;
  final String userProfilePicture;
  final String content;
  final String? image; // صورة واحدة (للتوافقية مع الكود القديم)
  final List<String> images; // دعم الصور المتعددة
  final List<String> likes;
  final List<Comment> comments;
  final DateTime createdAt;
  final bool isFeatured; // للمنشورات المميزة

  Post({
    required this.id,
    required this.userId,
    required this.username,
    required this.userProfilePicture,
    required this.content,
    this.image,
    this.images = const [],
    required this.likes,
    required this.comments,
    required this.createdAt,
    this.isFeatured = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    try {
      // التعامل مع بيانات المستخدم بشكل مرن
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
      
      // تحويل التعليقات بطريقة آمنة
      List<Comment> commentsList = [];
      if (json['comments'] != null && json['comments'] is List) {
        commentsList = (json['comments'] as List)
            .map((comment) => Comment.fromJson(comment))
            .toList();
      }
      
      // تحويل الإعجابات بطريقة آمنة
      List<String> likesList = [];
      if (json['likes'] != null && json['likes'] is List) {
        likesList = (json['likes'] as List)
            .map((like) => like.toString())
            .toList();
      }
      
      // تحويل الصور المتعددة
      List<String> imagesList = [];
      if (json['images'] != null && json['images'] is List) {
        imagesList = (json['images'] as List)
            .map((img) => img.toString())
            .toList();
      }
      
      // للتوافقية مع النظام القديم، إذا كان هناك صورة واحدة ولكن لا توجد قائمة صور
      // نضيف الصورة إلى قائمة الصور
      final String? singleImage = json['image'];
      if (singleImage != null && singleImage.isNotEmpty && imagesList.isEmpty) {
        imagesList.add(singleImage);
      }
      
      return Post(
        id: json['_id'] ?? '',
        userId: userId,
        username: username,
        userProfilePicture: userProfilePic,
        content: json['content'] ?? '',
        image: json['image'], // للتوافقية مع الكود القديم
        images: imagesList,
        likes: likesList,
        comments: commentsList,
        createdAt: json['createdAt'] != null 
            ? DateTime.parse(json['createdAt']) 
            : DateTime.now(),
        isFeatured: json['isFeatured'] ?? false,
      );
    } catch (e) {
      print('خطأ في تحويل المنشور: $e');
      // إنشاء منشور فارغ بدلاً من رمي استثناء
      return Post(
        id: json['_id'] ?? '',
        userId: '',
        username: 'خطأ في المنشور',
        userProfilePicture: 'default-profile.jpg',
        content: 'حدث خطأ في عرض هذا المنشور',
        likes: [],
        comments: [],
        images: [],
        createdAt: DateTime.now(),
      );
    }
  }
  
  // تحويل المنشور إلى JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': {
        '_id': userId,
        'username': username,
        'profilePicture': userProfilePicture,
      },
      'content': content,
      'image': image,
      'images': images,
      'likes': likes,
      'comments': comments.map((comment) => comment.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'isFeatured': isFeatured,
    };
  }
}