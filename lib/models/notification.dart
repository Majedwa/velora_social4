enum NotificationType {
  like,      // إعجاب
  comment,   // تعليق
  follow,    // متابعة
  mention,   // إشارة
  message,   // رسالة
  system,    // إشعار نظام
}

class AppNotification {
  final String id;
  final String recipientId;    // المستلم
  final String? senderId;      // المرسل (قد يكون null في إشعارات النظام)
  final String? senderName;
  final String? senderAvatar;
  final NotificationType type;
  final String message;
  final String? relatedItemId;  // معرف المنشور أو التعليق المرتبط
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.recipientId,
    this.senderId,
    this.senderName,
    this.senderAvatar,
    required this.type,
    required this.message,
    this.relatedItemId,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id'] ?? json['id'] ?? '',
      recipientId: json['recipientId'] ?? '',
      senderId: json['senderId'],
      senderName: json['senderName'],
      senderAvatar: json['senderAvatar'],
      type: _parseNotificationType(json['type']),
      message: json['message'] ?? '',
      relatedItemId: json['relatedItemId'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'recipientId': recipientId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'type': type.toString().split('.').last,
      'message': message,
      'relatedItemId': relatedItemId,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  // تحليل نوع الإشعار من النص
  static NotificationType _parseNotificationType(String? typeStr) {
    if (typeStr == null) return NotificationType.system;
    
    switch (typeStr) {
      case 'like':
        return NotificationType.like;
      case 'comment':
        return NotificationType.comment;
      case 'follow':
        return NotificationType.follow;
      case 'mention':
        return NotificationType.mention;
      case 'message':
        return NotificationType.message;
      case 'system':
      default:
        return NotificationType.system;
    }
  }

  // إنشاء نسخة جديدة مع تغيير حالة القراءة
  AppNotification copyWithRead({required bool isRead}) {
    return AppNotification(
      id: id,
      recipientId: recipientId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      type: type,
      message: message,
      relatedItemId: relatedItemId,
      createdAt: createdAt,
      isRead: isRead,
    );
  }
}