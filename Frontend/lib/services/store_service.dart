import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../models/parapharmacy_model.dart';

class StoreService {
  // Using the emulator IP and port directly
  static const String _baseUrl = 'http://10.0.2.2:3000';

  // Getter for the base URL to use in other services
  String get baseUrl => _baseUrl;

  // Get products for a specific parapharmacy with optional filters
  Future<List<Product>> getParapharmacyProducts({
    required String parapharmacyId,
    String? category,
    String? skinType,
    String? sortBy,
    String? search,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (category != null && category != 'All')
        queryParams['category'] = category;
      if (skinType != null && skinType != 'All')
        queryParams['skinType'] = skinType;
      if (search != null && search.trim().isNotEmpty)
        queryParams['search'] = search;

      // Map the UI sort options to backend sort options
      if (sortBy != null) {
        switch (sortBy) {
          case 'Popular':
            queryParams['sortBy'] = 'popular';
            break;
          case 'Price: Low to High':
            queryParams['sortBy'] = 'low';
            break;
          case 'Price: High to Low':
            queryParams['sortBy'] = 'high';
            break;
          case 'Newest':
            queryParams['sortBy'] = 'newest';
            break;
          default:
            queryParams['sortBy'] = sortBy.toLowerCase();
        }
      }

      // Build URL with query parameters
      final uri =
          Uri.parse('$_baseUrl/api/store/parapharmacy/$parapharmacyId/products')
              .replace(queryParameters: queryParams);

      print('Requesting: ${uri.toString()}');

      // Make the HTTP request
      final response = await http.get(uri);

      // Check if the request was successful
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // Debug: Print the response
        print('Response: ${response.body}');

        if (!jsonData['success']) {
          throw Exception(jsonData['message'] ?? 'Failed to load products');
        }

        final List<dynamic> productsJson = jsonData['products'];

        // Convert JSON to Product objects
        return productsJson.map((json) => Product.fromJson(json)).toList();
      } else {
        // Handle error response
        try {
          final errorMessage = json.decode(response.body)['message'] ??
              'Failed to load products';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('Failed to load products: ${response.statusCode}');
        }
      }
    } catch (e) {
      // Handle any exceptions
      print('Error fetching products: $e');
      throw Exception('Error fetching products: $e');
    }
  }

  // Search products by name across all parapharmacies
  Future<List<Product>> searchProducts(String query) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      final uri = Uri.parse('$_baseUrl/api/store/products/search')
          .replace(queryParameters: {'query': query});

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (!jsonData['success']) {
          throw Exception(jsonData['message'] ?? 'Failed to search products');
        }

        final List<dynamic> productsJson = jsonData['products'];
        return productsJson.map((json) => Product.fromJson(json)).toList();
      } else {
        final errorMessage = json.decode(response.body)['message'] ??
            'Failed to search products';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error searching products: $e');
      throw Exception('Error searching products: $e');
    }
  }

  // Get detailed product information by ID
  Future<Product> getProductDetails(String productId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/store/products/$productId'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (!jsonData['success']) {
          throw Exception(
              jsonData['message'] ?? 'Failed to load product details');
        }

        return Product.fromJson(jsonData['product']);
      } else {
        final errorMessage = json.decode(response.body)['message'] ??
            'Failed to load product details';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error fetching product details: $e');
      throw Exception('Error fetching product details: $e');
    }
  }

  // Compare product prices across different parapharmacies
  Future<List<Map<String, dynamic>>> compareProductPrices(
      String productName) async {
    try {
      final encodedName = Uri.encodeComponent(productName);
      final response = await http.get(
        Uri.parse('$_baseUrl/api/store/products/$encodedName/compare'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (!jsonData['success']) {
          throw Exception(jsonData['message'] ?? 'Failed to compare prices');
        }

        return List<Map<String, dynamic>>.from(jsonData['comparisons']);
      } else {
        final errorMessage =
            json.decode(response.body)['message'] ?? 'Failed to compare prices';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error comparing product prices: $e');
      throw Exception('Error comparing product prices: $e');
    }
  }

  // Get filter options (categories and skin types)
  Future<Map<String, List<String>>> getFilterOptions() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/store/filters'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (!jsonData['success']) {
          throw Exception(
              jsonData['message'] ?? 'Failed to load filter options');
        }

        // Convert the JSON response to a map of filter options
        return {
          'categories': List<String>.from(jsonData['categories']),
          'skinTypes': List<String>.from(jsonData['skinTypes']),
        };
      } else {
        final errorMessage = json.decode(response.body)['message'] ??
            'Failed to load filter options';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error fetching filter options: $e');
      throw Exception('Error fetching filter options: $e');
    }
  }

  // Get categories for a specific parapharmacy
  Future<List<String>> getParapharmacyCategories(String parapharmacyId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/api/store/categories/parapharmacy/$parapharmacyId'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (!jsonData['success']) {
          throw Exception(jsonData['message'] ?? 'Failed to load categories');
        }

        return List<String>.from(jsonData['categories']);
      } else {
        final errorMessage = json.decode(response.body)['message'] ??
            'Failed to load categories';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error fetching parapharmacy categories: $e');
      throw Exception('Error fetching parapharmacy categories: $e');
    }
  }

  // Get skin types for a specific parapharmacy
  Future<List<String>> getParapharmacySkinTypes(String parapharmacyId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/api/store/skin-types/parapharmacy/$parapharmacyId'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (!jsonData['success']) {
          throw Exception(jsonData['message'] ?? 'Failed to load skin types');
        }

        return List<String>.from(jsonData['skinTypes']);
      } else {
        final errorMessage = json.decode(response.body)['message'] ??
            'Failed to load skin types';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error fetching parapharmacy skin types: $e');
      throw Exception('Error fetching parapharmacy skin types: $e');
    }
  }

  // Helper method to get the full image URL
  String getFullImageUrl(String imagePath) {
    if (imagePath.isEmpty) return '';

    // If it's already a full URL, return it as is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // Otherwise, prepend the base URL
    // Replace backslashes with forward slashes for URL compatibility
    final normalizedPath = imagePath.replaceAll('\\', '/');
    return '$_baseUrl/$normalizedPath';
  }
}
