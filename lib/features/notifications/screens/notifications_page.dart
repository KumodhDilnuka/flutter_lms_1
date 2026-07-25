import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/shared/providers/notification_provider.dart';
import 'package:flutter_lms/shared/models/notification_model.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    await context.read<NotificationProvider>().fetchNotifications();
    if (mounted) setState(() => _isLoading = false);
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  void _handleTap(NotificationModel notification) async {
    if (!notification.isRead) {
      await context.read<NotificationProvider>().markAsRead(notification.id);
    }
    
    if (notification.link != null && notification.link!.isNotEmpty) {
      final uri = Uri.tryParse(notification.link!);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () {
              context.read<NotificationProvider>().markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All marked as read')));
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No notifications yet.', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _fetchNotifications,
            child: ListView.separated(
              itemCount: provider.notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return Dismissible(
                  key: Key(notification.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    provider.deleteNotification(notification.id);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification deleted')));
                  },
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    tileColor: notification.isRead ? null : Colors.blue.withValues(alpha: 0.05),
                    leading: CircleAvatar(
                      backgroundColor: notification.isRead ? Colors.grey.shade200 : Colors.blue.shade100,
                      child: Icon(
                        notification.type == 'enrollment' ? Icons.school :
                        notification.type == 'assignment' ? Icons.assignment :
                        notification.type == 'review' ? Icons.star :
                        Icons.notifications,
                        color: notification.isRead ? Colors.grey.shade600 : Colors.blue.shade700,
                      ),
                    ),
                    title: Text(
                      notification.title,
                      style: TextStyle(fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notification.message),
                        const SizedBox(height: 8),
                        Text(
                          _formatTime(notification.createdAt),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    onTap: () => _handleTap(notification),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
