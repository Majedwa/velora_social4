import 'package:flutter/material.dart';
import '../../models/notification.dart';
import '../../utils/time_util.dart';
import '../common/network_image.dart';

class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationTile({
    Key? key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
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
        color: notification.isRead 
            ? Theme.of(context).scaffoldBackgroundColor 
            : Theme.of(context).primaryColor.withOpacity(0.1),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // أيقونة نوع الإشعار
                _buildNotificationTypeIcon(notification.type, context),
                const SizedBox(width: 12),
                
                // صورة المرسل
                if (notification.senderAvatar != null)
                  ClipOval(
                    child: NetworkImageWithPlaceholder(
                      imageUrl: notification.senderAvatar!,
                      width: 40,
                      height: 40,
                    ),
                  )
                else
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                const SizedBox(width: 12),
                
                // محتوى الإشعار
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontWeight: !notification.isRead 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeAgo(notification.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // مؤشر غير مقروء
                if (!notification.isRead)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTypeIcon(NotificationType type, BuildContext context) {
    IconData iconData;
    Color iconColor;
    
    switch (type) {
      case NotificationType.like:
        iconData = Icons.favorite;
        iconColor = Colors.red;
        break;
      case NotificationType.comment:
        iconData = Icons.comment;
        iconColor = Colors.orange;
        break;
      case NotificationType.follow:
        iconData = Icons.person_add;
        iconColor = Colors.blue;
        break;
      case NotificationType.mention:
        iconData = Icons.alternate_email;
        iconColor = Colors.purple;
        break;
      case NotificationType.message:
        iconData = Icons.message;
        iconColor = Colors.green;
        break;
      case NotificationType.system:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }
}