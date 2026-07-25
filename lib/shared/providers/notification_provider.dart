import 'dart:async';
import 'package:flutter_lms/shared/models/notification_model.dart';
import 'package:flutter_lms/shared/services/notification_service.dart';
import 'feature_provider.dart';

class NotificationProvider extends FeatureProvider {
  final NotificationService _notificationService;
  
  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;
  
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  Timer? _pollingTimer;

  NotificationProvider(this._notificationService);

  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      fetchUnreadCount();
    });
    fetchUnreadCount(); // Fetch immediately when starting
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  Future<void> fetchNotifications() async {
    final result = await run(() => _notificationService.fetchNotifications());
    if (result != null) {
      _notifications = result;
      _updateUnreadCountFromList();
      notifyListeners();
    }
  }

  Future<void> fetchUnreadCount() async {
    final count = await run(() => _notificationService.fetchUnreadCount());
    if (count != null && count != _unreadCount) {
      _unreadCount = count;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    final result = await run(() => _notificationService.markAsRead(id));
    if (result != null) {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = result;
        _updateUnreadCountFromList();
        notifyListeners();
      } else {
        // If we don't have the full list loaded, just decrement the count if it was unread
        fetchUnreadCount();
      }
    }
  }

  Future<void> markAllAsRead() async {
    await run(() => _notificationService.markAllAsRead());
    if (errorMessage == null) {
      for (int i = 0; i < _notifications.length; i++) {
        final n = _notifications[i];
        _notifications[i] = NotificationModel(
          id: n.id,
          userId: n.userId,
          title: n.title,
          message: n.message,
          isRead: true,
          type: n.type,
          link: n.link,
          createdAt: n.createdAt,
        );
      }
      _unreadCount = 0;
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String id) async {
    await run(() => _notificationService.deleteNotification(id));
    if (errorMessage == null) {
      _notifications.removeWhere((n) => n.id == id);
      _updateUnreadCountFromList();
      notifyListeners();
    }
  }

  void _updateUnreadCountFromList() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
