// models/parapharmacy_model.dart
class Parapharmacy {
  final String id;
  final String name;
  final String address;
  final String description;
  final String imagePath;
  final String phone;
  final String email;
  String? region; // Region field
  final double rating; // Rating field
  String distance = ""; // Distance field (will be set by the API)
  double? latitude; // Latitude for location
  double? longitude; // Longitude for location

  Parapharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.description,
    required this.imagePath,
    required this.phone,
    required this.email,
    this.region,
    this.rating = 0.0,
    this.distance = "",
    this.latitude,
    this.longitude,
  });

  factory Parapharmacy.fromJson(Map<String, dynamic> json) {
    // Extract coordinates if available
    double? lat, lng;
    if (json['location'] != null &&
        json['location']['coordinates'] != null &&
        json['location']['coordinates'].length >= 2) {
      lng = json['location']['coordinates'][0]?.toDouble();
      lat = json['location']['coordinates'][1]?.toDouble();
    }

    // Extract distance if available
    String distance = "";
    if (json['distance'] != null) {
      distance = json['distance'].toString();
    }

    return Parapharmacy(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      description: json['description'] ?? '',
      imagePath: json['image'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      region: json['region'], // Extract region from JSON
      rating: json['rating']?.toDouble() ?? 0.0, // Extract rating from JSON
      distance: distance, // Extract distance if available
      latitude: lat,
      longitude: lng,
    );
  }
}
