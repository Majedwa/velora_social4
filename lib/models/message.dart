enum MessageType {
  text,     // نص
  image,    // صورة
  file,     // ملف
  voice,    // رسالة صوتية
  location, // موقع
  system,   // رسالة نظام
}

class Message {
  final String id;
  final String senderId;
  final String recipientId;
  final String conversationId;
  final MessageType type;
  final String content;      // النص الأساسي أو مسار الملف
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? metadata; // بيانات إضافية (مثل حجم الملف، اسم الملف، إلخ)

  Message({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.conversationId,
    required this.type,
    required this.content,
    required this.createdAt,
    this.isRead = false,
    this.metadata,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? json['_id'] ?? '',
      senderId: json['senderId'] ?? '',
      recipientId: json['recipientId'] ?? '',
      conversationId: json['conversationId'] ?? '',
      type: _parseMessageType(json['type']),
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'recipientId': recipientId,
      'conversationId': conversationId,
      'type': type.toString().split('.').last,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  static MessageType _parseMessageType(String? typeStr) {
    if (typeStr == null) return MessageType.text;
    
    switch (typeStr) {
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'voice':
        return MessageType.voice;
      case 'location':
        return MessageType.location;
      case 'system':
        return MessageType.system;
      case 'text':
      default:
        return MessageType.text;
    }
  }

  // إنشاء نسخة مقروءة من الرسالة
  Message copyWithRead({required bool read}) {
    return Message(
      id: id,
      senderId: senderId,
      recipientId: recipientId,
      conversationId: conversationId,
      type: type,
      content: content,
      createdAt: createdAt,
      isRead: read,
      metadata: metadata,
    );
  }
}

class Conversation {
  final String id;
  final List<String> participants;
  final String? lastMessageContent;
  final DateTime? lastMessageTime;
  final bool hasUnreadMessages;
  final int unreadCount;

  // بيانات العضو الآخر (للعرض)
  final String? otherUserId;
  final String? otherUserName;
  final String? otherUserAvatar;

  Conversation({
    required this.id,
    required this.participants,
    this.lastMessageContent,
    this.lastMessageTime,
    this.hasUnreadMessages = false,
    this.unreadCount = 0,
    this.otherUserId,
    this.otherUserName,
    this.otherUserAvatar,
  });

  factory Conversation.fromJson(Map<String, dynamic> json, {required String currentUserId}) {
    final List<String> participants = (json['participants'] as List?)
            ?.map((p) => p.toString())
            .toList() ??
        [];
    
    // تحديد معرف وبيانات المستخدم الآخر
    String? otherUserId;
    String? otherUserName;
    String? otherUserAvatar;
    
    if (participants.length == 2) {
      otherUserId = participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );
      
      if (json['userData'] != null && json['userData'][otherUserId] != null) {
        final userData = json['userData'][otherUserId];
        otherUserName = userData['username'];
        otherUserAvatar = userData['profilePicture'];
      }
    }

    return Conversation(
      id: json['id'] ?? json['_id'] ?? '',
      participants: participants,
      lastMessageContent: json['lastMessageContent'],
      lastMessageTime: json['lastMessageTime'] != null 
          ? DateTime.parse(json['lastMessageTime']) 
          : null,
      hasUnreadMessages: json['hasUnreadMessages'] ?? false,
      unreadCount: json['unreadCount'] ?? 0,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      otherUserAvatar: otherUserAvatar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants,
      'lastMessageContent': lastMessageContent,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'hasUnreadMessages': hasUnreadMessages,
      'unreadCount': unreadCount,
      'userData': otherUserId != null ? {
        otherUserId: {
          'username': otherUserName,
          'profilePicture': otherUserAvatar,
        }
      } : null,
    };
  }
}