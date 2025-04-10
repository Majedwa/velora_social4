import 'package:flutter/material.dart';
import '../../models/message.dart';
import '../../utils/time_util.dart';
import '../../widgets/common/network_image.dart';

class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const ConversationTile({
    Key? key,
    required this.conversation,
    required this.onTap,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(conversation.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16.0),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) => onDismiss(),
      child: Material(
        color: conversation.hasUnreadMessages
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Theme.of(context).scaffoldBackgroundColor,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // صورة المستخدم الآخر
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: conversation.otherUserAvatar != null && conversation.otherUserAvatar!.isNotEmpty
                          ? ClipOval(
                              child: NetworkImageWithPlaceholder(
                                imageUrl: conversation.otherUserAvatar!,
                                width: 48,
                                height: 48,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 30,
                              color: Theme.of(context).primaryColor,
                            ),
                    ),
                    // مؤشر للرسائل غير المقروءة
                    if (conversation.hasUnreadMessages)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 1.5,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              conversation.unreadCount > 9
                                  ? '9+'
                                  : conversation.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                
                // معلومات المحادثة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // اسم المستخدم
                      Text(
                        conversation.otherUserName ?? 'مستخدم',
                        style: TextStyle(
                          fontWeight: conversation.hasUnreadMessages
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // آخر رسالة
                      Text(
                        _getLastMessagePreview(),
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontWeight: conversation.hasUnreadMessages
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // وقت آخر رسالة
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (conversation.lastMessageTime != null)
                      Text(
                        _formatTime(conversation.lastMessageTime!),
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getLastMessagePreview() {
    if (conversation.lastMessageContent == null || conversation.lastMessageContent!.isEmpty) {
      return 'لا توجد رسائل بعد';
    }
    
    return conversation.lastMessageContent!.length > 30
        ? '${conversation.lastMessageContent!.substring(0, 30)}...'
        : conversation.lastMessageContent!;
  }

  String _formatTime(DateTime dateTime) {
    // إذا كانت الرسالة من نفس اليوم، نعرض الوقت فقط
    final now = DateTime.now();
    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
    
    // وإلا نعرض التاريخ
    return timeAgo(dateTime);
  }
}