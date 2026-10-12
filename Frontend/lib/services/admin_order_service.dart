import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminOrderService {
  final String baseUrl = 'http://10.0.2.2:3000/api'; // For Android emulator

  // Get token from shared preferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      debugPrint('No token found in SharedPreferences');
    } else {
      debugPrint('Token found in SharedPreferences');
    }

    return token;
  }

  // Check if user is a parapharmacy owner
  Future<bool> isParapharmacyOwner() async {
    try {
      final token = await _getToken();

      if (token == null) {
        return false;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final isParapharmacie = responseData['isParapharmacie'] ?? false;
        debugPrint('User is parapharmacy owner: $isParapharmacie');
        return isParapharmacie;
      } else {
        debugPrint('Failed to check parapharmacy status: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error checking parapharmacy status: $e');
      return false;
    }
  }

  // Get all orders for the parapharmacy
  Future<List<dynamic>> getParapharmacyOrders() async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Not authenticated');
      }

      debugPrint('Fetching parapharmacy orders...');
      final response = await http.get(
        Uri.parse('$baseUrl/admin/orders'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Orders API response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('Error response body: ${response.body}');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final orders = responseData['orders'] ?? [];
        debugPrint('Successfully fetched ${orders.length} orders');
        return orders;
      } else {
        final errorMessage =
            responseData['message'] ?? 'Failed to fetch orders';
        debugPrint('Error fetching orders: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Exception in getParapharmacyOrders: $e');
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

      debugPrint('Fetching details for order: $orderId');
      final response = await http.get(
        Uri.parse('$baseUrl/admin/orders/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Order details API response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('Error response body: ${response.body}');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final order = responseData['order'];
        debugPrint('Successfully fetched order details');
        return order;
      } else {
        final errorMessage =
            responseData['message'] ?? 'Failed to fetch order details';
        debugPrint('Error fetching order details: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Exception in getOrderDetails: $e');
      rethrow;
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Not authenticated');
      }

      debugPrint('Updating order $orderId status to: $status');
      final response = await http.put(
        Uri.parse('$baseUrl/admin/orders/$orderId/update-status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': status,
        }),
      );

      debugPrint('Update status API response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('Error response body: ${response.body}');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        debugPrint('Successfully updated order status');
        return true;
      } else {
        final errorMessage =
            responseData['message'] ?? 'Failed to update order status';
        debugPrint('Error updating order status: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Exception in updateOrderStatus: $e');
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
