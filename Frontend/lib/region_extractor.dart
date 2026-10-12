// utils/region_extractor.dart
class RegionExtractor {
  // List of Tunisian regions
  static final List<String> _tunisianRegions = [
    'Ariana',
    'Béja',
    'Ben Arous',
    'Bizerte',
    'Gabès',
    'Gafsa',
    'Jendouba',
    'Kairouan',
    'Kasserine',
    'Kébili',
    'Kef',
    'Mahdia',
    'Manouba',
    'Médenine',
    'Monastir',
    'Nabeul',
    'Sfax',
    'Sidi Bouzid',
    'Siliana',
    'Sousse',
    'Tataouine',
    'Tozeur',
    'Tunis',
    'Zaghouan'
  ];

  // Get all Tunisian regions
  static List<String> getAllRegions() {
    return List.from(_tunisianRegions);
  }

  // Extract region from address
  static String? extractRegionFromAddress(String address) {
    final lowerAddress = address.toLowerCase();

    for (final region in _tunisianRegions) {
      if (lowerAddress.contains(region.toLowerCase())) {
        return region;
      }
    }

    return null;
  }
}
