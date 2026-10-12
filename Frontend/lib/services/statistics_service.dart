import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'package:flutter/foundation.dart';

class StatisticsService {
  final String baseUrl = 'http://10.0.2.2:3000';
  final AuthService _authService = AuthService();

  // Get statistics for the logged-in parapharmacy
  Future<Map<String, dynamic>> getMyStatistics() async {
    try {
      // Get token from AuthService
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // Check if user is a parapharmacy
      final isParapharmacie = await _authService.isParapharmacieUser();
      if (!isParapharmacie) {
        throw Exception('Only parapharmacies can access statistics');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/statistics/my-statistics'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Statistics response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('Failed to load statistics: ${response.body}');
        throw Exception('Failed to load statistics: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching statistics: $e');
      throw Exception('Error fetching statistics: $e');
    }
  }

  // Get statistics for a specific parapharmacy (for admin or same parapharmacy)
  Future<Map<String, dynamic>> getParapharmacyStatistics(
      String parapharmacyId) async {
    try {
      // Get token from AuthService
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/statistics/parapharmacy/$parapharmacyId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Statistics response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('Failed to load statistics: ${response.body}');
        throw Exception('Failed to load statistics: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching statistics: $e');
      throw Exception('Error fetching statistics: $e');
    }
  }

  // Get admin statistics (all parapharmacies)
  Future<Map<String, dynamic>> getAdminStatistics() async {
    try {
      // Get token from AuthService
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // Check if user is NOT a parapharmacy (admin)
      final isParapharmacie = await _authService.isParapharmacieUser();
      if (isParapharmacie) {
        throw Exception('Only admins can access all statistics');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/statistics/admin'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Admin statistics response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('Failed to load admin statistics: ${response.body}');
        throw Exception(
            'Failed to load admin statistics: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching admin statistics: $e');
      throw Exception('Error fetching admin statistics: $e');
    }
  }

  // Method to get monthly sales data for charts
  List<Map<String, dynamic>> getMonthlySales(Map<String, dynamic>? statistics) {
    if (statistics == null || !statistics.containsKey('monthlySales')) {
      // Return dummy data if no statistics available
      return [
        {'month': 'Jan', 'sales': '0'},
        {'month': 'Feb', 'sales': '0'},
        {'month': 'Mar', 'sales': '0'},
        {'month': 'Apr', 'sales': '0'},
        {'month': 'May', 'sales': '0'},
        {'month': 'Jun', 'sales': '0'},
      ];
    }

    return List<Map<String, dynamic>>.from(statistics['monthlySales']);
  }

  // Method to get revenue by category for charts
  List<Map<String, dynamic>> getRevenueByCategory(
      Map<String, dynamic>? statistics) {
    if (statistics == null || !statistics.containsKey('categorySales')) {
      // Return dummy data if no statistics available
      return [
        {'category': 'Moisturizers', 'revenue': 0, 'percentage': '0'},
        {'category': 'Cleansers', 'revenue': 0, 'percentage': '0'},
        {'category': 'Sunscreens', 'revenue': 0, 'percentage': '0'},
      ];
    }

    return List<Map<String, dynamic>>.from(statistics['categorySales']);
  }

  // Method to get top products
  List<Map<String, dynamic>> getTopProducts(Map<String, dynamic>? statistics) {
    if (statistics == null || !statistics.containsKey('topProducts')) {
      return [];
    }

    return List<Map<String, dynamic>>.from(statistics['topProducts']);
  }
}
