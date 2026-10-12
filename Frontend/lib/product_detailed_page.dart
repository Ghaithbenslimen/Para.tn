import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/cartpage.dart';
import 'package:project/complementary_comparison_page.dart';
import 'package:project/welcome_screen.dart';
import '../services/store_service.dart';
import '../services/cart_service.dart';
import '../services/wishlist_service.dart';
import '../services/auth_service.dart';

class ProductDetailsPage extends StatefulWidget {
  final String name;
  final String brand;
  final double price;
  final double? discountedPrice;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final String description;
  final String howToUse;
  final List<Map<String, dynamic>> parapharmacyPrices;
  final String productId;
  final int quantity;
  // Add these new optional parameters for complementary comparison
  final List<String>? skinTypes;
  final String? interfaceAsiss;
  final String? category;

  const ProductDetailsPage({
    Key? key,
    required this.name,
    required this.brand,
    required this.price,
    this.discountedPrice,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.description,
    required this.howToUse,
    required this.parapharmacyPrices,
    this.productId = '',
    this.quantity = 0,
    this.skinTypes, // New parameter
    this.interfaceAsiss, // New parameter
    this.category, // New parameter
  }) : super(key: key);

  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _quantity = 1;
  bool _isFavorite = false;
  bool _isLoadingWishlist = false;
  bool _isAuthenticated = false;

  // Services
  final StoreService _storeService = StoreService();
  final CartService _cartService = CartService();
  final WishlistService _wishlistService = WishlistService();
  final AuthService _authService = AuthService();

  // Price comparison data
  List<Map<String, dynamic>> _comparisonPrices = [];
  bool _isLoadingComparison = false;
  String _comparisonError = '';

  // List of pharmacy names to exclude from comparisons
  final List<String> _excludedPharmacies = ['greenpharmacy3', 'Green Pharmacy'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Check authentication status
    _checkAuthentication();

    // Initialize with the provided parapharmacy prices
    // Filter out the excluded pharmacies
    _comparisonPrices = List.from(widget.parapharmacyPrices.where((pharmacy) {
      String pharmacyName = pharmacy['name'] as String;
      return !_excludedPharmacies.any((excluded) =>
          pharmacyName.toLowerCase().contains(excluded.toLowerCase()));
    }));

    // Load additional price comparisons if product ID is provided
    if (widget.productId.isNotEmpty) {
      _loadPriceComparisons();
      _checkWishlistStatus();
    }
  }

  // Check authentication status
  Future<void> _checkAuthentication() async {
    try {
      final isAuthenticated = await _authService.isAuthenticated();
      setState(() {
        _isAuthenticated = isAuthenticated;
      });
      print('User authentication status: $_isAuthenticated');
    } catch (e) {
      print('Error checking authentication: $e');
    }
  }

  // Check if the product is in the wishlist
  Future<void> _checkWishlistStatus() async {
    if (widget.productId.isEmpty) return;

    setState(() {
      _isLoadingWishlist = true;
    });

    try {
      final isInWishlist =
          await _wishlistService.isInWishlist(widget.productId);

      setState(() {
        _isFavorite = isInWishlist;
        _isLoadingWishlist = false;
      });
    } catch (e) {
      print('Error checking wishlist status: $e');
      setState(() {
        _isLoadingWishlist = false;
      });
    }
  }

  // Toggle wishlist status
  Future<void> _toggleWishlist() async {
    // Check if user is authenticated first
    if (!_isAuthenticated) {
      _showLoginRequiredSnackBar();
      return;
    }

    if (widget.productId.isEmpty) {
      // Show error if product ID is not available
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot add to wishlist: Product ID not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoadingWishlist = true;
    });

    try {
      bool success;
      String message;

      if (_isFavorite) {
        // Remove from wishlist
        success = await _wishlistService.removeFromWishlist(widget.productId);
        message = success
            ? '${widget.name} removed from wishlist'
            : 'Failed to remove from wishlist';
      } else {
        // Add to wishlist
        success = await _wishlistService.addToWishlist(widget.productId);
        message = success
            ? '${widget.name} added to wishlist'
            : 'Failed to add to wishlist';
      }

      if (success) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      print('Error toggling wishlist: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating wishlist: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingWishlist = false;
      });
    }
  }

  // Show login required snackbar
  void _showLoginRequiredSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You need to login first'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Login',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => WelcomeScreen()),
            ).then((_) {
              // Refresh authentication status when returning from login
              _checkAuthentication();
            });
          },
        ),
      ),
    );
  }

  Future<void> _loadPriceComparisons() async {
    if (_isLoadingComparison) return;

    setState(() {
      _isLoadingComparison = true;
      _comparisonError = '';
    });

    try {
      // Try to fetch price comparisons from other parapharmacies
      final comparisons = await _storeService.compareProductPrices(widget.name);

      setState(() {
        // Create a set of existing pharmacy names for faster lookup
        final existingNames = _comparisonPrices
            .map((p) => p['name'].toString().toLowerCase())
            .toSet();

        // Filter and add new comparisons
        for (var comparison in comparisons) {
          String pharmacyName = comparison['parapharmacy']['name'];

          // Skip if this pharmacy should be excluded
          if (_excludedPharmacies.any((excluded) =>
              pharmacyName.toLowerCase().contains(excluded.toLowerCase()))) {
            continue;
          }

          // Skip duplicates
          if (!existingNames.contains(pharmacyName.toLowerCase())) {
            _comparisonPrices.add({
              'name': pharmacyName,
              'price': comparison['effectivePrice'],
              'rating': comparison['parapharmacy']['rating'] ?? 0.0,
            });
            existingNames.add(pharmacyName.toLowerCase());
          }
        }

        // Sort by price (lowest first)
        _comparisonPrices
            .sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));

        _isLoadingComparison = false;
      });
    } catch (e) {
      setState(() {
        _comparisonError = 'Could not load price comparisons: $e';
        _isLoadingComparison = false;
      });
      print('Error loading price comparisons: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Add to cart method - updated to check authentication
  void _addToCart() {
    // Check if user is authenticated
    if (!_isAuthenticated) {
      _showLoginRequiredSnackBar();
      return;
    }

    // User is authenticated, proceed with adding to cart
    _cartService.addItem(
      id: widget.productId.isEmpty ? widget.name : widget.productId,
      name: widget.name,
      brand: widget.brand,
      description: widget.description,
      price: widget.price,
      discountedPrice: widget.discountedPrice,
      imageUrl: widget.imageUrl,
      quantity: _quantity,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text('${widget.name} added to cart!'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CartPage()),
                );
              },
              child: const Text(
                'VIEW CART',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Method to navigate to complementary comparison page
  void _navigateToComplementaryComparison() {
    if (widget.productId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product ID not available for comparison'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComplementaryComparisonPage(
          productId: widget.productId,
          productName: widget.name,
          category: widget.category ??
              widget.brand, // Use category or brand as fallback
          skinTypes:
              widget.skinTypes ?? [], // Use provided skin types or empty list
          interfaceAsiss: widget.interfaceAsiss ??
              'none', // Use provided interface asiss or 'none'
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount = widget.discountedPrice != null;
    final effectivePrice = hasDiscount ? widget.discountedPrice! : widget.price;
    final isInStock = widget.quantity > 0;

    return Scaffold(
      backgroundColor: Colors.green[50],
      body: CustomScrollView(
        slivers: [
          // App Bar with product image, gradient overlay and discount badge
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Product Image
                  Hero(
                    tag: 'product-${widget.name}',
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(30),
                        ),
                        child: _buildProductImage(),
                      ),
                    ),
                  ),
                  // Gradient overlay for text visibility
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  // Discount badge (if applicable)
                  if (hasDiscount)
                    Positioned(
                      top: 60,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${((widget.price - widget.discountedPrice!) / widget.price * 100).toInt()}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.green),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              // Favorite button (heart icon)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: _isLoadingWishlist
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.green,
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavorite ? Colors.red : Colors.grey[600],
                          ),
                          onPressed: _toggleWishlist,
                        ),
                ),
              ),
            ],
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
          // Product Information Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Brand
                  Text(
                    widget.brand,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Price Section
                  Row(
                    children: [
                      if (hasDiscount) ...[
                        Text(
                          '${widget.discountedPrice!.toStringAsFixed(2)}\DT',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.price.toStringAsFixed(2)}\DT',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ] else
                        Text(
                          '${widget.price.toStringAsFixed(2)}\DT',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Quantity Selector
                  Row(
                    children: [
                      const Text(
                        'Quantity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.remove, color: Colors.green),
                              onPressed: () {
                                if (_quantity > 1) {
                                  setState(() {
                                    _quantity--;
                                  });
                                }
                              },
                            ),
                            Text(
                              '$_quantity',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.green),
                              onPressed: () {
                                setState(() {
                                  _quantity++;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // *** COMPLEMENTARY COMPARISON BUTTON - ADD THIS SECTION ***
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 24),
                    child: ElevatedButton.icon(
                      onPressed: _navigateToComplementaryComparison,
                      icon: const Icon(Icons.compare_arrows,
                          size: 20, color: Colors.white),
                      label: const Text(
                        'Compare Complementary Products',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),

                  // Tabs for additional product info
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TabBar(
                          controller: _tabController,
                          labelColor: Colors.green,
                          unselectedLabelColor: Colors.grey[600],
                          indicatorColor: Colors.green,
                          indicatorSize: TabBarIndicatorSize.label,
                          tabs: const [
                            Tab(text: 'Description'),
                            Tab(text: 'How to Use'),
                            Tab(text: 'Compare Prices'),
                          ],
                        ),
                        Container(
                          height: 200,
                          padding: const EdgeInsets.all(16),
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Description Tab
                              SingleChildScrollView(
                                child: Text(
                                  widget.description.isNotEmpty
                                      ? widget.description
                                      : 'No description available for this product.',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              // How to Use Tab
                              SingleChildScrollView(
                                child: Text(
                                  widget.howToUse.isNotEmpty
                                      ? widget.howToUse
                                      : 'No usage instructions available for this product.',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              // Compare Prices Tab
                              _buildPriceComparisonTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // Bottom Bar (Total Price & Add to Cart)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Price',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${(effectivePrice * _quantity).toStringAsFixed(2)}\DT',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: isInStock ? _addToCart : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isInStock ? Colors.green : Colors.grey[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isInStock ? 'Add to Cart' : 'Out of Stock',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build the product image with proper handling of network images
  Widget _buildProductImage() {
    final isInStock = widget.quantity > 0;

    // Check if the image URL is a network URL
    final isNetworkImage = widget.imageUrl.startsWith('http://') ||
        widget.imageUrl.startsWith('https://');

    Widget imageWidget;
    if (isNetworkImage) {
      imageWidget = Image.network(
        widget.imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading network image: $error');
          // Fallback to placeholder on error
          return Container(
            color: Colors.green[100],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image, color: Colors.green, size: 64),
                const SizedBox(height: 8),
                Text(
                  'Image not available',
                  style: TextStyle(color: Colors.green[800]),
                ),
              ],
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.green[50],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: Colors.green,
              ),
            ),
          );
        },
      );
    } else {
      // For local server files, construct the full URL
      String fullImageUrl = widget.imageUrl;

      // If it's a relative path (not starting with http), prepend the base URL
      if (!widget.imageUrl.startsWith('http')) {
        // Replace backslashes with forward slashes for URLs
        String formattedPath = widget.imageUrl.replaceAll('\\', '/');
        fullImageUrl = 'http://10.0.2.2:3000/$formattedPath';
      }

      imageWidget = Image.network(
        fullImageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          // Fallback to placeholder on error
          return Container(
            color: Colors.green[100],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image, color: Colors.green, size: 64),
                const SizedBox(height: 8),
                Text(
                  'Image not available',
                  style: TextStyle(color: Colors.green[800]),
                ),
              ],
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.green[50],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: Colors.green,
              ),
            ),
          );
        },
      );
    }

    // Add an "Out of Stock" overlay if the product is not in stock
    return Stack(
      children: [
        imageWidget,
        if (!isInStock)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'OUT OF STOCK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Helper method to build the price comparison tab
  Widget _buildPriceComparisonTab() {
    if (_isLoadingComparison) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Loading price comparisons...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_comparisonError.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.orange, size: 40),
            const SizedBox(height: 8),
            Text(
              'Could not load all comparisons',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Showing available prices',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_comparisonPrices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_mall_directory_outlined,
                color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            Text(
              'No price comparisons available',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }

    // Find the lowest price for highlighting
    final lowestPrice = _comparisonPrices.isEmpty
        ? 0.0
        : _comparisonPrices
            .map((p) => p['price'] as num)
            .reduce((a, b) => a < b ? a : b);

    return ListView.builder(
      itemCount: _comparisonPrices.length,
      itemBuilder: (context, index) {
        final item = _comparisonPrices[index];
        final isLowestPrice = (item['price'] as num) <= lowestPrice;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isLowestPrice ? Colors.green.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isLowestPrice ? Colors.green : Colors.grey[300]!,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.store,
                color: isLowestPrice ? Colors.green : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'].toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (isLowestPrice)
                      const Text(
                        'Best Price!',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    if (item.containsKey('rating') && item['rating'] != null)
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            '${(item['rating'] as num).toStringAsFixed(1)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Text(
                '${(item['price'] as num).toStringAsFixed(2)}\DT',
                style: TextStyle(
                  color: isLowestPrice ? Colors.green : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
