import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import 'auth_service.dart';

class WishlistService {
  final String baseUrl =
      'http://10.0.2.2:3000'; // Android emulator address for localhost
  final AuthService _authService = AuthService();

  // Get all wishlist items
  Future<List<Product>> getWishlist() async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/wishlist'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['wishlist'] != null) {
          // Process each product to ensure image paths are complete URLs
          final products = List<Product>.from(data['wishlist'].map((item) {
            // If image path doesn't start with http, prepend the base URL
            if (item['image'] != null &&
                !item['image'].toString().startsWith('http')) {
              // Replace backslashes with forward slashes for URLs
              String imagePath = item['image'].toString().replaceAll('\\', '/');
              item['image'] = '$baseUrl/$imagePath';
            }
            return Product.fromJson(item);
          }));
          return products;
        }
        return [];
      } else {
        throw Exception('Failed to load wishlist: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting wishlist: $e');
      return [];
    }
  }

  // Add product to wishlist
  Future<bool> addToWishlist(String productId) async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/wishlist/add/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error adding to wishlist: $e');
      return false;
    }
  }

  // Remove product from wishlist
  Future<bool> removeFromWishlist(String productId) async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/wishlist/remove/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error removing from wishlist: $e');
      return false;
    }
  }

  // Check if product is in wishlist
  Future<bool> isInWishlist(String productId) async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        return false; // Not authenticated, so not in wishlist
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/wishlist/check/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['isInWishlist'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking wishlist status: $e');
      return false;
    }
  }

  // Helper method to get full image URL
  String getFullImageUrl(String imagePath) {
    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    // Replace backslashes with forward slashes for URLs
    String formattedPath = imagePath.replaceAll('\\', '/');
    return '$baseUrl/$formattedPath';
  }
}
