import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:project/cartpage.dart';
import '../services/cart_service.dart';
import '../models/cart_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecommendationPage extends StatefulWidget {
  final Map<String, dynamic>? analysisResults;

  const RecommendationPage({
    super.key,
    this.analysisResults,
  });

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _showEconomicFilter = false;
  bool _showNearbyFilter = false; // New state for nearby filter
  bool _connectionError = false;
  late TabController _tabController;
  int _selectedTabIndex = 0;

  // Cart service instance
  final CartService _cartService = CartService();

  // Green color scheme (matching the existing app)
  final Color _primaryColor = const Color(0xFF1E8449); // Deep green
  final Color _secondaryColor = const Color(0xFF58D68D); // Medium green
  final Color _accentColor = const Color(0xFFFF9800); // Amber accent
  final Color _backgroundColor =
      const Color(0xFFF8F9FA); // Light grey background
  final Color _cardColor = Colors.white;
  final Color _textColor = const Color(0xFF2C3E50); // Dark grey text

  // Skin conditions list that will be populated from analysis results
  late List<Map<String, dynamic>> _skinConditions;

  // Products list that will be populated from the backend
  List<Map<String, dynamic>> _recommendedProducts = [];

  // Parapharmacies with their products
  List<Map<String, dynamic>> _parapharmacyRecommendations = [];

  // Selected parapharmacy for detailed view
  String? _selectedParapharmacyId;

  // API base URLs
  final String _flaskApiBaseUrl = 'http://10.0.2.2:5000'; // Flask server for AI
  final String _nodeApiBaseUrl =
      'http://10.0.2.2:3000'; // Node.js server for static files
  // Use 'http://127.0.0.1:5000' and 'http://127.0.0.1:3000' for iOS simulator

  // Fallback products in case of connection error
  final List<Map<String, dynamic>> _fallbackProducts = [];

  // Stream subscription for cart updates
  int _cartItemCount = 0;

  // User ID for location-based filtering
  String? _userId;

  // Maximum distance for nearby filter (in km)
  int _maxDistance = 500000;

  List<Map<String, dynamic>> get _filteredProducts {
    if (_connectionError) {
      return _fallbackProducts;
    }

    // Flatten all products from all parapharmacies
    List<Map<String, dynamic>> allProducts = [];
    for (var parapharmacy in _parapharmacyRecommendations) {
      for (var anomalyGroup in parapharmacy['anomaly_products']) {
        allProducts
            .addAll(List<Map<String, dynamic>>.from(anomalyGroup['products']));
      }
    }

    return allProducts;
  }

  @override
  void initState() {
    super.initState();

    // Initialize tab controller
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });

    // Process analysis results to create skin conditions list
    _processAnalysisResults();

    // Load user ID from shared preferences
    _loadUserId().then((_) {
      // Fetch product recommendations from backend
      _fetchRecommendations();
    });

    // Listen to cart updates
    _cartService.cartStream.listen((items) {
      setState(() {
        _cartItemCount = _cartService.itemCount;
      });
    });
  }

  // Load user ID from shared preferences
  Future<void> _loadUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString("userId");

      setState(() {
        _userId = storedUserId;
      });

      print("Loaded user ID from SharedPreferences: $_userId");

      // Check if user ID is in the correct format
      if (_userId == null || _userId!.isEmpty) {
        print(
            "WARNING: User ID is null or empty. Nearby filtering will not work.");

        // Try to load from 'user_id' key instead (used by AuthService)
        final authUserId = prefs.getString("user_id");
        if (authUserId != null && authUserId.isNotEmpty) {
          setState(() {
            _userId = authUserId;
          });
          print("Found user ID from AuthService: $_userId");
        }
      }

      // Validate MongoDB ObjectId format
      if (_userId != null && _userId!.isNotEmpty) {
        if (_userId!.length != 24) {
          print(
              "WARNING: User ID does not appear to be a valid MongoDB ObjectId. Nearby filtering may not work.");
        } else {
          print(
              "User ID is valid. Nearby filtering should work if user has location data.");
        }
      }
    } catch (e) {
      print("Error loading user ID: $e");
      setState(() {
        _userId = null;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _processAnalysisResults() {
    _skinConditions = [];

    if (widget.analysisResults != null &&
        widget.analysisResults!.containsKey('all_probs')) {
      // Get the predicted class and confidence
      String primaryCondition =
          widget.analysisResults!['predicted_class'] ?? 'Unknown';
      double primaryConfidence = widget.analysisResults!['confidence'] ?? 0.0;

      // Add the primary condition with high severity
      _skinConditions.add({
        'name': _formatConditionName(primaryCondition),
        'probability': primaryConfidence,
        'percentage': (primaryConfidence * 100).toInt(),
        'severity': _getSeverityFromProbability(primaryConfidence),
      });

      // Process other conditions from all_probs
      Map<String, dynamic> allProbs = widget.analysisResults!['all_probs'];

      // Sort probabilities in descending order
      List<MapEntry<String, dynamic>> sortedEntries = allProbs.entries.toList()
        ..sort((a, b) => (b.value as double).compareTo(a.value as double));

      // Skip the first one (already added as primary) and take the next 4
      for (var entry in sortedEntries.skip(1).take(4)) {
        if (entry.key != primaryCondition) {
          _skinConditions.add({
            'name': _formatConditionName(entry.key),
            'probability': entry.value as double,
            'percentage': ((entry.value as double) * 100).toInt(),
            'severity': _getSeverityFromProbability(entry.value as double),
          });
        }
      }
    } else {
      // Fallback to mock data if no analysis results
      _skinConditions = [
        {
          'name': 'Acne',
          'probability': 0.0,
          'percentage': 0,
          'severity': 'Low'
        },
        {
          'name': 'Eczema',
          'probability': 0.8,
          'percentage': 80,
          'severity': 'High'
        },
      ];
    }
  }

  Future<void> _fetchRecommendations() async {
    try {
      // Prepare the request body
      final Map<String, dynamic> requestBody = {
        'skin_type': _determineSkinType(),
        'anomalies': _skinConditions
            .map((condition) => {
                  'name': condition['name'],
                  'percentage': condition['percentage'],
                })
            .toList(),
      };

      // Add user ID and distance filtering parameters if nearby filter is active
      if (_showNearbyFilter && _userId != null) {
        requestBody['user_id'] = _userId;
        requestBody['filter_by_distance'] = true;
        requestBody['max_distance'] = _maxDistance;
        print(
            'Adding nearby filter parameters: user_id=$_userId, max_distance=$_maxDistance');
      }

      print('Request body: ${jsonEncode(requestBody)}');

      // Determine which endpoint to use based on filters
      String endpoint;

      if (_showNearbyFilter && _userId != null) {
        // Use the nearby endpoint if nearby filter is active
        endpoint = '$_flaskApiBaseUrl/recommend/nearby';
        print('Using nearby endpoint: $endpoint');

        // Add price sorting if economic filter is also active
        if (_showEconomicFilter) {
          requestBody['sort_by_price'] = true;
          print('Adding price sorting to nearby request');
        }
      } else if (_showEconomicFilter) {
        // Use economy endpoint if only economic filter is active
        endpoint = '$_flaskApiBaseUrl/recommend/economy';
        print('Using economy endpoint: $endpoint');
      } else {
        // Use standard endpoint if no filters are active
        endpoint = '$_flaskApiBaseUrl/recommend';
        print('Using standard endpoint: $endpoint');
      }

      // Make the API request
      print('Sending request to: $endpoint');
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 10));
      print('Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('API Response: ${response.body}');

        // Check if there's a message in the response (for empty results)
        if (data.containsKey('message')) {
          print('API Message: ${data['message']}');
        }

        final List<dynamic> recommendations = data['recommendations'] ?? [];
        print('Found ${recommendations.length} parapharmacy recommendations');

        setState(() {
          _parapharmacyRecommendations =
              recommendations.map<Map<String, dynamic>>((item) {
            // Process each parapharmacy recommendation
            final List<dynamic> anomalyProductsList =
                item['anomaly_products'] ?? [];

            return {
              'parapharmacy_id': item['parapharmacy_id'],
              'parapharmacy_name':
                  item['parapharmacy_name'] ?? 'Unknown Parapharmacy',
              'distance': item['distance'], // Include distance if available
              'anomaly_products':
                  anomalyProductsList.map<Map<String, dynamic>>((anomalyGroup) {
                // Process each anomaly group
                final List<dynamic> productsList =
                    anomalyGroup['products'] ?? [];

                return {
                  'anomaly': anomalyGroup['anomaly'],
                  'products': productsList.map<Map<String, dynamic>>((product) {
                    // Process each product
                    String imagePath = product['image'] ?? '';

                    return {
                      'id': product['_id'] ?? product['id'] ?? '',
                      'name': product['name'] ?? 'Unknown Product',
                      'price': product['price'] ?? 0.0,
                      'description':
                          product['description'] ?? 'No description available',
                      'ingredients': product['ingredients'] != null
                          ? List<String>.from(product['ingredients'])
                          : [],
                      'image': imagePath,
                      'imageUrl': _getImageUrl(imagePath),
                      'forCondition':
                          anomalyGroup['anomaly'] ?? 'All Skin Types',
                      'intelfaceassis': product['intelfaceassis'] ?? [],
                      'parapharmacy_name':
                          item['parapharmacy_name'] ?? 'Unknown Parapharmacy',
                      'category': product['category'] ?? 'Skincare',
                      'hasDiscount': product['hasDiscount'] ?? false,
                      'discountPercentage': product['discountPercentage'] ?? 0,
                      'quantity': product['quantity'] ?? 0,
                      'howToUse': product['howToUse'] ?? '',
                      'brand': product['brand'] ?? 'Unknown Brand',
                    };
                  }).toList(),
                };
              }).toList(),
            };
          }).toList();

          _isLoading = false;
          _connectionError = false;

          // Debug output
          for (var para in _parapharmacyRecommendations) {
            print('Parapharmacy: ${para['parapharmacy_name']}');
            if (para['distance'] != null) {
              print('Distance: ${para['distance']} km');
            }

            for (var anomaly in para['anomaly_products']) {
              for (var product in anomaly['products']) {
                print('Product: ${product['name']}');
                print('Image path: ${product['image']}');
                print('Image URL: ${product['imageUrl']}');
              }
            }
          }

          // Check if we got any recommendations
          if (_parapharmacyRecommendations.isEmpty) {
            print(
                'WARNING: No recommendations returned. This could be because:');
            print(
                '1. No parapharmacies were found within the specified distance');
            print('2. User location data is missing in the database');
            print('3. No products match the skin conditions');
          }
        });
      } else {
        // Handle error response
        print('API Error: ${response.statusCode} - ${response.body}');
        setState(() {
          _parapharmacyRecommendations = [];
          _isLoading = false;
          _connectionError = true;
        });
      }
    } catch (e) {
      // Handle connection error
      print('Connection Error: $e');
      setState(() {
        _parapharmacyRecommendations = [];
        _isLoading = false;
        _connectionError = true;
      });
    }
  }

  // Add a product to cart
  Future<void> _addToCart(Map<String, dynamic> product) async {
    try {
      await _cartService.addItem(
        id: product['id'],
        name: product['name'],
        brand: product['brand'] ?? 'Unknown Brand',
        description: product['description'],
        price: product['price'].toDouble(),
        discountedPrice: product['hasDiscount']
            ? product['price'] * (1 - (product['discountPercentage'] / 100))
            : null,
        imageUrl: product['imageUrl'],
        quantity: 1,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${product['name']} added to cart!',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: _primaryColor,
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
        ),
      );
    } catch (e) {
      print('Error adding to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Failed to add product to cart. Please try again.',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Add all recommended products to cart
  Future<void> _addAllToCart() async {
    try {
      // Get all products from all parapharmacies
      List<Map<String, dynamic>> allProducts = [];
      for (var parapharmacy in _parapharmacyRecommendations) {
        for (var anomalyGroup in parapharmacy['anomaly_products']) {
          allProducts.addAll(
              List<Map<String, dynamic>>.from(anomalyGroup['products']));
        }
      }

      // Add each product to cart
      for (var product in allProducts) {
        await _cartService.addItem(
          id: product['id'],
          name: product['name'],
          brand: product['brand'] ?? 'Unknown Brand',
          description: product['description'],
          price: product['price'].toDouble(),
          discountedPrice: product['hasDiscount']
              ? product['price'] * (1 - (product['discountPercentage'] / 100))
              : null,
          imageUrl: product['imageUrl'],
          quantity: 1,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${allProducts.length} products added to cart!',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: _primaryColor,
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
        ),
      );
    } catch (e) {
      print('Error adding all to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Failed to add products to cart. Please try again.',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Convert local image path to a full URL
  String _getImageUrl(String imagePath) {
    if (imagePath.isEmpty) {
      return '';
    }

    // Replace backslashes with forward slashes for URL
    String formattedPath = imagePath.replaceAll('\\', '/');

    // Use the Node.js server URL instead of the Flask server URL
    // Debug the image path
    print('Original image path: $imagePath');
    print('Formatted image path: $formattedPath');
    print('Full image URL: $_nodeApiBaseUrl/$formattedPath');

    // Construct the full URL to the image
    return '$_nodeApiBaseUrl/$formattedPath';
  }

  String _determineSkinType() {
    // Determine skin type based on morning skin feel from analysis results
    if (widget.analysisResults != null &&
        widget.analysisResults!.containsKey('morningSkinFeel')) {
      String feel = widget.analysisResults!['morningSkinFeel'];

      if (feel.contains('Oily')) return 'oily';
      if (feel.contains('Dry') || feel.contains('Tight')) return 'dry';
      if (feel.contains('Combination')) return 'combination';
      if (feel.contains('Sensitive')) return 'sensitive';
    }

    // Default to combination if no specific type is determined
    return 'Combination';
  }

  String _formatConditionName(String condition) {
    // Convert snake_case or camelCase to Title Case with spaces
    String formatted = condition
        .replaceAllMapped(
            RegExp(r'_([a-z])'), (match) => ' ${match.group(1)!.toUpperCase()}')
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'),
            (match) => '${match.group(1)} ${match.group(2)}');

    // Capitalize first letter
    return formatted.substring(0, 1).toUpperCase() + formatted.substring(1);
  }

  String _getSeverityFromProbability(double probability) {
    if (probability >= 0.7) {
      return 'High';
    } else if (probability >= 0.4) {
      return 'Mid';
    } else {
      return 'Low';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'IntelFaceAssis',
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Colors.white,
              fontFamily: 'Poppins'),
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Cart icon with badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.shopping_cart,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CartPage()),
                  );
                },
              ),
              if (_cartItemCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: _accentColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _cartItemCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingView() : _buildAnalysisResultsView(),
      bottomNavigationBar: _isLoading
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _addAllToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'ADD ALL RECOMMENDED PRODUCTS TO CART',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Poppins'),
                ),
              ),
            ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'Analyzing your skin profile...',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: _textColor,
                fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'We\'re creating personalized recommendations based on your skin analysis',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: _textColor.withOpacity(0.7),
                  fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResultsView() {
    return Column(
      children: [
        // Analysis date card
        _buildAnalysisDateCard(),

        // Connection error banner (if applicable)
        if (_connectionError) _buildConnectionErrorBanner(),

        // Tab bar for switching between views
        Container(
          color: _primaryColor,
          child: TabBar(
            controller: _tabController,
            indicatorColor: _accentColor,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              fontSize: 14,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.medical_information),
                text: 'Skin Analysis',
              ),
              Tab(
                icon: Icon(Icons.recommend),
                text: 'Recommendations',
              ),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Skin Analysis Tab
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildSkinConditionsSection(),
                ),
              ),

              // Recommendations Tab
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildProductRecommendations(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionErrorBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.red.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connection Error',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                      fontFamily: 'Poppins'),
                ),
                const SizedBox(height: 4),
                Text(
                  'Showing general recommendations. Please check your connection and try again.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                      fontFamily: 'Poppins'),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.red.shade700),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _fetchRecommendations();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisDateCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _primaryColor,
            Color.lerp(_primaryColor, _secondaryColor, 0.5)!,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.face_retouching_natural,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Skin Analysis Results',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Poppins'),
                ),
                Text(
                  'Analysis completed on ${_getFormattedDate()}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontFamily: 'Poppins'),
                ),
              ],
            ),
          ),
          // Mode indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getFilterBadgeColor(),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getFilterIcon(),
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  _getFilterText(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for filter badge
  Color _getFilterBadgeColor() {
    if (_showNearbyFilter) {
      return Colors.blue;
    } else if (_showEconomicFilter) {
      return _accentColor;
    } else {
      return Colors.white.withOpacity(0.2);
    }
  }

  IconData _getFilterIcon() {
    if (_showNearbyFilter) {
      return Icons.location_on;
    } else if (_showEconomicFilter) {
      return Icons.attach_money;
    } else {
      return Icons.star;
    }
  }

  String _getFilterText() {
    if (_showNearbyFilter && _showEconomicFilter) {
      return 'Nearby & Economy';
    } else if (_showNearbyFilter) {
      return 'Nearby';
    } else if (_showEconomicFilter) {
      return 'Economy Mode';
    } else {
      return 'AI Matched';
    }
  }

  Widget _buildSkinConditionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.medical_information,
                color: _accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Detected Skin Conditions',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                    fontFamily: 'Poppins'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: _skinConditions
                .map((condition) => _buildConditionItem(
                      condition['name'],
                      condition['probability'],
                      condition['severity'],
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.grey[600],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This analysis is not a medical diagnosis. Please consult a dermatologist for professional advice.',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.4,
                        fontFamily: 'Poppins'),
                  ),
                ),
              ],
            ),
          ),

          // Recommended routine based on skin conditions
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: _primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Recommended Skincare Routine',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecommendedRoutine(),

          // View recommendations button
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.recommend, color: Colors.white),
              label: const Text(
                'VIEW PRODUCT RECOMMENDATIONS',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                _tabController.animateTo(1);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedRoutine() {
    // Determine primary skin condition
    String primaryCondition =
        _skinConditions.isNotEmpty ? _skinConditions.first['name'] : 'General';

    // Routine steps based on primary condition
    List<Map<String, dynamic>> routineSteps = [];

    if (primaryCondition.contains('Acne')) {
      routineSteps = [
        {
          'time': 'Morning',
          'steps': [
            'Gentle cleanser with salicylic acid',
            'Alcohol-free toner',
            'Lightweight oil-free moisturizer',
            'Broad-spectrum SPF 30+ sunscreen',
          ]
        },
        {
          'time': 'Evening',
          'steps': [
            'Oil-free makeup remover',
            'Gentle cleanser',
            'Treatment with benzoyl peroxide or salicylic acid',
            'Oil-free moisturizer',
          ]
        },
      ];
    } else if (primaryCondition.contains('Eczema')) {
      routineSteps = [
        {
          'time': 'Morning',
          'steps': [
            'Gentle fragrance-free cleanser',
            'Ceramide-rich moisturizer',
            'Mineral-based sunscreen',
          ]
        },
        {
          'time': 'Evening',
          'steps': [
            'Gentle fragrance-free cleanser',
            'Hydrating serum with hyaluronic acid',
            'Thick moisturizer with ceramides',
            'Occlusive balm on dry patches if needed',
          ]
        },
      ];
    } else {
      // Default routine
      routineSteps = [
        {
          'time': 'Morning',
          'steps': [
            'Gentle cleanser',
            'Hydrating toner',
            'Antioxidant serum',
            'Moisturizer',
            'Sunscreen SPF 30+',
          ]
        },
        {
          'time': 'Evening',
          'steps': [
            'Makeup remover (if needed)',
            'Gentle cleanser',
            'Treatment serum',
            'Moisturizer',
          ]
        },
      ];
    }

    return Column(
      children: routineSteps.map((routine) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _secondaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      routine['time'] == 'Morning'
                          ? Icons.wb_sunny
                          : Icons.nightlight_round,
                      color: _primaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      routine['time'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _textColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: (routine['steps'] as List).map<Widget>((step) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: _primaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              step,
                              style: TextStyle(
                                fontSize: 14,
                                color: _textColor.withOpacity(0.8),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConditionItem(
      String condition, double probability, String severity) {
    Color severityColor;

    if (severity == 'Low') {
      severityColor = Colors.green;
    } else if (severity == 'Mid') {
      severityColor = Colors.orange;
    } else {
      severityColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${(probability * 100).toInt()}%',
                style: TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  condition,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                      fontFamily: 'Poppins'),
                ),
                const SizedBox(height: 4),
                Text(
                  'Detection probability',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins'),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: severityColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              severity,
              style: TextStyle(
                  color: severityColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRecommendations() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with recommended products text and filter badge
          Row(
            children: [
              Icon(
                Icons.recommend,
                color: _primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                // Use Expanded to prevent overflow
                child: Text(
                  'Recommended Products',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                constraints:
                    BoxConstraints(maxWidth: 120), // Add max width constraint
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getFilterBadgeColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min, // Keep content tight
                  children: [
                    Icon(
                      _getFilterIcon(),
                      color: _getFilterBadgeColor(),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      // Allow text to wrap/ellipsis if needed
                      child: Text(
                        _getFilterText(),
                        style: TextStyle(
                          color: _getFilterBadgeColor(),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filter chips row
          SingleChildScrollView(
            // Wrap in SingleChildScrollView for horizontal scrolling
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'Filter:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _textColor,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  // Add constraints to filter chips
                  constraints: BoxConstraints(maxWidth: 120),
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 16,
                          color: _showEconomicFilter
                              ? Colors.white
                              : _primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Economic',
                            style: TextStyle(
                              color: _showEconomicFilter
                                  ? Colors.white
                                  : _primaryColor,
                              fontSize: 12,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                    selected: _showEconomicFilter,
                    onSelected: (selected) {
                      setState(() {
                        _showEconomicFilter = selected;
                        _isLoading = true;
                      });
                      _fetchRecommendations();
                    },
                    selectedColor: _primaryColor,
                    checkmarkColor: Colors.white,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: _primaryColor,
                        width: 1,
                      ),
                    ),
                  ),
                ),
                if (_userId != null) ...[
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 120),
                    child: FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color:
                                _showNearbyFilter ? Colors.white : Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Nearby',
                              style: TextStyle(
                                color: _showNearbyFilter
                                    ? Colors.white
                                    : Colors.blue,
                                fontSize: 12,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                      selected: _showNearbyFilter,
                      onSelected: (selected) {
                        setState(() {
                          _showNearbyFilter = selected;
                          _isLoading = true;
                        });
                        _fetchRecommendations();
                      },
                      selectedColor: Colors.blue,
                      checkmarkColor: Colors.white,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: Colors.blue,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_connectionError)
            _buildProductsList(_fallbackProducts)
          else if (_parapharmacyRecommendations.isEmpty)
            _buildNoProductsMessage()
          else
            _buildParapharmacyRecommendations(),
        ],
      ),
    );
  }

  Widget _buildParapharmacyRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _parapharmacyRecommendations.map((parapharmacy) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Parapharmacy header
            if (parapharmacy['parapharmacy_name'] != null &&
                parapharmacy['parapharmacy_name'].isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12, top: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _secondaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.store,
                      color: _secondaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        parapharmacy['parapharmacy_name'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _textColor,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    // Display distance if available
                    if (parapharmacy['distance'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.blue,
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${parapharmacy['distance']} km',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_showEconomicFilter && parapharmacy['distance'] == null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Economy',
                          style: TextStyle(
                            color: _accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Anomaly groups
            ...(parapharmacy['anomaly_products'] as List<Map<String, dynamic>>)
                .map((anomalyGroup) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Anomaly header
                  Container(
                    margin: const EdgeInsets.only(bottom: 8, top: 16),
                    child: Row(
                      children: [
                        Icon(
                          _getIconForAnomaly(anomalyGroup['anomaly']),
                          color: _accentColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'For ${anomalyGroup['anomaly']}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _accentColor,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Products for this anomaly
                  ...(anomalyGroup['products'] as List<Map<String, dynamic>>)
                      .map((product) => _buildProductCard(product))
                      .toList(),
                ],
              );
            }).toList(),
          ],
        );
      }).toList(),
    );
  }

  IconData _getIconForAnomaly(String anomaly) {
    switch (anomaly.toLowerCase()) {
      case 'acne':
        return Icons.face_retouching_natural;
      case 'eczema':
        return Icons.healing;
      case 'rosacea':
        return Icons.face;
      case 'psoriasis':
        return Icons.health_and_safety;
      case 'dry skin':
        return Icons.water_drop;
      case 'oily skin':
        return Icons.opacity;
      default:
        return Icons.medical_services;
    }
  }

  Widget _buildProductsList(List<Map<String, dynamic>> products) {
    if (products.isEmpty) {
      return _buildNoProductsMessage();
    }

    return Column(
      children: products.map((product) => _buildProductCard(product)).toList(),
    );
  }

  Widget _buildNoProductsMessage() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No matching products found',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _textColor,
                fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 8),
          Text(
            'We couldn\'t find products that match your skin conditions. Please try adjusting your filters.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: Colors.grey[600], fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
            child: _buildProductImage(product),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'],
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                      fontFamily: 'Poppins'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Price - slightly enhanced
                    Text(
                      '${product['price'].toStringAsFixed(2)} DT',
                      style: TextStyle(
                        fontSize: 18, // Slightly larger
                        fontWeight: FontWeight.w700, // Bolder
                        color: _accentColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(width: 16), // Increased spacing

                    // Condition tag - improved layout with original colors
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, // More padding
                        vertical: 6, // More padding
                      ),
                      decoration: BoxDecoration(
                        color: _secondaryColor
                            .withOpacity(0.08), // Very subtle background
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _secondaryColor
                              .withOpacity(0.3), // Original border color
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'For ${product['forCondition']}', // Removed colon for cleaner look
                        style: TextStyle(
                          fontSize: 13, // Slightly larger
                          color: _secondaryColor, // Original text color
                          fontWeight: FontWeight.w600, // Slightly bolder
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  product['description'],
                  style: TextStyle(
                      fontSize: 14,
                      color: _textColor.withOpacity(0.8),
                      height: 1.4,
                      fontFamily: 'Poppins'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                if ((product['ingredients'] as List).isNotEmpty)
                  SizedBox(
                    height: 40,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: (product['ingredients'] as List)
                            .map<Widget>((ingredient) {
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              ingredient.toString(),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontFamily: 'Poppins'),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_cart,
                        size: 16, color: Colors.white),
                    label: const Text(
                      'ADD TO CART',
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => _addToCart(product),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(Map<String, dynamic> product) {
    // Debug the product image data
    print('Product: ${product['name']}');
    print('Image path: ${product['image']}');
    print('Image URL: ${product['imageUrl']}');

    // Check if we have a valid image URL
    if (product.containsKey('imageUrl') &&
        product['imageUrl'].toString().isNotEmpty) {
      return Image.network(
        product['imageUrl'],
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          print('Failed URL: ${product['imageUrl']}');
          return _buildFallbackImage();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Container(
            height: 180,
            width: double.infinity,
            color: _primaryColor.withOpacity(0.1),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
            ),
          );
        },
      );
    } else if (product.containsKey('imageAsset') &&
        product['imageAsset'].toString().isNotEmpty) {
      // Try to load from assets
      return Image.asset(
        product['imageAsset'],
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackImage();
        },
      );
    } else {
      return _buildFallbackImage();
    }
  }

  Widget _buildFallbackImage() {
    return Container(
      height: 180,
      width: double.infinity,
      color: _primaryColor.withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image,
              size: 50,
              color: _primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'No image available',
              style: TextStyle(
                color: _primaryColor.withOpacity(0.7),
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}
