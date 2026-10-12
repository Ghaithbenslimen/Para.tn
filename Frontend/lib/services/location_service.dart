import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';

class LocationService {
  static const String baseUrl = 'http://10.0.2.2:3000/api/location';

  // Get the auth token
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Update user location with manual coordinates
  static Future<bool> updateUserLocation(
      double latitude, double longitude, String address) async {
    final token = await _getToken();
    if (token == null) return false;

    final url = Uri.parse('$baseUrl/user-location');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
        }),
      );

      if (response.statusCode == 200) {
        print('Location updated successfully: ${response.body}');
        return true;
      } else {
        print('Failed to update location: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating user location: $e');
      return false;
    }
  }

  // Update parapharmacy location with manual coordinates
  static Future<bool> updateParapharmacyLocation(
      double latitude, double longitude) async {
    final token = await _getToken();
    if (token == null) return false;

    final url = Uri.parse('$baseUrl/parapharmacy-location');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode == 200) {
        print('Parapharmacy location updated successfully: ${response.body}');
        return true;
      } else {
        print('Failed to update parapharmacy location: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating parapharmacy location: $e');
      return false;
    }
  }

  // Get current location
  static Future<Map<String, dynamic>?> getCurrentLocation(
      BuildContext context) async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Location permissions are permanently denied, we cannot request permissions.'),
          ),
        );
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String address = '';
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        address = '${place.street}, ${place.locality}, ${place.country}';
      }

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': address,
      };
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
      return null;
    }
  }

  // Get address from coordinates
  static Future<String?> getAddressFromCoordinates(
      double latitude, double longitude, BuildContext context) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.country}';
      }
      return null;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting address: $e')),
      );
      return null;
    }
  }
}
