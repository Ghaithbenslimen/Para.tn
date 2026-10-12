import 'dart:async';
import 'package:flutter/material.dart';
import 'package:project/IntelFaceAssis.dart';
import 'package:project/accountinfo.dart';
import 'package:project/cartpage.dart';
import 'package:project/chat_screen.dart';
import 'package:project/edit_profile_page.dart';
import 'package:project/home_screen.dart';
import 'package:project/login_page.dart';
import 'package:project/product_detailed_page.dart';
import 'package:project/region_extractor.dart';
import 'package:project/screens/admin_layout.dart';
import 'package:project/search_page.dart';
import 'package:project/services/cart_service.dart';
import 'package:project/services/notification_service.dart';
import 'package:project/services/store_service.dart';
import 'package:project/test.dart';
import 'package:project/track_orders_page.dart';
import 'package:project/welcome_screen.dart';
import 'package:project/parapharmacy_details.dart';
import '../models/parapharmacy_model.dart';
import '../services/parapharmacy_service.dart';
import '../services/auth_service.dart';
import 'package:project/widgets/notifications_drawer.dart';
import 'package:project/models/product_model.dart';
import 'package:project/services/product_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ParapharmacyPage extends StatefulWidget {
  const ParapharmacyPage({Key? key}) : super(key: key);

  @override
  _ParapharmacyPageState createState() => _ParapharmacyPageState();
}

class _ParapharmacyPageState extends State<ParapharmacyPage> {
  final ParapharmacyService _parapharmacyService = ParapharmacyService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final ProductService _productService = ProductService();
  final StoreService _storeService = StoreService();
  List<Parapharmacy> _allParapharmacies = [];
  List<Parapharmacy> _filteredParapharmacies = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _selectedIndex = 0;
  String _selectedFilter = 'All';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isAuthenticated = false;

  // Filter variables
  final TextEditingController _nameFilterController = TextEditingController();
  String? _selectedRegion;
  double _minRating = 0.0;
  bool _isFilterExpanded = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication().then((_) {
      _loadParapharmacies();
      if (_isAuthenticated) {
        _notificationService.getUnreadCount();
      }
    });
  }

  @override
  void dispose() {
    _nameFilterController.dispose();
    super.dispose();
  }

  // Updated method to show notifications - allow all users to access products
  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: NotificationsDrawer(
            onProductNotificationTap: (productId, productName) {
              // Navigate to product details for all users without login popup
              print('Navigate to product: $productId - $productName');
              _navigateToProductDetails(productId, productName);
            },
          ),
        ),
      ),
    );
  }

  // Updated method to navigate to product details - works for all users
  void _navigateToProductDetails(String productId, String productName) {
    // Close the notifications drawer
    Navigator.pop(context);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          color: Colors.green,
        ),
      ),
    );

    // Try to fetch product details using the StoreService first (public access)
    _storeService.getProductDetails(productId).then((product) {
      // Dismiss loading dialog
      Navigator.pop(context);

      if (product != null) {
        // Navigate to product details page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(
              name: product.name,
              brand: product.category, // Using category as brand
              price: product.price,
              discountedPrice: product.hasDiscount
                  ? product.price * (1 - product.discountPercentage / 100)
                  : null,
              rating: 4.5, // Default rating
              reviewCount: 10, // Default review count
              imageUrl: product.imagePath,
              description: product.description,
              howToUse: product.howToUse,
              parapharmacyPrices: [], // Empty list for now
              productId: product.id, // IMPORTANT: Pass the product ID
              quantity: product.quantity, // FIXED: Pass the quantity
            ),
          ),
        );
      } else {
        // If public access fails, try authenticated access if user is logged in
        if (_isAuthenticated) {
          _fetchAuthenticatedProductDetails(productId).then((product) {
            if (product != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailsPage(
                    name: product.name,
                    brand: product.category,
                    price: product.price,
                    discountedPrice: product.hasDiscount
                        ? product.price * (1 - product.discountPercentage / 100)
                        : null,
                    rating: 4.5,
                    reviewCount: 10,
                    imageUrl: product.imagePath,
                    description: product.description,
                    howToUse: product.howToUse,
                    parapharmacyPrices: [],
                    productId: product.id,
                    quantity: product.quantity, // FIXED: Pass the quantity
                  ),
                ),
              );
            } else {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Product not found or no longer available'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          });
        } else {
          // Show error message for non-authenticated users
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product not found or no longer available'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }).catchError((error) {
      // Dismiss loading dialog
      Navigator.pop(context);

      // Try authenticated method if user is logged in
      if (_isAuthenticated) {
        _fetchAuthenticatedProductDetails(productId).then((product) {
          if (product != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsPage(
                  name: product.name,
                  brand: product.category,
                  price: product.price,
                  discountedPrice: product.hasDiscount
                      ? product.price * (1 - product.discountPercentage / 100)
                      : null,
                  rating: 4.5,
                  reviewCount: 10,
                  imageUrl: product.imagePath,
                  description: product.description,
                  howToUse: product.howToUse,
                  parapharmacyPrices: [],
                  productId: product.id,
                  quantity: product.quantity, // FIXED: Pass the quantity
                ),
              ),
            );
          } else {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Product not found or no longer available'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading product: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  // Method to fetch product details for authenticated users
  Future<Product?> _fetchAuthenticatedProductDetails(String productId) async {
    try {
      print(
          'Starting to fetch authenticated product details for ID: $productId');
      final token = await _authService.getToken();
      if (token == null) {
        print('Authentication token not available');
        throw Exception('Authentication token not available');
      }

      // APPROACH 1: Try to fetch the specific product by ID directly from API
      try {
        print('APPROACH 1: Attempting to fetch product directly by ID');
        final product = await _productService.getProductById(token, productId);
        print('Successfully fetched product by ID: ${product.name}');
        return product;
      } catch (specificError) {
        print('Error in APPROACH 1: $specificError');
        print('Falling back to APPROACH 2...');

        // APPROACH 2: Try a direct HTTP request to the product endpoint
        try {
          print(
              'APPROACH 2: Attempting direct HTTP request to product endpoint');
          final response = await http.get(
            Uri.parse('${_productService.baseUrl}/auth/products/$productId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );

          print('Direct HTTP response status: ${response.statusCode}');
          print('Direct HTTP response body: ${response.body}');

          if (response.statusCode == 200) {
            final data = json.decode(response.body);

            // Handle different response formats
            Map<String, dynamic> productJson;
            if (data is Map<String, dynamic>) {
              if (data.containsKey('product')) {
                productJson = data['product'];
              } else {
                productJson = data;
              }

              // Convert to Product model
              final product = Product(
                id: productJson['_id'] ?? '',
                name: productJson['name'] ?? '',
                category: productJson['category'] ?? '',
                price:
                    double.tryParse(productJson['price']?.toString() ?? '0') ??
                        0.0,
                quantity:
                    int.tryParse(productJson['quantity']?.toString() ?? '0') ??
                        0,
                description: productJson['description'] ?? '',
                howToUse: productJson['howToUse'] ?? '',
                interfaceAsiss: productJson['intelfaceassis'] ?? '',
                hasDiscount: productJson['hasDiscount'] ?? false,
                discountPercentage: productJson['discountPercentage'] != null
                    ? double.tryParse(
                            productJson['discountPercentage'].toString()) ??
                        0.0
                    : 0.0,
                imagePath: productJson['image'] ?? '',
                skinTypes: productJson['skinTypes'] != null
                    ? List<String>.from(productJson['skinTypes'])
                    : [],
              );

              print(
                  'Successfully parsed product from direct HTTP: ${product.name}');
              return product;
            } else {
              print('Unexpected response format in APPROACH 2');
              throw Exception('Unexpected response format');
            }
          } else {
            print(
                'API error in APPROACH 2: ${response.statusCode} - ${response.body}');
            throw Exception('Failed to load product: ${response.statusCode}');
          }
        } catch (httpError) {
          print('Error in APPROACH 2: $httpError');
          print('Falling back to APPROACH 3...');

          // APPROACH 3: Last resort - Get all products and find the one with matching ID
          print('APPROACH 3: Attempting to find product in all products');
          final products = await _productService.getProducts(token);
          print(
              'Fetched ${products.length} products, searching for ID: $productId');

          try {
            final product = products.firstWhere(
              (p) => p.id == productId,
            );
            print('Found product in list: ${product.name}');
            return product;
          } catch (e) {
            print('Product not found in list: $e');
            throw Exception('Product not found in any source');
          }
        }
      }
    } catch (e) {
      print('Final error in _fetchAuthenticatedProductDetails: $e');
      return null;
    }
  }

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

  Future<void> _loadParapharmacies() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final parapharmacies = await _parapharmacyService.getParapharmacies();

      setState(() {
        _allParapharmacies = parapharmacies;
        _filteredParapharmacies = parapharmacies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load parapharmacies: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Load nearby parapharmacies for authenticated user
  Future<void> _loadNearbyParapharmacies() async {
    if (!_isAuthenticated) {
      _showLoginRequiredDialog();
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      print('Loading nearby parapharmacies...');
      final parapharmacies =
          await _parapharmacyService.getNearbyParapharmaciesForUser();
      print('Loaded ${parapharmacies.length} nearby parapharmacies');

      setState(() {
        // For nearby, we replace the entire list since it's a different dataset
        _filteredParapharmacies = parapharmacies;
        _isLoading = false;
      });

      if (parapharmacies.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'No nearby parapharmacies found. Make sure your location is set in your profile.'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Update Location',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProfilePage()),
                ).then((_) {
                  if (_selectedFilter == 'Nearby') {
                    _loadNearbyParapharmacies();
                  }
                });
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error loading nearby parapharmacies: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load nearby parapharmacies: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $_errorMessage'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Try All',
            textColor: Colors.white,
            onPressed: () {
              _onFilterSelected('All');
            },
          ),
        ),
      );
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Login Required'),
        content: Text(
            'You need to login to use the nearby feature. This allows us to access your location.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WelcomeScreen()),
              ).then((_) {
                _checkAuthentication();
                if (_isAuthenticated && _selectedFilter == 'Nearby') {
                  _loadNearbyParapharmacies();
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: Text('Login'),
          ),
        ],
      ),
    );
  }

  // Apply filters to the parapharmacies list
  void _applyFilters() {
    // Determine which base list to filter from
    List<Parapharmacy> baseList;
    if (_selectedFilter == 'Nearby') {
      // For nearby, we filter the already fetched nearby parapharmacies
      baseList = _filteredParapharmacies;
    } else {
      // For All and Top Rated, we filter from all parapharmacies
      baseList = _allParapharmacies;

      // If Top Rated is selected, sort by rating first
      if (_selectedFilter == 'Top Rated') {
        baseList = List.from(baseList)
          ..sort((a, b) => b.rating.compareTo(a.rating));
      }
    }

    setState(() {
      _filteredParapharmacies = baseList.where((parapharmacy) {
        // Filter by name
        final nameMatches = _nameFilterController.text.isEmpty ||
            parapharmacy.name
                .toLowerCase()
                .contains(_nameFilterController.text.toLowerCase());

        // Filter by region
        final regionMatches = _selectedRegion == null ||
            _selectedRegion == 'All' ||
            parapharmacy.region == _selectedRegion;

        // Filter by rating
        final ratingMatches = parapharmacy.rating >= _minRating;

        return nameMatches && regionMatches && ratingMatches;
      }).toList();
    });
  }

  // Reset all filters
  void _resetFilters() {
    setState(() {
      _nameFilterController.clear();
      _selectedRegion = null;
      _minRating = 0.0;

      // Reset to the appropriate base list based on current filter type
      if (_selectedFilter == 'Nearby') {
        // Reload nearby parapharmacies
        _loadNearbyParapharmacies();
      } else if (_selectedFilter == 'Top Rated') {
        // Sort all parapharmacies by rating
        _filteredParapharmacies = List.from(_allParapharmacies)
          ..sort((a, b) => b.rating.compareTo(a.rating));
      } else {
        // Reset to all parapharmacies
        _filteredParapharmacies = _allParapharmacies;
      }
    });
  }

  void _navigateToProtectedPage(Widget page) {
    if (!_isAuthenticated) {
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
                _checkAuthentication();
              });
            },
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 3) {
      // Profile
      _navigateToProtectedPage(ProfilePage());
    } else if (index == 2) {
      // Wishlist
      _navigateToProtectedPage(WishlistScreen());
    } else if (index == 1) {
      // Cart
      _navigateToProtectedPage(CartPage());
    }
  }

  void _onLogoClicked() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _onFilterSelected(String filter) {
    // If selecting the same filter, do nothing
    if (_selectedFilter == filter) return;

    setState(() {
      _selectedFilter = filter;

      // Reset advanced filters when changing main filter
      _nameFilterController.clear();
      _selectedRegion = null;
      _minRating = 0.0;
    });

    // Apply different sorting based on filter
    if (filter == 'All') {
      setState(() {
        _filteredParapharmacies = _allParapharmacies;
      });
    } else if (filter == 'Nearby') {
      // Use the nearby-user endpoint for authenticated users
      _loadNearbyParapharmacies();
    } else if (filter == 'Top Rated') {
      // Sort by rating (highest first)
      setState(() {
        _filteredParapharmacies = List.from(_allParapharmacies)
          ..sort((a, b) => b.rating.compareTo(a.rating));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define our primary color
    const primaryGreen = Color(0xFF2E7D32);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color(0xFFF1F8F1), // Light green background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: _onLogoClicked,
          child: Image.asset('assets/—Pngtree—women nature logo_7598961.png'),
        ),
        title: Text(
          'Para.tn',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          // Notification icon with badge - works for both authenticated and non-authenticated users
          ValueListenableBuilder<int>(
            valueListenable: _notificationService.unreadCountNotifier,
            builder: (context, unreadCount, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications_outlined,
                        color: Colors.green[800]),
                    onPressed: _showNotifications,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Get Started Button - Only show if not authenticated
          if (!_isAuthenticated)
            TextButton(
              onPressed: () {
                // Navigate to the WelcomeScreen when Get Started is tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WelcomeScreen()),
                ).then((_) {
                  // Refresh authentication status when returning from WelcomeScreen
                  _checkAuthentication();
                });
              },
              child: Text(
                'Get Started',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: primaryGreen,
              ),
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Para.tn',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your Skincare Companion',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ParapharmacyPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.favorite),
              title: Text('Favorites'),
              onTap: () {
                _navigateToProtectedPage(WishlistScreen());
              },
            ),
            ListTile(
              leading: Icon(Icons.chat),
              title: Text('SkinCoach'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.face),
              title: Text('IntelFaceAssist'),
              onTap: () {
                _navigateToProtectedPage(IntelFaceAssistPage());
              },
            ),
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text('Manage Account'),
              onTap: () {
                _navigateToProtectedPage(ProfilePage());
              },
            ),
            ListTile(
              leading: Icon(Icons.shop),
              title: Text('Order History'),
              onTap: () {
                _navigateToProtectedPage(TrackOrdersPage());
              },
            ),
            if (_isAuthenticated)
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
                onTap: () async {
                  bool result = await signOutUser();
                  if (result) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Logout successful!'),
                        backgroundColor: Colors.black,
                      ),
                    );
                    // Update authentication status after logout
                    setState(() {
                      _isAuthenticated = false;
                    });
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Logout failed. Please try again.')),
                    );
                  }
                },
              ),
          ],
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _selectedFilter == 'Nearby' && _isAuthenticated
              ? _loadNearbyParapharmacies
              : _loadParapharmacies,
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: primaryGreen))
              : _errorMessage.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 48, color: Colors.red),
                          SizedBox(height: 16),
                          Text(
                            'Error loading parapharmacies',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(_errorMessage),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed:
                                _selectedFilter == 'Nearby' && _isAuthenticated
                                    ? _loadNearbyParapharmacies
                                    : _loadParapharmacies,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                            ),
                            child: Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : CustomScrollView(
                      slivers: [
                        // Promotion Banner
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 200,
                                margin: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  border:
                                      Border.all(color: primaryGreen, width: 1),
                                ),
                                child: Stack(
                                  children: [
                                    // Carousel background
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: PromotionCarousel(
                                        imagePaths: [
                                          'assets/parapharmacy.jpg',
                                          'assets/Pharmacie_Talbi-960x640.jpg',
                                          'assets/parapharmacy3.jpg',
                                        ],
                                      ),
                                    ),
                                    // Overlay gradient
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.black.withOpacity(0.4),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Promotional text
                                    Positioned(
                                      left: 20,
                                      top: 20,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color:
                                                  primaryGreen.withOpacity(0.9),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              _selectedFilter == 'Nearby'
                                                  ? 'NEARBY STORES'
                                                  : _selectedFilter ==
                                                          'Top Rated'
                                                      ? 'TOP RATED'
                                                      : 'ALL STORES',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            _selectedFilter == 'Nearby'
                                                ? 'Find Your Local\nParapharmacy'
                                                : _selectedFilter == 'Top Rated'
                                                    ? 'Highest Rated\nParapharmacies'
                                                    : 'Discover All\nParapharmacies',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              shadows: [
                                                Shadow(
                                                  offset: Offset(0, 1),
                                                  blurRadius: 3,
                                                  color: Colors.black
                                                      .withOpacity(0.5),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Filter options
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    _buildFilterChip(
                                        'All', _selectedFilter == 'All'),
                                    SizedBox(width: 8),
                                    _buildFilterChip(
                                        'Nearby', _selectedFilter == 'Nearby'),
                                    SizedBox(width: 8),
                                    _buildFilterChip('Top Rated',
                                        _selectedFilter == 'Top Rated'),
                                  ],
                                ),
                              ),

                              // Advanced Filter Panel
                              Container(
                                margin: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
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
                                child: Column(
                                  children: [
                                    // Filter header with expand/collapse button
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _isFilterExpanded =
                                              !_isFilterExpanded;
                                        });
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            Icon(Icons.filter_list,
                                                color: primaryGreen),
                                            SizedBox(width: 8),
                                            Text(
                                              'Advanced Filters',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Spacer(),
                                            Icon(
                                              _isFilterExpanded
                                                  ? Icons.keyboard_arrow_up
                                                  : Icons.keyboard_arrow_down,
                                              color: primaryGreen,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Expandable filter content
                                    if (_isFilterExpanded)
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Name filter
                                            Text(
                                              'Parapharmacy Name',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            TextField(
                                              controller: _nameFilterController,
                                              decoration: InputDecoration(
                                                hintText: 'Search by name',
                                                prefixIcon: Icon(Icons.search,
                                                    size: 20),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  borderSide: BorderSide(
                                                      color: Colors.grey[300]!),
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        vertical: 12,
                                                        horizontal: 16),
                                              ),
                                              onChanged: (value) {
                                                // Apply filters on text change
                                                _applyFilters();
                                              },
                                            ),

                                            SizedBox(height: 16),

                                            // Region filter
                                            Text(
                                              'Region',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Colors.grey[300]!),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 12),
                                              child:
                                                  DropdownButtonHideUnderline(
                                                child: DropdownButton<String>(
                                                  isExpanded: true,
                                                  hint: Text('Select region'),
                                                  value: _selectedRegion,
                                                  items: [
                                                    DropdownMenuItem<String>(
                                                      value: 'All',
                                                      child:
                                                          Text('All Regions'),
                                                    ),
                                                    ...RegionExtractor
                                                            .getAllRegions()
                                                        .map((region) {
                                                      return DropdownMenuItem<
                                                          String>(
                                                        value: region,
                                                        child: Text(region),
                                                      );
                                                    }).toList(),
                                                  ],
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _selectedRegion = value;
                                                    });
                                                    _applyFilters();
                                                  },
                                                ),
                                              ),
                                            ),

                                            SizedBox(height: 16),

                                            // Rating filter
                                            Text(
                                              'Minimum Rating: ${_minRating.toStringAsFixed(1)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Slider(
                                              value: _minRating,
                                              min: 0,
                                              max: 5,
                                              divisions: 10,
                                              activeColor: primaryGreen,
                                              inactiveColor: Colors.grey[300],
                                              label:
                                                  _minRating.toStringAsFixed(1),
                                              onChanged: (value) {
                                                setState(() {
                                                  _minRating = value;
                                                });
                                              },
                                              onChangeEnd: (value) {
                                                _applyFilters();
                                              },
                                            ),

                                            SizedBox(height: 16),

                                            // Filter action buttons
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: OutlinedButton(
                                                    onPressed: _resetFilters,
                                                    style: OutlinedButton
                                                        .styleFrom(
                                                      foregroundColor:
                                                          primaryGreen,
                                                      side: BorderSide(
                                                          color: primaryGreen),
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              vertical: 12),
                                                    ),
                                                    child: Text('Reset'),
                                                  ),
                                                ),
                                                SizedBox(width: 12),
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed: _applyFilters,
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          primaryGreen,
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              vertical: 12),
                                                    ),
                                                    child: Text('Apply'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Parapharmacies title
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _selectedFilter == 'Nearby'
                                          ? 'Parapharmacies Near You'
                                          : _selectedFilter == 'Top Rated'
                                              ? 'Top Rated Parapharmacies'
                                              : 'All Parapharmacies',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: primaryGreen,
                                      ),
                                    ),
                                    Text(
                                      '${_filteredParapharmacies.length} found',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Parapharmacies list
                        _filteredParapharmacies.isEmpty
                            ? SliverToBoxAdapter(
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.store_outlined,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'No parapharmacies found',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Try a different filter or check back later',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        if (_selectedFilter == 'Nearby' &&
                                            _isAuthenticated)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 16.0),
                                            child: ElevatedButton.icon(
                                              icon: Icon(Icons.edit_location),
                                              label:
                                                  Text('Update Your Location'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: primaryGreen,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          EditProfilePage()),
                                                ).then((_) {
                                                  _loadNearbyParapharmacies();
                                                });
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final parapharmacy =
                                        _filteredParapharmacies[index];

                                    // Get distance from API or use a default
                                    String distance = "";
                                    if (_selectedFilter == 'Nearby' &&
                                        parapharmacy.distance.isNotEmpty) {
                                      // Only show distance in Nearby filter
                                      distance = '${parapharmacy.distance} km';
                                    }

                                    // Get rating
                                    final rating = parapharmacy.rating > 0
                                        ? parapharmacy.rating
                                        : 4.0 + (index % 10) / 10;

                                    // Every 3rd store is closed for demo purposes
                                    final isOpen = index % 3 != 0;

                                    return _buildParapharmacyCard(
                                      parapharmacy: parapharmacy,
                                      distance: distance,
                                      rating: rating,
                                      isOpen: isOpen,
                                      showDistance: _selectedFilter == 'Nearby',
                                    );
                                  },
                                  childCount: _filteredParapharmacies.length,
                                ),
                              ),
                        SliverToBoxAdapter(
                          child: SizedBox(height: 16),
                        ),
                      ],
                    ),
        ),
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

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _onFilterSelected(label),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF2E7D32) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Color(0xFF2E7D32),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFF2E7D32).withOpacity(0.3),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Color(0xFF2E7D32),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildParapharmacyCard({
    required Parapharmacy parapharmacy,
    required String distance,
    required double rating,
    required bool isOpen,
    required bool showDistance,
  }) {
    final primaryGreen = Color(0xFF2E7D32);

    // Build the image URL
    String imageUrl;
    if (parapharmacy.imagePath.isEmpty) {
      imageUrl = ''; // Will show placeholder
    } else if (parapharmacy.imagePath.startsWith('http')) {
      imageUrl = parapharmacy.imagePath;
    } else {
      // Handle server-relative paths
      final normalizedPath = parapharmacy.imagePath.replaceAll('\\', '/');
      imageUrl = '${_parapharmacyService.baseUrl}/$normalizedPath';
    }

    // Wrap the card in an InkWell to make it clickable.
    return InkWell(
      onTap: () {
        // Navigate to the StoreDetailsPage with the parapharmacy information.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoreDetailsPage(
              id: parapharmacy.id,
              name: parapharmacy.name,
              address: parapharmacy.address,
              distance: distance,
              rating: rating,
              isOpen: isOpen,
              imageUrl: imageUrl,
              phone: parapharmacy.phone,
              region: parapharmacy.region, // Pass region to details page
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Store image without distance indicator
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              child: imageUrl.isEmpty
                  ? Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: Icon(Icons.local_pharmacy,
                          color: primaryGreen, size: 50),
                    )
                  : Image.network(
                      imageUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading image: $error');
                        return Container(
                          height: 150,
                          color: Colors.grey[200],
                          child: Icon(Icons.local_pharmacy,
                              color: primaryGreen, size: 50),
                        );
                      },
                    ),
            ),
            // Store details
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          parapharmacy.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    parapharmacy.address,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Display region if available
                  if (parapharmacy.region != null &&
                      parapharmacy.region!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          Icon(Icons.location_city,
                              size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            'Region: ${parapharmacy.region}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < rating.floor()
                                ? Icons.star
                                : (index < rating
                                    ? Icons.star_half
                                    : Icons.star_border),
                            color: Colors.amber,
                            size: 18,
                          );
                        }),
                      ),
                      SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      // Display distance only in Nearby filter
                      if (showDistance && distance.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.directions,
                                size: 14, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              distance,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StoreDetailsPage(
                                  id: parapharmacy.id,
                                  name: parapharmacy.name,
                                  address: parapharmacy.address,
                                  distance: distance,
                                  rating: rating,
                                  isOpen: isOpen,
                                  imageUrl: imageUrl,
                                  phone: parapharmacy.phone,
                                  region: parapharmacy.region,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: primaryGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text('View Details'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Update signOutUser to use AuthService
  Future<bool> signOutUser() async {
    try {
      // Clear the cart when logging out
      await CartService().clearCart();

      await _authService.logout();
      return true;
    } catch (e) {
      print('Error signing out: $e');
      return false;
    }
  }
}

class PromotionCarousel extends StatefulWidget {
  final List<String> imagePaths;
  final Duration interval;
  final Duration animationDuration;

  const PromotionCarousel({
    Key? key,
    required this.imagePaths,
    this.interval = const Duration(seconds: 5),
    this.animationDuration = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  _PromotionCarouselState createState() => _PromotionCarouselState();
}

class _PromotionCarouselState extends State<PromotionCarousel> {
  late final PageController _pageController;
  late Timer _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: _currentPage);

    _timer = Timer.periodic(widget.interval, (Timer timer) {
      if (mounted) {
        _currentPage = (_currentPage + 1) % widget.imagePaths.length;
        _pageController.animateToPage(
          _currentPage,
          duration: widget.animationDuration,
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.imagePaths.length,
          itemBuilder: (context, index) {
            return Image.asset(
              widget.imagePaths[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.grey[400],
                    size: 50,
                  ),
                );
              },
            );
          },
        ),
        // Indicator dots
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.imagePaths.length,
              (index) => Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
