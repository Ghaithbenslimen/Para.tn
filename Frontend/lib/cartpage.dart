import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/accountinfo.dart';
import 'package:project/home_screen.dart';
import 'package:project/parapharmacy_page.dart';
import 'package:project/test.dart';
import 'package:project/checkout_page.dart'; // Import the checkout page
import 'package:project/utils/snackbar_utils.dart'; // Import the snackbar utility
import '../services/cart_service.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartService _cartService = CartService();
  int _selectedIndex = 1; // Default to the Cart tab

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 3) {
      // Profile
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage()),
      );
    } else if (index == 2) {
      // Wishlist
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WishlistScreen()),
      );
    } else if (index == 1) {
      // Cart
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CartPage()),
      );
    } else if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ParapharmacyPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define our color palette
    const primaryGreen = Color(0xFF2E7D32);
    const lightGreen = Color(0xFFE8F5E9);
    const backgroundColor = Color(0xFFF5F9F5);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: const Text(
          'My Cart',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.arrow_back, color: primaryGreen, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                // Clear cart confirmation
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Clear Cart'),
                    content: Text('Are you sure you want to clear your cart?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          _cartService.clearCart();
                          Navigator.pop(context);
                          // Show snackbar when cart is cleared
                          SnackbarUtils.showSuccessSnackbar(
                              context, 'Cart cleared successfully');
                        },
                        child:
                            Text('Clear', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.delete_outline,
                    color: Colors.red[400], size: 20),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<dynamic>>(
        stream: _cartService.cartStream,
        initialData: _cartService.items,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final cartItems = snapshot.data ?? [];

          if (cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add items to your cart to see them here',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ParapharmacyPage()),
                      );
                    },
                    icon: Icon(Icons.shopping_bag_outlined),
                    label: Text('Continue Shopping'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      iconColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Cart items section
                    Text(
                      'Cart Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Cart items list
                    ...cartItems.map((item) => _buildCartItem(item)).toList(),

                    // Order summary section
                    SizedBox(height: 24),
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildSummaryRow('Subtotal',
                              '${_cartService.totalPrice.toStringAsFixed(2)}\DT'),
                          SizedBox(height: 8),
                          _buildSummaryRow('Shipping', 'Free'),
                          SizedBox(height: 8),
                          Divider(),
                          SizedBox(height: 8),
                          _buildSummaryRow('Total',
                              '${_cartService.totalPrice.toStringAsFixed(2)}\DT',
                              isTotal: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Checkout button section - UPDATED
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to checkout page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CheckoutPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Checkout',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          size: 20,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: primaryGreen,
          unselectedItemColor: Colors.grey[400],
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              label: 'Wishlist',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Widget _buildCartItem(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildProductImage(item.imageUrl, 100, 100),
          ),
          const SizedBox(width: 16),

          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.brand,
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.effectivePrice.toStringAsFixed(2)}\DT',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),

                    // Quantity controls
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _buildQuantityButton(
                            Icons.remove,
                            () {
                              if (item.quantity > 1) {
                                _cartService.updateQuantity(
                                    item.id, item.quantity - 1);
                                // Show snackbar when quantity is decreased
                                SnackbarUtils.showSuccessSnackbar(
                                    context, 'Quantity updated');
                              } else {
                                // Show delete confirmation
                                _showDeleteConfirmation(context, item);
                              }
                            },
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                          _buildQuantityButton(
                            Icons.add,
                            () {
                              _cartService.updateQuantity(
                                  item.id, item.quantity + 1);
                              // Show snackbar when quantity is increased
                              SnackbarUtils.showSuccessSnackbar(
                                  context, 'Quantity updated');
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String imageUrl, double width, double height) {
    final isNetworkImage =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

    if (isNetworkImage) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: Icon(Icons.image, color: Colors.grey[400], size: 40),
          );
        },
      );
    } else {
      return Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: Icon(Icons.image, color: Colors.grey[400], size: 40),
          );
        },
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context, dynamic item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Item'),
        content: Text('Do you want to remove ${item.name} from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _cartService.removeItem(item.id);
              Navigator.pop(context);

              // Show snackbar when item is removed
              SnackbarUtils.showErrorSnackbar(
                  context, '${item.name} removed from cart');
            },
            child: Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(8),
        child: Icon(
          icon,
          color: Color(0xFF2E7D32),
          size: 18,
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
            color: isTotal ? Color(0xFF1A1A1A) : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
            color: isTotal ? Color(0xFF2E7D32) : Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}
