import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'package:flutter/foundation.dart';

class DashboardService {
  final String baseUrl = 'http://10.0.2.2:3000';
  final AuthService _authService = AuthService();

  // Get dashboard statistics for the logged-in parapharmacy
  Future<Map<String, dynamic>> getDashboardStatistics() async {
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

      debugPrint(
          'Dashboard statistics response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('Failed to load dashboard statistics: ${response.body}');
        throw Exception(
            'Failed to load dashboard statistics: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching dashboard statistics: $e');
      throw Exception('Error fetching dashboard statistics: $e');
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
}
