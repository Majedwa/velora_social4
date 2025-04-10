import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notification.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/notification/notification_tile.dart';
import '../../screens/post/post_detail_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/chat/conversation_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    // تحميل الإشعارات عند فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).refreshNotifications();
    });
  }

  void _handleNotificationTap(AppNotification notification) {
    // تعليم الإشعار كمقروء
    Provider.of<NotificationProvider>(context, listen: false)
        .markAsRead(notification.id);

    // التنقل حسب نوع الإشعار
    switch (notification.type) {
      case NotificationType.like:
      case NotificationType.comment:
        if (notification.relatedItemId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(
                postId: notification.relatedItemId!,
              ),
            ),
          );
        }
        break;
      case NotificationType.follow:
        if (notification.senderId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(
                userId: notification.senderId!,
              ),
            ),
          );
        }
        break;
      case NotificationType.message:
        if (notification.senderId != null && notification.relatedItemId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConversationScreen(
                conversationId: notification.relatedItemId!,
                otherUserId: notification.senderId!,
                otherUserName: notification.senderName ?? 'مستخدم',
                otherUserAvatar: notification.senderAvatar ?? '',
              ),
            ),
          );
        }
        break;
      case NotificationType.mention:
      case NotificationType.system:
        // يمكن تنفيذ سلوكيات أخرى هنا
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          // زر تعليم جميع الإشعارات كمقروءة
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () {
              Provider.of<NotificationProvider>(context, listen: false)
                  .markAllAsRead();
            },
            tooltip: 'تعليم الكل كمقروء',
          ),
          // زر مسح جميع الإشعارات
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('مسح الإشعارات'),
                    content: const Text('هل أنت متأكد من رغبتك في مسح جميع الإشعارات؟'),
                    actions: [
                      TextButton(
                        child: const Text('إلغاء'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      TextButton(
                        child: const Text('مسح'),
                        onPressed: () {
                          Provider.of<NotificationProvider>(context, listen: false)
                              .clearAllNotifications();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
            tooltip: 'مسح الكل',
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          if (notificationProvider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (notificationProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('حدث خطأ: ${notificationProvider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => notificationProvider.refreshNotifications(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          if (notificationProvider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ليس لديك إشعارات حاليًا',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ستظهر هنا إشعارات الإعجابات والتعليقات والمتابعين',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => notificationProvider.refreshNotifications(),
            child: ListView.separated(
              itemCount: notificationProvider.notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = notificationProvider.notifications[index];
                return NotificationTile(
                  notification: notification,
                  onTap: () => _handleNotificationTap(notification),
                  onDismiss: () => notificationProvider.deleteNotification(notification.id),
                );
              },
            ),
          );
        },
      ),
    );
  }
}