import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TrackOrderService {
  final String baseUrl = 'http://10.0.2.2:3000/api'; // For Android emulator

  // Get token from shared preferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Get all orders for the current user
  Future<List<dynamic>> getOrders() async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/track-orders'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData['orders'];
      } else {
        throw Exception(responseData['message'] ?? 'Failed to fetch orders');
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      rethrow;
    }
  }

  // Get order details by ID
  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/track-orders/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData['order'];
      } else {
        throw Exception(
            responseData['message'] ?? 'Failed to fetch order details');
      }
    } catch (e) {
      debugPrint('Error fetching order details: $e');
      rethrow;
    }
  }

  // Cancel an order
  Future<bool> cancelOrder(String orderId) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/track-orders/$orderId/cancel'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to cancel order');
      }
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      rethrow;
    }
  }

  // Helper method to get status color
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper method to get status icon
  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'processing':
        return Icons.sync;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  // Helper method to format date
  static String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return 'Invalid date';
    }
  }
}
