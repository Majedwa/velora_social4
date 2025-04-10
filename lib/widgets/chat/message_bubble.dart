import 'package:flutter/material.dart';
import 'dart:io';
import '../../models/message.dart';
import '../../widgets/common/network_image.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showUserInfo;
  final String userAvatar;
  final String userName;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.showUserInfo = false,
    this.userAvatar = '',
    this.userName = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // صورة المستخدم الآخر (تظهر فقط للرسائل المستلمة)
          if (!isMe && showUserInfo)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: userAvatar.isNotEmpty
                    ? ClipOval(
                        child: NetworkImageWithPlaceholder(
                          imageUrl: userAvatar,
                          width: 32,
                          height: 32,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
              ),
            ),
          
          // محتوى الرسالة
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: _getBubblePadding(),
              decoration: BoxDecoration(
                color: _getBubbleColor(context),
                borderRadius: _getBubbleRadius(),
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // اسم المرسل (للرسائل المستلمة فقط)
                  if (!isMe && showUserInfo && userName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        userName,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  
                  // محتوى الرسالة حسب النوع
                  _buildMessageContent(context),
                  
                  // وقت الرسالة وحالة القراءة
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.createdAt),
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                            fontSize: 10,
                          ),
                        ),
                        if (isMe)
                          Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: Icon(
                              message.isRead ? Icons.done_all : Icons.done,
                              size: 12,
                              color: message.isRead
                                  ? Colors.blue
                                  : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            color: isMe ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        );
      
      case MessageType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildImageContent(context),
        );
      
      case MessageType.file:
        return _buildFileContent(context);
      
      case MessageType.voice:
        return _buildVoiceContent(context);
      
      case MessageType.location:
        return _buildLocationContent(context);
      
      case MessageType.system:
        return Text(
          message.content,
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        );
      
      default:
        return Text(
          message.content,
          style: TextStyle(
            color: isMe ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        );
    }
  }

  Widget _buildImageContent(BuildContext context) {
    // التحقق مما إذا كانت الصورة محلية أو من الخادم
    if (message.content.startsWith('/')) {
      // صورة محلية
      return Image.file(
        File(message.content),
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 200,
            height: 150,
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.error, color: Colors.red),
            ),
          );
        },
      );
    } else {
      // صورة من الخادم
      return NetworkImageWithPlaceholder(
        imageUrl: message.content,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
      );
    }
  }

  Widget _buildFileContent(BuildContext context) {
    final fileName = message.metadata?['name'] ?? 'ملف';
    final fileSize = message.metadata?['size'] ?? 0;
    
    String formattedSize = '';
    if (fileSize is int) {
      if (fileSize < 1024) {
        formattedSize = '$fileSize B';
      } else if (fileSize < 1024 * 1024) {
        formattedSize = '${(fileSize / 1024).toStringAsFixed(1)} KB';
      } else {
        formattedSize = '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.blue.withOpacity(0.1)
            : Theme.of(context).highlightColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file, size: 32),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (formattedSize.isNotEmpty)
                  Text(
                    formattedSize,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.download, size: 20),
        ],
      ),
    );
  }

  Widget _buildVoiceContent(BuildContext context) {
    // مستقبلاً يمكن إضافة مشغل صوتي هنا
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.blue.withOpacity(0.1)
            : Theme.of(context).highlightColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mic, size: 24),
          const SizedBox(width: 8),
          Text(
            'رسالة صوتية',
            style: TextStyle(
              color: isMe
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationContent(BuildContext context) {
    // مستقبلاً يمكن إضافة عرض خريطة مصغرة هنا
    return Container(
      width: 200,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, size: 32),
            SizedBox(height: 8),
            Text('موقع'),
          ],
        ),
      ),
    );
  }

  EdgeInsetsGeometry _getBubblePadding() {
    switch (message.type) {
      case MessageType.image:
        return const EdgeInsets.all(4);
      case MessageType.text:
      default:
        return const EdgeInsets.all(12);
    }
  }

  Color _getBubbleColor(BuildContext context) {
    if (isMe) {
      return Theme.of(context).primaryColor;
    } else {
      switch (message.type) {
        case MessageType.system:
          return Colors.transparent;
        default:
          return Theme.of(context).cardColor;
      }
    }
  }

  BorderRadius _getBubbleRadius() {
    return BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMe ? 16 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 16),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}