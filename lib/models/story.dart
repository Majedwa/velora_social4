enum StoryType {
  image,   // صورة
  text,    // نص
  video,   // فيديو
}

class StoryItem {
  final String id;
  final StoryType type;
  final String content;       // مسار الصورة/الفيديو أو محتوى النص
  final DateTime createdAt;
  final Map<String, dynamic>? metadata; // بيانات إضافية مثل لون الخلفية للنص أو الفلاتر للصور
  final List<String> viewedBy; // المستخدمين الذين شاهدوا القصة

  StoryItem({
    required this.id,
    required this.type,
    required this.content,
    required this.createdAt,
    this.metadata,
    this.viewedBy = const [],
  });

  factory StoryItem.fromJson(Map<String, dynamic> json) {
    return StoryItem(
      id: json['id'] ?? json['_id'] ?? '',
      type: _parseStoryType(json['type']),
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      metadata: json['metadata'],
      viewedBy: json['viewedBy'] != null 
          ? List<String>.from(json['viewedBy']) 
          : [],
    );
  }

  static StoryType _parseStoryType(String? typeStr) {
    if (typeStr == null) return StoryType.image;
    
    switch (typeStr) {
      case 'text':
        return StoryType.text;
      case 'video':
        return StoryType.video;
      case 'image':
      default:
        return StoryType.image;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
      'viewedBy': viewedBy,
    };
  }

  // التحقق من صلاحية القصة (24 ساعة)
  bool get isValid {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inHours < 24;
  }

  // التحقق مما إذا كان مستخدم معين قد شاهد القصة
  bool isViewedBy(String userId) {
    return viewedBy.contains(userId);
  }

  // إضافة مستخدم إلى قائمة المشاهدين
  StoryItem addViewer(String userId) {
    if (!viewedBy.contains(userId)) {
      final updatedViewedBy = List<String>.from(viewedBy)..add(userId);
      return StoryItem(
        id: id,
        type: type,
        content: content,
        createdAt: createdAt,
        metadata: metadata,
        viewedBy: updatedViewedBy,
      );
    }
    return this;
  }
}

class Story {
  final String id;
  final String userId;
  final String username;
  final String userProfilePicture;
  final List<StoryItem> items;
  final DateTime lastUpdated;

  Story({
    required this.id,
    required this.userId,
    required this.username,
    required this.userProfilePicture,
    required this.items,
    required this.lastUpdated,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] ?? json['_id'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? 'مستخدم غير معروف',
      userProfilePicture: json['userProfilePicture'] ?? 'default-profile.jpg',
      items: json['items'] != null 
          ? List<StoryItem>.from(json['items'].map((item) => StoryItem.fromJson(item))) 
          : [],
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userProfilePicture': userProfilePicture,
      'items': items.map((item) => item.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // الحصول على القصص الصالحة فقط (أقل من 24 ساعة)
  List<StoryItem> get validItems {
    return items.where((item) => item.isValid).toList();
  }

  // التحقق مما إذا كانت جميع القصص قد شوهدت بواسطة مستخدم معين
  bool allViewedBy(String userId) {
    final validItemsList = validItems;
    if (validItemsList.isEmpty) return false;
    
    return validItemsList.every((item) => item.isViewedBy(userId));
  }

  // التحقق مما إذا كانت هناك أي قصة جديدة (لم تشاهد) لمستخدم معين
  bool hasUnviewedItems(String userId) {
    final validItemsList = validItems;
    if (validItemsList.isEmpty) return false;
    
    return validItemsList.any((item) => !item.isViewedBy(userId));
  }

  // التحقق من صلاحية جميع القصص
  bool get hasValidItems {
    return validItems.isNotEmpty;
  }
}