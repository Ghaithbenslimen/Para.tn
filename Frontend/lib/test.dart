import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/accountinfo.dart';
import 'package:project/cartpage.dart';
import 'package:project/home_screen.dart';
import 'package:project/parapharmacy_page.dart';
import 'package:project/models/product_model.dart';
import 'package:project/product_detailed_page.dart';
import 'package:project/services/wishlist_service.dart';
import 'package:project/services/cart_service.dart'; // Import cart service

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  int _selectedIndex = 2; // Wishlist tab
  bool _isLoading = true;
  String _error = '';

  // Wishlist service
  final WishlistService _wishlistService = WishlistService();

  // Cart service
  final CartService _cartService = CartService();

  // Wishlist items from API
  List<Product> _wishlistItems = [];

  // Define the color palette
  final Color primaryColor = const Color(0xFF2E7D32);
  final Color lightGreen = const Color(0xFFE8F5E9);
  final Color backgroundColor = const Color(0xFFF5F9F5);
  final Color textColor = const Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _loadWishlistItems();
  }

  // Load wishlist items from API
  Future<void> _loadWishlistItems() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final items = await _wishlistService.getWishlist();

      setState(() {
        _wishlistItems = items;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading wishlist: $e');
      setState(() {
        _error = 'Failed to load wishlist items. Please try again.';
        _isLoading = false;
      });
    }
  }

  // Remove item from wishlist
  Future<void> _toggleFavorite(int index) async {
    final product = _wishlistItems[index];

    try {
      final success = await _wishlistService.removeFromWishlist(product.id);

      if (success) {
        setState(() {
          _wishlistItems.removeAt(index);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} removed from wishlist'),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: Colors.white,
              onPressed: () async {
                // Add back to wishlist
                final addSuccess =
                    await _wishlistService.addToWishlist(product.id);
                if (addSuccess) {
                  setState(() {
                    _wishlistItems.insert(index, product);
                  });
                }
              },
            ),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove from wishlist'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error removing from wishlist: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate based on the selected tab
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage()),
      );
    } else if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ParapharmacyPage()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CartPage()),
      );
    }
  }

  // Navigate to product details page
  void _navigateToProductDetails(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsPage(
          productId: product.id,
          name: product.name,
          brand: product.category,
          price: product.price,
          discountedPrice: product.hasDiscount
              ? product.price * (1 - product.discountPercentage / 100)
              : null,
          rating: 0, // Default rating if not available
          reviewCount: 0, // Default review count if not available
          imageUrl: product.imagePath,
          description: product.description,
          howToUse: product.howToUse,
          parapharmacyPrices: [], // Empty list as default
        ),
      ),
    );
  }

  // Add item to cart
  void _addToCart(int index) {
    final product = _wishlistItems[index];

    // Use cart service to add item
    _cartService.addItem(
      id: product.id,
      name: product.name,
      brand: product.category,
      description: product.description,
      price: product.price,
      discountedPrice: product.hasDiscount
          ? product.price * (1 - product.discountPercentage / 100)
          : null,
      imageUrl: product.imagePath,
      quantity: 1,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CartPage()),
            );
          },
        ),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Add all items to cart
  void _addAllToCart() {
    if (_wishlistItems.isEmpty) return;

    for (var product in _wishlistItems) {
      _cartService.addItem(
        id: product.id,
        name: product.name,
        brand: product.category,
        description: product.description,
        price: product.price,
        discountedPrice: product.hasDiscount
            ? product.price * (1 - product.discountPercentage / 100)
            : null,
        imageUrl: product.imagePath,
        quantity: 1,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_wishlistItems.length} items added to cart'),
        action: SnackBarAction(
          label: 'VIEW CART',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CartPage()),
            );
          },
        ),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: const Text(
          'Wishlist',
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.arrow_back, color: primaryColor, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Refresh button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.refresh, color: primaryColor, size: 20),
            ),
            onPressed: _loadWishlistItems,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingIndicator()
          : _error.isNotEmpty
              ? _buildErrorState()
              : _wishlistItems.isEmpty
                  ? _buildEmptyWishlist()
                  : _buildWishlistGrid(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: primaryColor,
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

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryColor),
          const SizedBox(height: 16),
          Text(
            'Loading your wishlist...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadWishlistItems,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'TRY AGAIN',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWishlist() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Your wishlist is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Items you save will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ParapharmacyPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'EXPLORE PRODUCTS',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistGrid() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Text(
                '${_wishlistItems.length} items',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _addAllToCart,
                icon: Icon(Icons.shopping_cart_outlined,
                    size: 18, color: primaryColor),
                label: Text(
                  'Add all to cart',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: lightGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _wishlistItems.length,
            itemBuilder: (context, index) {
              final item = _wishlistItems[index];
              return EnhancedProductCard(
                image: item.imagePath,
                name: item.name,
                brand: item.category,
                price: item.actualPrice,
                isFavorited: true, // Always true in wishlist
                primaryColor: primaryColor,
                onFavoriteToggle: () => _toggleFavorite(index),
                onAddToCart: () => _addToCart(index),
                onTap: () => _navigateToProductDetails(item),
                product: item, // Pass the entire product
              );
            },
          ),
        ),
      ],
    );
  }
}

class EnhancedProductCard extends StatelessWidget {
  final String image;
  final String name;
  final String brand;
  final double price;
  final bool isFavorited;
  final Color primaryColor;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onAddToCart;
  final VoidCallback onTap;
  final Product product; // Add product for navigation

  const EnhancedProductCard({
    super.key,
    required this.image,
    required this.name,
    required this.brand,
    required this.price,
    required this.isFavorited,
    required this.primaryColor,
    required this.onFavoriteToggle,
    required this.onAddToCart,
    required this.onTap,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Make the entire card clickable
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image with heart icon overlay
            Expanded(
              flex: 6,
              child: Stack(
                children: [
                  // Ensure the image fills the entire container
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: SizedBox.expand(
                      child: _buildProductImage(image),
                    ),
                  ),
                  // Favorite button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onFavoriteToggle,
                          borderRadius: BorderRadius.circular(18),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              isFavorited
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 20,
                              color:
                                  isFavorited ? Colors.red : Colors.grey[400],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Brand badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        brand,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Product details
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product name
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Price and add to cart
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${price.toStringAsFixed(2)}\DT',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        // Add to cart button
                        GestureDetector(
                          onTap: onAddToCart,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.add_shopping_cart,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build product image with proper error handling
  Widget _buildProductImage(String imagePath) {
    // Check if the image path is empty
    if (imagePath.isEmpty) {
      return Container(
        color: Colors.green[100],
        child: Icon(Icons.image, color: primaryColor, size: 40),
      );
    }

    // Check if it's already a full URL
    final isNetworkImage =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');

    if (isNetworkImage) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading network image: $error');
          return Container(
            color: Colors.green[100],
            child: Icon(Icons.image, color: primaryColor, size: 40),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: primaryColor,
            ),
          );
        },
      );
    } else {
      // For local server files, construct the full URL
      String fullImageUrl = imagePath;

      // If it's a relative path (not starting with http), prepend the base URL
      if (!imagePath.startsWith('http')) {
        // Replace backslashes with forward slashes for URLs
        String formattedPath = imagePath.replaceAll('\\', '/');
        fullImageUrl = 'http://10.0.2.2:3000/$formattedPath';
      }

      return Image.network(
        fullImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          return Container(
            color: Colors.green[100],
            child: Icon(Icons.image, color: primaryColor, size: 40),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: primaryColor,
            ),
          );
        },
      );
    }
  }
}
