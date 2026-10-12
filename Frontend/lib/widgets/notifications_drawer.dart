import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project/services/notification_service.dart';
import 'package:project/services/auth_service.dart';

class NotificationsDrawer extends StatefulWidget {
  // Add callback for product notification tap
  final Function(String productId, String productName)?
      onProductNotificationTap;

  const NotificationsDrawer({
    Key? key,
    this.onProductNotificationTap,
  }) : super(key: key);

  @override
  _NotificationsDrawerState createState() => _NotificationsDrawerState();
}

class _NotificationsDrawerState extends State<NotificationsDrawer> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication().then((_) {
      _loadNotifications();
    });
  }

  Future<void> _checkAuthentication() async {
    try {
      final isAuthenticated = await _authService.isAuthenticated();
      setState(() {
        _isAuthenticated = isAuthenticated;
      });
    } catch (e) {
      print('Error checking authentication: $e');
    }
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final notifications = await _notificationService.getUserNotifications();

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load notifications: $e';
      });
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead || !_isAuthenticated) return;

    try {
      final success = await _notificationService.markAsRead(notification.id);
      if (success) {
        setState(() {
          // Update the local notification to show as read
          final index = _notifications.indexOf(notification);
          if (index != -1) {
            _notifications[index] = AppNotification(
              id: notification.id,
              title: notification.title,
              message: notification.message,
              type: notification.type,
              sender: notification.sender,
              senderName: notification.senderName,
              productId: notification.productId,
              productName: notification.productName,
              productImage: notification.productImage,
              createdAt: notification.createdAt,
              isRead: true,
            );
          }
        });
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _clearAllNotifications() async {
    if (!_isAuthenticated) {
      _showLoginRequiredDialog();
      return;
    }

    try {
      final success = await _notificationService.clearAllNotifications();
      if (success) {
        await _loadNotifications();
      }
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Login Required'),
        content: Text(
            'You need to login to mark notifications as read or clear them.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/welcome').then((_) {
                _checkAuthentication();
                _loadNotifications();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: Text('Login'),
          ),
        ],
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'promotion':
        return Colors.orange;
      case 'update':
        return Colors.blue;
      case 'reminder':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'promotion':
        return Icons.local_offer;
      case 'update':
        return Icons.update;
      case 'reminder':
        return Icons.alarm;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Spacer(),
            ],
          ),
        ),

        // Login banner for non-authenticated users
        if (!_isAuthenticated && _notifications.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.orange[100],
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[800], size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Login to mark notifications as read and see personalized updates.',
                    style: TextStyle(color: Colors.orange[800]),
                  ),
                ),
              ],
            ),
          ),

        // Notifications List
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.green))
              : _errorMessage.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 48, color: Colors.red),
                          SizedBox(height: 16),
                          Text(_errorMessage),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadNotifications,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _notifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_off,
                                  size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No notifications yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Check back later for updates',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadNotifications,
                          color: Colors.green,
                          child: ListView.builder(
                            itemCount: _notifications.length,
                            itemBuilder: (context, index) {
                              final notification = _notifications[index];
                              return _buildNotificationItem(notification);
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildNotificationItem(AppNotification notification) {
    final hasProduct = notification.productId.isNotEmpty &&
        notification.productName.isNotEmpty;

    return InkWell(
      onTap: () {
        // Mark notification as read if authenticated
        if (_isAuthenticated) {
          _markAsRead(notification);
        }

        // If it's a product notification and we have a callback, navigate to product
        // directly without showing any login prompt
        if (hasProduct && widget.onProductNotificationTap != null) {
          widget.onProductNotificationTap!(
              notification.productId, notification.productName);
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isAuthenticated && notification.isRead
              ? Colors.white
              : Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isAuthenticated && notification.isRead
                ? Colors.grey[300]!
                : Colors.green[300]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: _getNotificationColor(notification.type),
                  radius: 20,
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: _isAuthenticated && notification.isRead
                                    ? Colors.black87
                                    : Colors.green[800],
                              ),
                            ),
                          ),
                          if (_isAuthenticated && !notification.isRead)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          color: Colors.grey[700],
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 4),
                      // Add the sender name display here
                      if (notification.senderName.isNotEmpty)
                        Text(
                          'From: ${notification.senderName}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            DateFormat('MMM d, yyyy • h:mm a')
                                .format(notification.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Product information (if available)
            if (hasProduct) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    if (notification.productImage.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          notification.productImage,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[200],
                              child: Icon(Icons.image_not_supported,
                                  color: Colors.grey),
                            );
                          },
                        ),
                      )
                    else
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.shopping_bag, color: Colors.orange),
                      ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.productName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap to view product details',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.orange[800],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
