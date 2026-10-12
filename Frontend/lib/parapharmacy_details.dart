import 'package:flutter/material.dart';
import 'package:project/Product_Category_Page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:project/login_page.dart'; // Import login page
import 'package:project/product_detailed_page.dart'; // Import product details page
import '../models/parapharmacy_model.dart';
import '../models/product_model.dart'; // Import product model
import '../services/parapharmacy_service.dart';
import '../services/auth_service.dart';
import '../services/statistics_service.dart'; // Import statistics service
import '../services/store_service.dart'; // Import store service

class StoreDetailsPage extends StatefulWidget {
  final String id;
  final String name;
  final String address;
  final String distance;
  final double rating;
  final bool isOpen;
  final String imageUrl;
  final String phone;
  final String? region; // Add region parameter

  const StoreDetailsPage({
    Key? key,
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    required this.rating,
    required this.isOpen,
    required this.imageUrl,
    required this.phone,
    this.region, // Make it optional
  }) : super(key: key);

  @override
  _StoreDetailsPageState createState() => _StoreDetailsPageState();
}

class _StoreDetailsPageState extends State<StoreDetailsPage> {
  final TextEditingController _commentController = TextEditingController();
  final ParapharmacyService _parapharmacyService = ParapharmacyService();
  final AuthService _authService = AuthService();
  final StatisticsService _statisticsService =
      StatisticsService(); // Initialize statistics service
  final StoreService _storeService = StoreService(); // Initialize store service

  double _userRating = 5.0;
  bool _isCommentExpanded = false;
  bool _isLoading = false;
  bool _isSubmittingReview = false;
  String _errorMessage = '';
  bool _isAuthenticated = false;
  String? _currentUserId;
  String? _currentUserName;
  bool _showAllReviews = false;
  static const int _initialReviewCount = 5;

  // Add variables for popular products
  List<Map<String, dynamic>> _popularProducts = [];
  bool _isLoadingPopularProducts = false;

  // Track which review is being deleted
  String? _deletingReviewId;

  Parapharmacy? _parapharmacyDetails;
  List<Map<String, dynamic>> _reviews = [];

  // Add variables for coordinates
  double? _latitude;
  double? _longitude;
  bool _isLoadingCoordinates = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    if (widget.id.isNotEmpty) {
      _loadParapharmacyDetails();
      _loadReviews();
      _loadParapharmacyCoordinates(); // Load coordinates when page initializes
      _loadPopularProducts(); // Load popular products
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // Method to load popular products
  Future<void> _loadPopularProducts() async {
    if (widget.id.isEmpty) return;

    try {
      setState(() {
        _isLoadingPopularProducts = true;
      });

      // Get statistics for this parapharmacy to access top products
      final statistics =
          await _statisticsService.getParapharmacyStatistics(widget.id);

      if (statistics.containsKey('topProducts')) {
        setState(() {
          _popularProducts =
              List<Map<String, dynamic>>.from(statistics['topProducts']);
        });
        print('Loaded ${_popularProducts.length} popular products');
      }
    } catch (e) {
      print('Error loading popular products: $e');
      // We don't show an error message here to avoid disrupting the user experience
    } finally {
      setState(() {
        _isLoadingPopularProducts = false;
      });
    }
  }

  // Method to navigate to product details
  void _navigateToProductDetails(String productId, String productName) {
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

    // Fetch product details
    _fetchProductDetails(productId).then((product) {
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
              quantity: product.quantity, // Pass quantity to show stock status
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
    }).catchError((error) {
      // Dismiss loading dialog
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading product: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  // Method to fetch product details
  Future<Product?> _fetchProductDetails(String productId) async {
    try {
      return await _storeService.getProductDetails(productId);
    } catch (e) {
      print('Error fetching product details: $e');
      return null;
    }
  }

  Future<void> _checkAuthentication() async {
    // Initialize the auth service first
    await _authService.initialize();

    final isAuthenticated = await _authService.isAuthenticated();
    final userId = await _authService.getCurrentUserId();
    final userName = await _authService.getCurrentUsername();

    setState(() {
      _isAuthenticated = isAuthenticated;
      _currentUserId = userId;
      _currentUserName = userName;
    });

    print('Authentication status: $_isAuthenticated');
    print('Current user ID: $_currentUserId');
    print('Current user name: $_currentUserName');

    // After authentication, reload reviews to ensure proper ownership display
    if (isAuthenticated && widget.id.isNotEmpty) {
      _loadReviews();
    }
  }

  // New method to load parapharmacy coordinates
  Future<void> _loadParapharmacyCoordinates() async {
    if (widget.id.isEmpty) return;
    setState(() {
      _isLoadingCoordinates = true;
    });
    try {
      print('Loading coordinates for parapharmacy ID: ${widget.id}');
      final coordinates =
          await _parapharmacyService.getParapharmacyCoordinates(widget.id);
      if (coordinates != null) {
        print('Received coordinates: $coordinates');
        // Make sure to parse the values as doubles
        final double? lat = coordinates['latitude'] is double
            ? coordinates['latitude']
            : double.tryParse(coordinates['latitude'].toString());
        final double? lng = coordinates['longitude'] is double
            ? coordinates['longitude']
            : double.tryParse(coordinates['longitude'].toString());
        setState(() {
          _latitude = lat;
          _longitude = lng;
        });
        print('Set coordinates: Lat: $_latitude, Long: $_longitude');
      } else {
        print('No coordinates received from service');
      }
    } catch (e) {
      print('Error loading coordinates: $e');
    } finally {
      setState(() {
        _isLoadingCoordinates = false;
      });
    }
  }

  // Method to open Google Maps with the coordinates
  Future<void> _openMapsWithDirections() async {
    try {
      if (_latitude == null || _longitude == null) {
        print('Coordinates not loaded yet, trying to load them now...');
        // If coordinates aren't loaded yet, try loading them
        await _loadParapharmacyCoordinates();

        // If still null after loading, show error
        if (_latitude == null || _longitude == null) {
          print('Still no coordinates available after loading attempt');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Location coordinates not available for this store')),
          );
          return;
        }
      }

      print('Opening maps with coordinates: $_latitude, $_longitude');

      // Format the Google Maps URL with the coordinates
      final String googleMapsUrl =
          'https://www.google.com/maps/dir/?api=1&destination=$_latitude,$_longitude&travelmode=driving&dir_action=navigate';

      print('Maps URL: $googleMapsUrl');

      // Create a Uri object from the URL
      final Uri uri = Uri.parse(googleMapsUrl);

      // Launch the URL
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // If Google Maps app is not installed, try opening in browser
        final String webMapsUrl =
            'https://www.google.com/maps?q=$_latitude,$_longitude';
        final Uri webUri = Uri.parse(webMapsUrl);
        if (await canLaunchUrl(webUri)) {
          await launchUrl(
            webUri,
            mode: LaunchMode.externalApplication,
          );
        } else {
          throw 'Could not launch maps';
        }
      }
    } catch (e) {
      print('Error opening maps: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening maps: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadParapharmacyDetails() async {
    if (widget.id.isEmpty) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final parapharmacy =
          await _parapharmacyService.getParapharmacyById(widget.id);

      setState(() {
        _parapharmacyDetails = parapharmacy;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load parapharmacy details: $e';
      });
      print(_errorMessage);
    }
  }

  Future<void> _loadReviews() async {
    if (widget.id.isEmpty) return;

    try {
      final reviews = await _parapharmacyService.getReviews(widget.id);
      setState(() {
        _reviews = reviews;
      });
      print('Loaded ${_reviews.length} reviews');

      // Debug: Print review details
      for (var review in _reviews) {
        print(
            'Review ID: ${review['_id']}, User: ${review['user']}, Current User: $_currentUserName');
      }
    } catch (e) {
      print('Error loading reviews: $e');
      // We don't show an error message here to avoid disrupting the user experience
    }
  }

  Future<void> _submitReview() async {
    // Check if user is authenticated
    if (!_isAuthenticated) {
      _showLoginDialog();
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a comment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingReview = true;
    });

    try {
      final success = await _parapharmacyService.submitReview(
        widget.id,
        _userRating,
        _commentController.text,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );

        // Clear the form and refresh reviews
        setState(() {
          _commentController.clear();
          _isCommentExpanded = false;
        });

        // Reload reviews to show the new one
        _loadReviews();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit review. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting review: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmittingReview = false;
      });
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Required'),
        content: const Text('You need to be logged in to submit a review.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              ).then((_) => _checkAuthentication());
            },
            child: const Text('Login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    ).then((_) => _checkAuthentication());
  }

  // Method to delete a review
  Future<void> _deleteReview(String reviewId) async {
    // Show confirmation dialog before deleting
    final bool confirmDelete = await _showDeleteConfirmationDialog();
    if (!confirmDelete) return;

    setState(() {
      _deletingReviewId = reviewId; // Set which review is being deleted
    });

    try {
      print('Attempting to delete review: $reviewId');
      final success =
          await _parapharmacyService.deleteReview(widget.id, reviewId);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review deleted successfully!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );

        // Reload reviews to update the list
        _loadReviews();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete review. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting review: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _deletingReviewId = null; // Clear the deleting review ID
      });
    }
  }

  // Show confirmation dialog before deleting a review
  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Review'),
            content: const Text(
                'Are you sure you want to delete this review? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = const Color(0xFF2E7D32);
    final accentGreen = const Color(0xFFC8E6C9);
    final lightGreen = const Color(0xFFE8F5E9);

    // Use either loaded details or widget parameters
    final name = _parapharmacyDetails?.name ?? widget.name;
    final address = _parapharmacyDetails?.address ?? widget.address;
    final phone = _parapharmacyDetails?.phone ?? widget.phone;
    final description = _parapharmacyDetails?.description ?? '';

    // Use region from parapharmacy details or widget parameter
    final region = _parapharmacyDetails?.region ?? widget.region;

    // Build the image URL
    String imageUrl;
    if (_parapharmacyDetails != null &&
        _parapharmacyDetails!.imagePath.isNotEmpty) {
      if (_parapharmacyDetails!.imagePath.startsWith('http')) {
        imageUrl = _parapharmacyDetails!.imagePath;
      } else {
        // Handle server-relative paths
        final normalizedPath =
            _parapharmacyDetails!.imagePath.replaceAll('\\', '/');
        imageUrl = '${_parapharmacyService.baseUrl}/$normalizedPath';
      }
    } else {
      imageUrl = widget.imageUrl;
    }

    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
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
                      child:
                          Icon(Icons.arrow_back, color: Colors.black, size: 20),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  expandedHeight: 300.0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: accentGreen,
                            child: Icon(Icons.store,
                                size: 100, color: primaryGreen),
                          ),
                        ),
                        // Gradient overlay for better text visibility
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.5),
                              ],
                              stops: [0.7, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Changed to white
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 3.0,
                            color: Colors.black.withOpacity(
                                0.5), // Darker shadow for better contrast
                          ),
                        ],
                      ),
                    ),
                  ),
                  pinned: true,
                  backgroundColor: primaryGreen,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Store Info Card
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  SizedBox(width: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.star,
                                            color: Colors.amber, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          widget.rating.toStringAsFixed(
                                              1), // Changed to show 1 decimal place
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.location_on,
                                      size: 16, color: Colors.grey),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      address,
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ),
                                ],
                              ),
                              // Display region if available
                              if (region != null && region.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_city,
                                          size: 16, color: Colors.grey),
                                      SizedBox(width: 4),
                                      Text(
                                        'Region: $region',
                                        style:
                                            TextStyle(color: Colors.grey[700]),
                                      ),
                                    ],
                                  ),
                                ),

                              if (phone.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    children: [
                                      Icon(Icons.phone,
                                          size: 16, color: Colors.grey),
                                      SizedBox(width: 4),
                                      Text(
                                        phone,
                                        style:
                                            TextStyle(color: Colors.grey[700]),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_parapharmacyDetails?.email != null &&
                                  _parapharmacyDetails!.email.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    children: [
                                      Icon(Icons.email,
                                          size: 16, color: Colors.grey),
                                      SizedBox(width: 4),
                                      Text(
                                        _parapharmacyDetails!.email,
                                        style:
                                            TextStyle(color: Colors.grey[700]),
                                      ),
                                    ],
                                  ),
                                ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: Icon(Icons.call, size: 16),
                                      label: Text('Call'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: primaryGreen,
                                        side: BorderSide(color: primaryGreen),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () async {
                                        if (phone.isNotEmpty) {
                                          final Uri phoneUri =
                                              Uri(scheme: 'tel', path: phone);
                                          if (await canLaunchUrl(phoneUri)) {
                                            await launchUrl(phoneUri);
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'Could not launch call')),
                                            );
                                          }
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'No phone number available')),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: Icon(Icons.directions, size: 16),
                                      label: Text('Directions'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: primaryGreen,
                                        side: BorderSide(color: primaryGreen),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: _isLoadingCoordinates
                                          ? null
                                          : _openMapsWithDirections,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        if (description.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 24),
                              Text(
                                'About',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 12),
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  description,
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),

                        SizedBox(height: 24),
                        Text(
                          'Store Highlights',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildFeatureChip(
                                'Free Delivery', Icons.local_shipping),
                            _buildFeatureChip(
                                '24/7 Support', Icons.support_agent),
                            _buildFeatureChip(
                                'Verified Products', Icons.verified_user),
                            _buildFeatureChip('Secure Payment', Icons.lock),
                          ],
                        ),

                        SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Popular Products',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        _isLoadingPopularProducts
                            ? Container(
                                height: 180,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: primaryGreen,
                                  ),
                                ),
                              )
                            : _popularProducts.isEmpty
                                ? Container(
                                    height: 180,
                                    child: ListView(
                                      scrollDirection: Axis.horizontal,
                                      children: [
                                        _buildProductCard(
                                            'Vitamin C Serum', '29.99 TND'),
                                        _buildProductCard(
                                            'Sunscreen SPF 50', '19.99 TND'),
                                        _buildProductCard(
                                            'Moisturizing Cream', '24.99 TND'),
                                        _buildProductCard(
                                            'Face Mask', '15.99 TND'),
                                      ],
                                    ),
                                  )
                                : Container(
                                    height: 180,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _popularProducts.length,
                                      itemBuilder: (context, index) {
                                        final product = _popularProducts[index];
                                        return _buildPopularProductCard(
                                          product['name'] ?? 'Unknown Product',
                                          '${product['revenue']?.toStringAsFixed(2) ?? '0.00'} TND',
                                          product['id'] ?? '',
                                          product['image'] ?? '',
                                          product['quantity'] ?? 0,
                                        );
                                      },
                                    ),
                                  ),

                        SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Customer Reviews',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  widget.rating.toStringAsFixed(
                                      1), // Changed to show 1 decimal place
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.star, color: Colors.amber, size: 18),
                                Text(
                                  ' (${_reviews.length})',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Add Review Section
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Write a Review',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (_isAuthenticated)
                                    IconButton(
                                      icon: Icon(
                                        _isCommentExpanded
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        color: primaryGreen,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isCommentExpanded =
                                              !_isCommentExpanded;
                                        });
                                      },
                                    ),
                                ],
                              ),
                              if (_isAuthenticated && _isCommentExpanded) ...[
                                SizedBox(height: 8),
                                Text(
                                  'Your Rating',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    for (int i = 1; i <= 5; i++)
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _userRating = i.toDouble();
                                          });
                                        },
                                        child: Icon(
                                          i <= _userRating
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.amber,
                                          size: 32,
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Your Comment',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextField(
                                  controller: _commentController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Share your experience with this store...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          BorderSide(color: primaryGreen),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    contentPadding: EdgeInsets.all(16),
                                  ),
                                ),
                                SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isSubmittingReview
                                        ? null
                                        : _submitReview,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryGreen,
                                      foregroundColor: Colors.white,
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isSubmittingReview
                                        ? SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          )
                                        : Text(
                                            'Submit Review',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                  ),
                                ),
                              ] else if (!_isAuthenticated) ...[
                                SizedBox(height: 16),
                                Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        'Please login to write a review',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: _navigateToLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryGreen,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          'Login',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                SizedBox(height: 8),
                                Text(
                                  'Tap to share your experience with this store',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        SizedBox(height: 24),
                        // Display reviews from the backend
                        _reviews.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    'No reviews yet. Be the first to review!',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  // Display limited or all reviews based on _showAllReviews flag
                                  ..._reviews
                                      .take(_showAllReviews
                                          ? _reviews.length
                                          : _initialReviewCount)
                                      .map((review) {
                                    // Parse the review date
                                    DateTime reviewDate;
                                    try {
                                      reviewDate =
                                          DateTime.parse(review['date']);
                                    } catch (e) {
                                      reviewDate = DateTime.now();
                                    }
                                    // Format the date
                                    final formattedDate =
                                        DateFormat('MMM d, yyyy')
                                            .format(reviewDate);

                                    // Get the review ID
                                    final reviewId = review['_id'];

                                    // IMPORTANT FIX: Check if the current user is the author by username
                                    // Since the database doesn't have userId in reviews, we compare usernames
                                    final String reviewUsername =
                                        review['user']?.toString() ?? '';
                                    final String currentUsername =
                                        _currentUserName?.toString() ?? '';

                                    print(
                                        'Comparing review username: $reviewUsername with current username: $currentUsername');

                                    // Check if the current user is the author of this review by comparing usernames
                                    final bool isAuthor = _isAuthenticated &&
                                        reviewUsername.isNotEmpty &&
                                        currentUsername.isNotEmpty &&
                                        reviewUsername == currentUsername;

                                    print(
                                        'Is author of review $reviewId: $isAuthor');

                                    return _buildReviewFromData(
                                      review['comment'] ?? '',
                                      review['user'] ?? 'User',
                                      (review['rating'] ?? 0).toDouble(),
                                      formattedDate,
                                      isAuthor
                                          ? () => _deleteReview(reviewId)
                                          : null,
                                      reviewId,
                                    );
                                  }).toList(),

                                  // Show "See All" button if there are more than 5 reviews and not showing all
                                  if (_reviews.length > _initialReviewCount &&
                                      !_showAllReviews)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16.0),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _showAllReviews = true;
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF2E7D32),
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          'See All Reviews (${_reviews.length})',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),

                                  // Show "Show Less" button when showing all reviews and there are more than 5
                                  if (_reviews.length > _initialReviewCount &&
                                      _showAllReviews)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16.0),
                                      child: TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _showAllReviews = false;
                                          });
                                        },
                                        child: Text(
                                          'Show Less',
                                          style: TextStyle(
                                            color: Color(0xFF2E7D32),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                        // If you have sample reviews section, replace it with:
                        if (_reviews.isEmpty && !_isLoading) ...[
                          _buildReview(
                              'Amazing service! The staff was very helpful and knowledgeable about skincare products.',
                              'Sarah M.',
                              5),
                          _buildReview(
                              'Good products, but delivery was a bit slow. Overall satisfied with my purchase.',
                              'Ali R.',
                              4),
                          _buildReview(
                              'Fast delivery and the products were exactly as described. Will definitely shop here again!',
                              'Emma S.',
                              5),
                        ],

                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        child: SafeArea(
          child: ElevatedButton.icon(
            icon: Icon(Icons.shopping_cart, color: Colors.white),
            label: Text('Shop Now'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ProductCategoryPage(
                          categoryName: '',
                          parapharmacyId: widget.id,
                        )),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Color(0xFF2E7D32)),
          SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(String name, String price) {
    return Container(
      width: 140,
      margin: EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Color(0xFFE8F5E9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(
              child: Icon(Icons.spa, size: 40, color: Color(0xFF2E7D32)),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  price,
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // New method to build popular product card with real data
  Widget _buildPopularProductCard(String name, String price, String productId,
      String imagePath, int quantity) {
    // Get the image URL
    String imageUrl = "";
    if (imagePath.isNotEmpty) {
      if (imagePath.startsWith("http")) {
        imageUrl = imagePath;
      } else {
        // Handle server-relative paths
        final normalizedPath = imagePath.replaceAll("\\", "/");
        imageUrl = "${_parapharmacyService.baseUrl}/$normalizedPath";
      }
    }

    return GestureDetector(
      onTap: () {
        if (productId.isNotEmpty) {
          _navigateToProductDetails(productId, name);
        }
      },
      child: Container(
        width: 140,
        margin: EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Color(0xFFE8F5E9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(Icons.spa,
                              size: 40, color: Color(0xFF2E7D32)),
                        ),
                      ),
                    )
                  : Center(
                      child:
                          Icon(Icons.spa, size: 40, color: Color(0xFF2E7D32)),
                    ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (quantity <= 0)
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Out of stock',
                            style: TextStyle(
                              color: Colors.red[800],
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
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

  Widget _buildReview(String text, String author, int stars) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                radius: 20,
                child: Text(
                  author.split(' ')[0][0],
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    author,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: List.generate(
                      5,
                      (index) => Icon(
                        index < stars ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              Spacer(),
              Text(
                '2 days ago',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // In _StoreDetailsPageState
  Widget _buildReviewFromData(
      String text, String author, double rating, String date,
      [Function()? onDelete, String? reviewId]) {
    // Use the provided author, defaulting to 'User' if empty.
    final displayName = author.isNotEmpty ? author : 'User';
    final primaryGreen = const Color(0xFF2E7D32);
    final isDeleting = reviewId != null && reviewId == _deletingReviewId;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                radius: 20,
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display the actual username
                  Text(
                    displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  // Display rating stars
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
                            size: 16,
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
                    ],
                  ),
                ],
              ),
              Spacer(),
              Row(
                children: [
                  Text(
                    date,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  // If a delete function is provided, show the delete icon
                  if (onDelete != null) ...[
                    SizedBox(width: 8),
                    isDeleting
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.red[400]!),
                            ),
                          )
                        : IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red[400],
                            ),
                            onPressed: onDelete,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            tooltip: 'Delete review',
                          ),
                  ],
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
