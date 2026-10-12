import 'dart:convert';

class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final int quantity;
  final String description;
  final String howToUse;
  final String interfaceAsiss;
  final bool hasDiscount;
  final double discountPercentage;
  final String imagePath;
  final List<String> skinTypes;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.quantity,
    required this.description,
    required this.howToUse,
    required this.interfaceAsiss,
    this.hasDiscount = false,
    this.discountPercentage = 0,
    required this.imagePath,
    this.skinTypes = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'],
      name: json['name'],
      category: json['category'],
      price: double.parse(json['price'].toString()),
      quantity: int.parse(json['quantity'].toString()),
      description: json['description'] ?? '',
      howToUse: json['howToUse'] ?? '',
      interfaceAsiss: json['intelfaceassis'] ?? 'none',
      hasDiscount: json['hasDiscount'] ?? false,
      discountPercentage: json['discountPercentage']?.toDouble() ?? 0.0,
      imagePath: json['image'] ?? '',
      skinTypes:
          json['skinTypes'] != null ? List<String>.from(json['skinTypes']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'quantity': quantity,
      'description': description,
      'howToUse': howToUse,
      'intelfaceassis': interfaceAsiss,
      'hasDiscount': hasDiscount,
      'discountPercentage': discountPercentage,
      'skinTypes': skinTypes,
    };
  }

  // Helper method to get the actual price (considering discount)
  double get actualPrice {
    return hasDiscount ? price * (1 - discountPercentage / 100) : price;
  }
}
