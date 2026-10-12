import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project/region_extractor.dart';
import '../models/parapharmacy_model.dart';
import 'auth_service.dart';

class ParapharmacyService {
  final String baseUrl = 'http://10.0.2.2:3000'; // For Android emulator
  // Using the singleton instance of AuthService
  final AuthService _authService = AuthService();

  // Get all parapharmacies
  Future<List<Parapharmacy>> getParapharmacies() async {
    try {
      final uri = Uri.parse('$baseUrl/api/parapharmacies');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> parapharmaciesJson = data['parapharmacies'];
          final parapharmacies = parapharmaciesJson
              .map((json) => Parapharmacy.fromJson(json))
              .toList();

          // Extract regions from addresses if not already set
          for (var parapharmacy in parapharmacies) {
            if (parapharmacy.region == null || parapharmacy.region!.isEmpty) {
              parapharmacy.region = RegionExtractor.extractRegionFromAddress(
                  parapharmacy.address);
            }
          }

          return parapharmacies;
        } else {
          throw Exception('API returned error: ${data['message']}');
        }
      } else {
        throw Exception(
            'Failed to load parapharmacies: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching parapharmacies: $e');
      throw Exception('Failed to load parapharmacies: $e');
    }
  }

  // Get nearby parapharmacies for the authenticated user
  Future<List<Parapharmacy>> getNearbyParapharmaciesForUser() async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
        throw Exception('Authentication required to get nearby parapharmacies');
      }

      final uri = Uri.parse('$baseUrl/api/location/nearby-user');

      print('Fetching nearby parapharmacies with token: $token');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          final List<dynamic> parapharmaciesJson = data['parapharmacies'];
          final List<Parapharmacy> parapharmacies = [];

          for (var json in parapharmaciesJson) {
            try {
              // Create parapharmacy object from JSON
              final parapharmacy = Parapharmacy.fromJson(json);

              // Add to list
              parapharmacies.add(parapharmacy);
            } catch (e) {
              print('Error parsing parapharmacy: $e');
              print('Problematic JSON: $json');
            }
          }

          print(
              'Successfully parsed ${parapharmacies.length} nearby parapharmacies');
          return parapharmacies;
        } else {
          throw Exception('API returned error: ${data['message']}');
        }
      } else {
        throw Exception(
            'Failed to load nearby parapharmacies: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching nearby parapharmacies for user: $e');
      throw Exception('Failed to load nearby parapharmacies: $e');
    }
  }

  // Get a single parapharmacy by ID
  Future<Parapharmacy> getParapharmacyById(String id) async {
    try {
      final uri = Uri.parse('$baseUrl/api/parapharmacies/$id');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final parapharmacy = Parapharmacy.fromJson(data['parapharmacy']);

          // Extract region if not already set
          if (parapharmacy.region == null || parapharmacy.region!.isEmpty) {
            parapharmacy.region =
                RegionExtractor.extractRegionFromAddress(parapharmacy.address);
          }

          return parapharmacy;
        } else {
          throw Exception('API returned error: ${data['message']}');
        }
      } else {
        throw Exception('Failed to load parapharmacy: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching parapharmacy: $e');
      throw Exception('Failed to load parapharmacy: $e');
    }
  }

  // Search parapharmacies by name or address
  Future<List<Parapharmacy>> searchParapharmacies(String query) async {
    try {
      final uri = Uri.parse('$baseUrl/api/parapharmacies/search/$query');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> parapharmaciesJson = data['parapharmacies'];
          final parapharmacies = parapharmaciesJson
              .map((json) => Parapharmacy.fromJson(json))
              .toList();

          // Extract regions from addresses if not already set
          for (var parapharmacy in parapharmacies) {
            if (parapharmacy.region == null || parapharmacy.region!.isEmpty) {
              parapharmacy.region = RegionExtractor.extractRegionFromAddress(
                  parapharmacy.address);
            }
          }

          return parapharmacies;
        } else {
          throw Exception('API returned error: ${data['message']}');
        }
      } else {
        throw Exception(
            'Failed to search parapharmacies: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching parapharmacies: $e');
      throw Exception('Failed to search parapharmacies: $e');
    }
  }

  // Filter parapharmacies by name, region, and/or rating
  Future<List<Parapharmacy>> filterParapharmacies({
    String? name,
    String? region,
    double? minRating,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (name != null && name.isNotEmpty) {
        queryParams['name'] = name;
      }
      if (region != null && region.isNotEmpty && region != 'All') {
        queryParams['region'] = region;
      }
      if (minRating != null) {
        queryParams['minRating'] = minRating.toString();
      }

      final uri = Uri.parse('$baseUrl/api/parapharmacies/filter')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> parapharmaciesJson = data['parapharmacies'];
          final parapharmacies = parapharmaciesJson
              .map((json) => Parapharmacy.fromJson(json))
              .toList();

          // Extract regions from addresses if not already set
          for (var parapharmacy in parapharmacies) {
            if (parapharmacy.region == null || parapharmacy.region!.isEmpty) {
              parapharmacy.region = RegionExtractor.extractRegionFromAddress(
                  parapharmacy.address);
            }
          }

          return parapharmacies;
        } else {
          throw Exception('API returned error: ${data['message']}');
        }
      } else {
        throw Exception(
            'Failed to filter parapharmacies: ${response.statusCode}');
      }
    } catch (e) {
      print('Error filtering parapharmacies: $e');
      throw Exception('Failed to filter parapharmacies: $e');
    }
  }

  // Submit a review for a parapharmacy (requires authentication)
  Future<bool> submitReview(
      String parapharmacyId, double rating, String comment) async {
    try {
      // Make sure we have the latest user information
      await _authService.initialize();

      final token = await _authService.getToken();
      final userName = await _authService.getCurrentUsername();
      final userId = await _authService.getCurrentUserId();

      if (token == null || userId == null) {
        print('Authentication required to submit a review');
        return false;
      }

      print('Submitting review as: $userName (ID: $userId)');

      final response = await http.post(
        Uri.parse('$baseUrl/api/parapharmacies/$parapharmacyId/reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'rating': rating,
          'comment': comment,
          'user': userName,
          'userId': userId,
        }),
      );

      if (response.statusCode == 201) {
        final result = json.decode(response.body);
        print('Review submitted successfully: ${result['success']}');
        return result['success'] == true;
      }

      print('Failed to submit review: ${response.statusCode}');
      print('Response body: ${response.body}');
      return false;
    } catch (e) {
      print('Error submitting review: $e');
      return false;
    }
  }

  // Get reviews for a parapharmacy
  Future<List<Map<String, dynamic>>> getReviews(String parapharmacyId) async {
    try {
      final uri =
          Uri.parse('$baseUrl/api/parapharmacies/$parapharmacyId/reviews');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> reviewsJson = data['reviews'];
          final reviews = reviewsJson.cast<Map<String, dynamic>>();
          print('Fetched reviews: $reviews');
          return reviews;
        } else {
          throw Exception('API returned error: ${data['message']}');
        }
      } else {
        throw Exception('Failed to load reviews: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching reviews: $e');
      throw Exception('Failed to load reviews: $e');
    }
  }

  // NEW METHOD: Get reviews for the authenticated parapharmacy
  Future<Map<String, dynamic>> getMyParapharmacyReviews() async {
    try {
      // Make sure we have the latest user information
      await _authService.initialize();

      final token = await _authService.getToken();

      if (token == null) {
        print('Authentication required to get parapharmacy reviews');
        throw Exception('Authentication required');
      }

      final uri = Uri.parse('$baseUrl/api/my-parapharmacy/reviews');

      print(
          'Fetching reviews for authenticated parapharmacy with token: $token');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'parapharmacyName': data['parapharmacyName'],
            'parapharmacyId': data['parapharmacyId'],
            'reviews': data['reviews'],
            'count': data['count'],
          };
        } else {
          throw Exception('API returned error: ${data['message']}');
        }
      } else {
        throw Exception(
            'Failed to load parapharmacy reviews: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching parapharmacy reviews: $e');
      throw Exception('Failed to load parapharmacy reviews: $e');
    }
  }

  // Delete a review (requires authentication)
  Future<bool> deleteReview(String parapharmacyId, String reviewId) async {
    try {
      final token = await _authService.getToken();
      final userName = await _authService.getCurrentUsername();
      final userId = await _authService.getCurrentUserId();

      if (token == null) {
        print('Authentication required to delete a review');
        return false;
      }

      print('Deleting review with token: $token');
      print('Current user: $userName (ID: $userId)');
      print('Parapharmacy ID: $parapharmacyId, Review ID: $reviewId');

      final uri = Uri.parse(
          '$baseUrl/api/parapharmacies/$parapharmacyId/reviews/$reviewId');

      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Delete review response status: ${response.statusCode}');
      print('Delete review response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('Review deleted successfully: ${data['success']}');
        return data['success'] == true;
      } else {
        print('Failed to delete review: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting review: $e');
      return false;
    }
  }

  // Get coordinates for a parapharmacy
  Future<Map<String, dynamic>?> getParapharmacyCoordinates(
      String parapharmacyId) async {
    try {
      final url = Uri.parse(
          '$baseUrl/api/location/parapharmacy-coordinates/$parapharmacyId');
      print('Fetching coordinates from: $url');

      final response = await http.get(url);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsed coordinates: $data');
        return data;
      } else {
        print('Failed to get coordinates: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting parapharmacy coordinates: $e');
      return null;
    }
  }
}
