import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

// Renamed from Notification to AppNotification to avoid conflict with Flutter's Notification class
class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final String sender;
  final String senderName;
  final String productId;
  final String productName;
  final String productImage;
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.sender,
    required this.senderName,
    this.productId = '',
    this.productName = '',
    this.productImage = '',
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'general',
      sender: json['sender'] ?? '',
      senderName: json['senderName'] ?? 'Parapharmacy',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      productImage: json['productImage'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isRead: json['isReadByUser'] ?? false,
    );
  }
}

class NotificationService {
  final String baseUrl = 'http://10.0.2.2:3000';
  final AuthService _authService = AuthService();

  // Stream controller for real-time notification updates
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal() {
    // Initialize unread count
    getUnreadCount().then((count) {
      unreadCountNotifier.value = count;
    });
  }

  // Get all notifications for the current user
  Future<List<AppNotification>> getUserNotifications() async {
    try {
      final token = await _authService.getToken();
      final isAuthenticated = token != null;

      if (isAuthenticated) {
        // Authenticated user - get personalized notifications
        final response = await http.get(
          Uri.parse('$baseUrl/api/notifications/user'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          final notifications =
              data.map((json) => AppNotification.fromJson(json)).toList();

          // Update unread count
          final unreadCount = notifications.where((n) => !n.isRead).length;
          unreadCountNotifier.value = unreadCount;

          return notifications;
        } else {
          debugPrint('Failed to load notifications: ${response.body}');
          // Fall back to public notifications if user endpoint fails
          return getPublicNotifications();
        }
      } else {
        // Non-authenticated user - get public notifications
        return getPublicNotifications();
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      // Try to get public notifications as fallback
      return getPublicNotifications();
    }
  }

  // Get public notifications (no authentication required)
  Future<List<AppNotification>> getPublicNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/public'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final notifications =
            data.map((json) => AppNotification.fromJson(json)).toList();

        // For public view, we'll set the unread count to the total number
        // since we can't track read status for non-authenticated users
        unreadCountNotifier.value = notifications.length;

        return notifications;
      } else {
        debugPrint('Failed to load public notifications: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching public notifications: $e');
      return [];
    }
  }

  // Get all notifications for the parapharmacie (admin)
  Future<List<AppNotification>> getAdminNotifications() async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        debugPrint('No token available, user not authenticated');
        return [];
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/admin'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => AppNotification.fromJson(json)).toList();
      } else {
        debugPrint('Failed to load admin notifications: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching admin notifications: $e');
      return [];
    }
  }

  // Create a new notification (admin only)
  Future<bool> createNotification({
    required String title,
    required String message,
    String type = 'general',
    String recipients = 'all',
    List<String> specificUsers = const [],
    String? productId,
    String? productName,
    String? productImage,
  }) async {
    try {
      final token = await _authService.getToken();
      final username = await _authService.getCurrentUsername();

      if (token == null) {
        debugPrint('No token available, user not authenticated');
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'title': title,
          'message': message,
          'type': type,
          'recipients': recipients,
          'specificUsers': specificUsers,
          'productId': productId,
          'productName': productName,
          'productImage': productImage,
          'senderName': username,
        }),
      );

      if (response.statusCode == 201) {
        debugPrint('Notification created successfully');
        return true;
      } else {
        debugPrint('Failed to create notification: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error creating notification: $e');
      return false;
    }
  }

  // Mark a notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        debugPrint('No token available, user not authenticated');
        return false;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/notifications/read/$notificationId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('Notification marked as read');

        // Update unread count after marking as read
        getUnreadCount().then((count) {
          unreadCountNotifier.value = count;
        });

        return true;
      } else {
        debugPrint('Failed to mark notification as read: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  // Delete a notification (admin only)
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        debugPrint('No token available, user not authenticated');
        return false;
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/notifications/$notificationId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('Notification deleted successfully');
        return true;
      } else {
        debugPrint('Failed to delete notification: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
    }
  }

  // Clear all notifications for the current user - FIXED: Changed from DELETE to PUT method
  Future<bool> clearAllNotifications() async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        debugPrint('No token available, user not authenticated');
        return false;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/notifications/clear-all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('All notifications cleared successfully');

        // Update unread count after clearing
        unreadCountNotifier.value = 0;

        return true;
      } else {
        debugPrint(
            'Failed to clear notifications: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
      return false;
    }
  }

  // Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        debugPrint('No token available, user not authenticated');
        // For non-authenticated users, we'll get the count of public notifications
        final publicNotifications = await getPublicNotifications();
        return publicNotifications.length;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/unread-count'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final count = data['unreadCount'] ?? 0;
        unreadCountNotifier.value = count;
        return count;
      } else {
        debugPrint('Failed to get unread count: ${response.body}');
        return 0;
      }
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  // Check if user can mark notifications as read (only authenticated users)
  Future<bool> canMarkAsRead() async {
    final token = await _authService.getToken();
    return token != null;
  }
}
