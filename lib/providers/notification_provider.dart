import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification.dart';
import '../api/api_service.dart';

class NotificationProvider with ChangeNotifier {
  final ApiService _apiService;
  List<AppNotification> _notifications = [];
  bool _loading = false;
  String? _error;
  int _unreadCount = 0;
  
  NotificationProvider(this._apiService) {
    _loadNotifications();
  }
  
  List<AppNotification> get notifications => _notifications;
  bool get loading => _loading;
  String? get error => _error;
  int get unreadCount => _unreadCount;
  
  // تحميل الإشعارات
  Future<void> _loadNotifications() async {
    _loading = true;
    notifyListeners();
    
    try {
      // في حالة وجود API للإشعارات
      // final response = await _apiService.getNotifications();
      
      // للتجربة، سنستخدم بيانات محلية محفوظة
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString('notifications');
      
      if (notificationsJson != null) {
        final List<dynamic> notificationsData = jsonDecode(notificationsJson);
        _notifications = notificationsData
            .map((data) => AppNotification.fromJson(data))
            .toList();
      }
      
      // حساب عدد الإشعارات غير المقروءة
      _calculateUnreadCount();
      
    } catch (e) {
      print('خطأ في تحميل الإشعارات: $e');
      _error = 'فشل في تحميل الإشعارات';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
  
  // حفظ الإشعارات محليًا
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = jsonEncode(
        _notifications.map((notification) => notification.toJson()).toList(),
      );
      await prefs.setString('notifications', notificationsJson);
    } catch (e) {
      print('خطأ في حفظ الإشعارات: $e');
    }
  }
  
  // حساب عدد الإشعارات غير المقروءة
  void _calculateUnreadCount() {
    _unreadCount = _notifications.where((notification) => !notification.isRead).length;
    notifyListeners();
  }
  
  // تعليم إشعار كمقروء
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((notification) => notification.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWithRead(isRead: true);
      _calculateUnreadCount();
      await _saveNotifications();
    }
  }
  
  // تعليم جميع الإشعارات كمقروءة
  Future<void> markAllAsRead() async {
    if (_notifications.any((notification) => !notification.isRead)) {
      _notifications = _notifications.map((notification) {
        return notification.isRead ? notification : notification.copyWithRead(isRead: true);
      }).toList();
      
      _unreadCount = 0;
      notifyListeners();
      await _saveNotifications();
    }
  }
  
  // إضافة إشعار جديد
  Future<void> addNotification(AppNotification notification) async {
    _notifications.insert(0, notification);
    _calculateUnreadCount();
    await _saveNotifications();
  }
  
  // إضافة إشعار إعجاب
  Future<void> addLikeNotification({
    required String recipientId,
    required String senderId,
    required String senderName,
    required String senderAvatar,
    required String postId,
  }) async {
    // التحقق من عدم وجود إشعار مشابه
    final hasExisting = _notifications.any((notification) => 
      notification.type == NotificationType.like &&
      notification.senderId == senderId &&
      notification.relatedItemId == postId &&
      !notification.isRead
    );
    
    if (!hasExisting) {
      final notification = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        recipientId: recipientId,
        senderId: senderId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        type: NotificationType.like,
        message: 'أعجب $senderName بمنشورك',
        relatedItemId: postId,
        createdAt: DateTime.now(),
      );
      
      await addNotification(notification);
    }
  }
  
  // إضافة إشعار تعليق
  Future<void> addCommentNotification({
    required String recipientId,
    required String senderId,
    required String senderName,
    required String senderAvatar,
    required String postId,
    required String commentText,
  }) async {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      recipientId: recipientId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      type: NotificationType.comment,
      message: '$senderName علق على منشورك: "${commentText.length > 30 ? commentText.substring(0, 30) + '...' : commentText}"',
      relatedItemId: postId,
      createdAt: DateTime.now(),
    );
    
    await addNotification(notification);
  }
  
  // إضافة إشعار متابعة
  Future<void> addFollowNotification({
    required String recipientId,
    required String senderId,
    required String senderName,
    required String senderAvatar,
  }) async {
    // التحقق من عدم وجود إشعار مشابه
    final hasExisting = _notifications.any((notification) => 
      notification.type == NotificationType.follow &&
      notification.senderId == senderId &&
      !notification.isRead
    );
    
    if (!hasExisting) {
      final notification = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        recipientId: recipientId,
        senderId: senderId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        type: NotificationType.follow,
        message: '$senderName بدأ متابعتك',
        createdAt: DateTime.now(),
      );
      
      await addNotification(notification);
    }
  }
  
  // إضافة إشعار رسالة
  Future<void> addMessageNotification({
    required String recipientId,
    required String senderId,
    required String senderName,
    required String senderAvatar,
    required String messageText,
    required String conversationId,
  }) async {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      recipientId: recipientId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      type: NotificationType.message,
      message: '$senderName أرسل لك رسالة: "${messageText.length > 30 ? messageText.substring(0, 30) + '...' : messageText}"',
      relatedItemId: conversationId,
      createdAt: DateTime.now(),
    );
    
    await addNotification(notification);
  }
  
  // تحديث/تحميل الإشعارات
  Future<void> refreshNotifications() async {
    await _loadNotifications();
  }
  
  // حذف إشعار
  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((notification) => notification.id == notificationId);
    _calculateUnreadCount();
    await _saveNotifications();
  }
  
  // حذف جميع الإشعارات
  Future<void> clearAllNotifications() async {
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
    await _saveNotifications();
  }
}