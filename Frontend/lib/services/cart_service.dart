import 'dart:async';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';

class CartService {
  // Singleton pattern
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  static const String _cartBoxName = 'cartBox';
  static const String _cartItemsKey = 'cartItems';
  late Box _box;

  // Initialize Hive
  Future<void> init() async {
    await Hive.openBox(_cartBoxName);
    _box = Hive.box(_cartBoxName);
    _loadCartItems();
  }

  // Cart items
  final List<CartItem> _items = [];

  // Stream controller for cart updates
  final _cartController = StreamController<List<CartItem>>.broadcast();

  // Stream getter
  Stream<List<CartItem>> get cartStream => _cartController.stream;

  // Load cart items from storage
  Future<void> _loadCartItems() async {
    try {
      final cartData = _box.get(_cartItemsKey);
      if (cartData != null && cartData is List) {
        _items.clear();
        for (var item in cartData) {
          if (item is Map) {
            _items.add(CartItem(
              id: item['id'],
              name: item['name'],
              brand: item['brand'],
              description: item['description'],
              price: item['price'],
              discountedPrice: item['discountedPrice'],
              imageUrl: item['imageUrl'],
              quantity: item['quantity'] ?? 1,
            ));
          }
        }
        _cartController.add(_items);
      }
    } catch (e) {
      print('Error loading cart items: $e');
    }
  }

  // Save cart items to storage
  Future<void> _saveCartItems() async {
    try {
      final cartData = _items.map((item) => item.toMap()).toList();
      await _box.put(_cartItemsKey, cartData);
    } catch (e) {
      print('Error saving cart items: $e');
    }
  }

  // Get all cart items
  List<CartItem> get items => List.unmodifiable(_items);

  // Get cart item count
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  // Get cart total price
  double get totalPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);

  // Add item to cart
  Future<void> addItem({
    required String id,
    required String name,
    required String brand,
    required String description,
    required double price,
    double? discountedPrice,
    required String imageUrl,
    int quantity = 1,
  }) async {
    // Check if item already exists in cart
    final existingIndex = _items.indexWhere((item) => item.id == id);

    if (existingIndex >= 0) {
      // Update quantity if item exists
      _items[existingIndex].quantity += quantity;
    } else {
      // Add new item if it doesn't exist
      _items.add(CartItem(
        id: id,
        name: name,
        brand: brand,
        description: description,
        price: price,
        discountedPrice: discountedPrice,
        imageUrl: imageUrl,
        quantity: quantity,
      ));
    }

    // Save to storage and notify listeners
    await _saveCartItems();
    _cartController.add(_items);
  }

  // Update item quantity
  Future<void> updateQuantity(String id, int quantity) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index].quantity = quantity;
      if (_items[index].quantity <= 0) {
        _items.removeAt(index);
      }
      await _saveCartItems();
      _cartController.add(_items);
    }
  }

  // Remove item from cart
  Future<void> removeItem(String id) async {
    _items.removeWhere((item) => item.id == id);
    await _saveCartItems();
    _cartController.add(_items);
  }

  // Clear cart
  Future<void> clearCart() async {
    _items.clear();
    await _box.delete(_cartItemsKey);
    _cartController.add(_items);
  }

  // Clear cart on logout (optional)
  Future<void> clearCartOnLogout() async {
    // You can choose to clear cart on logout or not
    // _items.clear();
    // await _box.delete(_cartItemsKey);
    // _cartController.add(_items);
  }

  // Dispose
  void dispose() {
    _cartController.close();
  }
}
