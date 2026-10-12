class Order {
  final String id;
  final String status;
  final double totalAmount;
  final String paymentMethod;
  final bool isPaid;
  final DateTime? paidAt;
  final DateTime createdAt;
  final Map<String, dynamic> shippingAddress;
  final List<OrderItem> products;
  final Map<String, dynamic> parapharmacy;

  Order({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.paymentMethod,
    required this.isPaid,
    this.paidAt,
    required this.createdAt,
    required this.shippingAddress,
    required this.products,
    required this.parapharmacy,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    List<OrderItem> orderItems = [];
    if (json['products'] != null) {
      orderItems = List<OrderItem>.from(
          json['products'].map((item) => OrderItem.fromJson(item)));
    }

    return Order(
      id: json['_id'],
      status: json['status'],
      totalAmount: json['totalAmount'].toDouble(),
      paymentMethod: json['paymentMethod'],
      isPaid: json['isPaid'] ?? false,
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      shippingAddress: json['shippingAddress'],
      products: orderItems,
      parapharmacy: json['parapharmacy'],
    );
  }
}

class OrderItem {
  final String id;
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String? image;

  OrderItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.image,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['_id'],
      productId: json['product']['_id'],
      name: json['name'],
      price: json['price'].toDouble(),
      quantity: json['quantity'],
      image: json['image'],
    );
  }
}
