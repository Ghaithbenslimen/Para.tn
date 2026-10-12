import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class ProductService {
  // Update the baseUrl if needed.
  final String baseUrl = 'http://10.0.2.2:3000';

  // Cache for products to avoid unnecessary API calls
  List<Product> _cachedProducts = [];

  // Example categories list (if needed for other logic)
  List<String> categories = [
    'Moisturizers',
    'Skincare',
    'Cleansers',
    // Add more categories as required
  ];

  /// Get cached products or fetch if empty.
  List<Product> get products => _cachedProducts;

  /// Fetches all products from the API.
  Future<List<Product>> getProducts(String token) async {
    try {
      print('Fetching all products...');
      final uri = Uri.parse('$baseUrl/auth/products');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        print('Products API response: ${response.statusCode}');

        // Handle different response formats
        List<dynamic> productsJson;
        if (decoded is Map<String, dynamic> &&
            decoded.containsKey('products')) {
          productsJson = decoded['products'];
        } else if (decoded is List) {
          productsJson = decoded;
        } else {
          throw Exception('Unexpected response format');
        }

        _cachedProducts =
            productsJson.map((json) => _convertJsonToProduct(json)).toList();
        print('Fetched ${_cachedProducts.length} products');
        return _cachedProducts;
      } else {
        print('Failed to load products: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getProducts: $e');
      throw Exception('Error fetching products: $e');
    }
  }

  /// Fetches a specific product by ID directly from the API
  Future<Product> getProductById(String token, String productId) async {
    try {
      print('Fetching product by ID: $productId');

      // First check if the product is in the cache
      if (_cachedProducts.isNotEmpty) {
        try {
          final cachedProduct = _cachedProducts.firstWhere(
            (product) => product.id == productId,
          );
          print('Product found in cache: ${cachedProduct.name}');
          return cachedProduct;
        } catch (e) {
          print('Product not found in cache, will fetch from API');
        }
      }

      // If not in cache or cache is empty, fetch from API
      final uri = Uri.parse('$baseUrl/auth/products/$productId');
      print('Making API request to: ${uri.toString()}');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('API response status: ${response.statusCode}');
      print('API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle different response formats
        Map<String, dynamic> productJson;
        if (data is Map<String, dynamic>) {
          if (data.containsKey('product')) {
            productJson = data['product'];
          } else {
            productJson = data;
          }
        } else {
          throw Exception('Unexpected response format');
        }

        final product = _convertJsonToProduct(productJson);
        print('Successfully parsed product: ${product.name}');

        // Add to cache if not already there
        if (!_cachedProducts.any((p) => p.id == product.id)) {
          _cachedProducts.add(product);
        }

        return product;
      } else {
        print('API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load product: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getProductById: $e');
      throw Exception('Failed to get product: $e');
    }
  }

  /// Get monthly sales data (dummy data for now).
  List<Map<String, dynamic>> getMonthlySales() {
    return [
      {'month': 'Jan', 'sales': 1500},
      {'month': 'Feb', 'sales': 2200},
      {'month': 'Mar', 'sales': 1800},
      {'month': 'Apr', 'sales': 2400},
      {'month': 'May', 'sales': 2000},
      {'month': 'Jun', 'sales': 2800},
    ];
  }

  /// Get revenue by category (dummy data for demonstration).
  List<Map<String, dynamic>> getRevenueByCategory() {
    double total = 0;
    List<Map<String, dynamic>> result = [];

    for (int i = 0; i < categories.length; i++) {
      double revenue = (i + 1) * 1000.0;
      total += revenue;
      result.add({
        'category': categories[i],
        'revenue': revenue,
      });
    }

    // Calculate percentages based on total.
    for (var item in result) {
      item['percentage'] = (item['revenue'] / total) * 100;
    }

    return result;
  }

  /// Converts JSON response to a Product model.
  Product _convertJsonToProduct(Map<String, dynamic> json) {
    try {
      return Product(
        id: json['_id'] ?? '',
        name: json['name'] ?? '',
        category: json['category'] ?? '',
        price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
        quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
        description: json['description'] ?? '',
        howToUse: json['howToUse'] ?? '',
        interfaceAsiss: json['intelfaceassis'] ?? '',
        hasDiscount: json['hasDiscount'] ?? false,
        discountPercentage: json['discountPercentage'] != null
            ? double.tryParse(json['discountPercentage'].toString()) ?? 0.0
            : 0.0,
        imagePath: json['image'] ?? '',
        skinTypes: json['skinTypes'] != null
            ? List<String>.from(json['skinTypes'])
            : [],
      );
    } catch (e) {
      print('Error converting JSON to Product: $e');
      print('JSON data: $json');
      throw Exception('Error parsing product data: $e');
    }
  }

  /// Deletes a product by ID.
  Future<bool> deleteProduct(String productId, String token) async {
    final uri = Uri.parse('$baseUrl/auth/products/$productId');
    final response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      // Remove from cache if deleted successfully.
      _cachedProducts.removeWhere((product) => product.id == productId);
      return true;
    } else {
      print('Failed to delete product: ${response.statusCode}');
      print(response.body);
      return false;
    }
  }

  /// Sends a POST request to add a new product.
  Future<bool> addProduct(Product product, String token) async {
    final uri = Uri.parse('$baseUrl/auth/products');
    var request = http.MultipartRequest('POST', uri);

    // Add the authorization header.
    request.headers['Authorization'] = 'Bearer $token';

    // Add form fields.
    request.fields['name'] = product.name;
    request.fields['category'] = product.category;
    request.fields['price'] = product.price.toString();
    request.fields['quantity'] = product.quantity.toString();
    request.fields['hasDiscount'] = product.hasDiscount.toString();
    request.fields['discountPercentage'] =
        product.discountPercentage.toString();
    request.fields['description'] = product.description;
    request.fields['howToUse'] = product.howToUse;
    request.fields['intelfaceassis'] = product.interfaceAsiss;
    // Sending skinTypes as a JSON string.
    request.fields['skinTypes'] = jsonEncode(product.skinTypes);

    // Add the image file.
    var multipartFile = await http.MultipartFile.fromPath(
      'image',
      product.imagePath,
    );
    request.files.add(multipartFile);

    // Send the request.
    final response = await request.send();
    if (response.statusCode == 201) {
      print('Product added successfully');
      // Refresh the cache after adding.
      await getProducts(token);
      return true;
    } else {
      String responseBody = await response.stream.bytesToString();
      print('Failed to add product. Status code: ${response.statusCode}');
      print(responseBody);
      return false;
    }
  }

  /// Updates an existing product.
  Future<bool> updateProduct(Product product, String token,
      {File? newImageFile}) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/products/${product.id}');
      final request = http.MultipartRequest('PUT', uri);

      // Add the authorization header.
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields.
      request.fields['name'] = product.name;
      request.fields['category'] = product.category;
      request.fields['price'] = product.price.toString();
      request.fields['quantity'] = product.quantity.toString();
      request.fields['hasDiscount'] = product.hasDiscount.toString();
      request.fields['discountPercentage'] =
          product.discountPercentage.toString();
      request.fields['description'] = product.description;
      request.fields['howToUse'] = product.howToUse;
      request.fields['intelfaceassis'] = product.interfaceAsiss;
      // Sending skinTypes as a JSON string.
      request.fields['skinTypes'] = jsonEncode(product.skinTypes);

      // Add image file if provided.
      if (newImageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            newImageFile.path,
          ),
        );
      }

      // Send the request.
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        print('Product updated successfully');
        // Refresh the cache after updating.
        await getProducts(token);
        return true;
      } else {
        print('Failed to update product. Status code: ${response.statusCode}');
        print(responseBody);
        return false;
      }
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }

  /// Uploads a product image and returns the image path.
  Future<String?> uploadProductImage(File imageFile, String token) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/upload-product-image');
      final request = http.MultipartRequest('POST', uri);

      // Add the authorization header.
      request.headers['Authorization'] = 'Bearer $token';

      // Add the image file.
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final responseData = json.decode(responseBody);
        return responseData['imagePath'];
      } else {
        print('Failed to upload image: ${response.statusCode}');
        print(responseBody);
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
}
