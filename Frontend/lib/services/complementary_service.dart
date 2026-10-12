import 'dart:convert';
import 'package:http/http.dart' as http;

class ComplementaryService {
  static const String _baseUrl = 'http://10.0.2.2:3000';

  // Get complementary products for a given product ID
  Future<List<Map<String, dynamic>>> getComplementaryProducts(
      String productId) async {
    try {
      final uri = Uri.parse(
          '$_baseUrl/api/complementary/products/$productId/complementary');

      print('Requesting complementary products for: $productId');
      print('URL: ${uri.toString()}');

      final response = await http.get(uri);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (!jsonData['success']) {
          throw Exception(
              jsonData['message'] ?? 'Failed to load complementary products');
        }

        final List<dynamic> productsJson = jsonData['complementaryProducts'];
        return List<Map<String, dynamic>>.from(productsJson);
      } else {
        try {
          final errorMessage = json.decode(response.body)['message'] ??
              'Failed to load complementary products';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception(
              'Failed to load complementary products: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error fetching complementary products: $e');
      throw Exception('Error fetching complementary products: $e');
    }
  }

  // Get detailed comparison for a specific product across all parapharmacies
  Future<Map<String, dynamic>> getDetailedProductComparison(
      String productName) async {
    try {
      final encodedName = Uri.encodeComponent(productName);
      final uri = Uri.parse(
          '$_baseUrl/api/complementary/products/$encodedName/detailed-comparison');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (!jsonData['success']) {
          throw Exception(
              jsonData['message'] ?? 'Failed to load product comparison');
        }

        return jsonData;
      } else {
        final errorMessage = json.decode(response.body)['message'] ??
            'Failed to load product comparison';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error fetching detailed product comparison: $e');
      throw Exception('Error fetching detailed product comparison: $e');
    }
  }
}
