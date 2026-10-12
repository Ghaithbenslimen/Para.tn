import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/cart_service.dart';
import '../models/order.dart';

class CommandService {
  final String baseUrl = 'http://10.0.2.2:3000/api'; // For Android emulator
  final CartService _cartService = CartService();

  // Get token from shared preferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Create a new order - now supports multiple parapharmacies
  Future<Map<String, dynamic>> createOrder({
    required Map<String, dynamic> shippingAddress,
    String paymentMethod = 'cash_on_delivery',
  }) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Get cart items
      final cartItems = _cartService.items;

      if (cartItems.isEmpty) {
        throw Exception('Cart is empty');
      }

      // Format products for the API
      final List<Map<String, dynamic>> products = cartItems.map((item) {
        return {
          'productId': item.id,
          'quantity': item.quantity,
        };
      }).toList();

      final response = await http.post(
        Uri.parse('$baseUrl/commands'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'products': products,
          'shippingAddress': shippingAddress,
          'paymentMethod': paymentMethod,
        }),
      );

      final responseData = jsonDecode(response.body);
      print("Create order response: $responseData");

      if (response.statusCode == 201) {
        // Clear cart after successful order
        _cartService.clearCart();

        // Handle both single command and multiple commands responses
        if (responseData.containsKey('commands') &&
            responseData['commands'] is List &&
            responseData['commands'].isNotEmpty) {
          // Return the first command ID for backward compatibility
          return {
            'command': responseData['commands'][0],
            'allCommands': responseData['commands'],
            'commandId':
                responseData['commandId'] ?? responseData['commands'][0]['_id'],
          };
        } else if (responseData.containsKey('command')) {
          return responseData;
        } else {
          return {'command': responseData};
        }
      } else {
        throw Exception(responseData['message'] ?? 'Failed to create order');
      }
    } catch (e) {
      print("Error in createOrder: $e");
      rethrow;
    }
  }

  // Get all orders for the current user
  Future<List<dynamic>> getOrders() async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/commands'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);
      print("Get orders response: $responseData");

      if (response.statusCode == 200) {
        if (responseData.containsKey('commands') &&
            responseData['commands'] is List) {
          return responseData['commands'];
        } else if (responseData is List) {
          return responseData;
        } else {
          return [];
        }
      } else {
        throw Exception(responseData['message'] ?? 'Failed to fetch orders');
      }
    } catch (e) {
      print("Error in getOrders: $e");
      rethrow;
    }
  }

  // Get order details by ID - now includes related orders from other parapharmacies
  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/commands/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);
      print("Get order details response: $responseData");

      if (response.statusCode == 200) {
        if (responseData.containsKey('command')) {
          return responseData;
        } else if (responseData.containsKey('success') &&
            responseData['success'] == true) {
          // Handle different response structures
          if (responseData.containsKey('command')) {
            return {
              'command': responseData['command'],
              'relatedCommands': responseData['relatedCommands'] ?? [],
            };
          } else {
            return {'command': responseData};
          }
        } else {
          return responseData;
        }
      } else {
        throw Exception(
            responseData['message'] ?? 'Failed to fetch order details');
      }
    } catch (e) {
      print("Error in getOrderDetails: $e");
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
        Uri.parse('$baseUrl/commands/$orderId/cancel'),
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
      print("Error in cancelOrder: $e");
      rethrow;
    }
  }

  // New method to cancel all related orders
  Future<bool> cancelAllRelatedOrders(List<String> orderIds) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Not authenticated');
      }

      bool allSuccessful = true;

      for (String orderId in orderIds) {
        final response = await http.put(
          Uri.parse('$baseUrl/commands/$orderId/cancel'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode != 200) {
          allSuccessful = false;
        }
      }

      return allSuccessful;
    } catch (e) {
      print("Error in cancelAllRelatedOrders: $e");
      rethrow;
    }
  }
}
