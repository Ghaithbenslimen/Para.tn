class CartItem {
  final String id;
  final String name;
  final String brand;
  final String description;
  final double price;
  final double? discountedPrice;
  final String imageUrl;
  int quantity;
  final String? ownerId; // Add owner ID (parapharmacy ID)

  CartItem({
    required this.id,
    required this.name,
    required this.brand,
    required this.description,
    required this.price,
    this.discountedPrice,
    required this.imageUrl,
    this.quantity = 1,
    this.ownerId, // Make it optional but we'll set it when adding to cart
  });

  double get effectivePrice => discountedPrice ?? price;

  double get totalPrice => effectivePrice * quantity;

  CartItem copyWith({
    String? id,
    String? name,
    String? brand,
    String? description,
    double? price,
    double? discountedPrice,
    String? imageUrl,
    int? quantity,
    String? ownerId,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      description: description ?? this.description,
      price: price ?? this.price,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      ownerId: ownerId ?? this.ownerId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'description': description,
      'price': price,
      'discountedPrice': discountedPrice,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'ownerId': ownerId,
    };
  }
}
