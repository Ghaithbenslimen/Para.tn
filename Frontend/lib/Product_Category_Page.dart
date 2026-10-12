import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/category_page.dart';
import 'package:project/product_detailed_page.dart';
import '../models/product_model.dart';
import '../services/store_service.dart';

class ProductCategoryPage extends StatefulWidget {
  final String categoryName;
  final String parapharmacyId;

  const ProductCategoryPage({
    Key? key,
    required this.categoryName,
    required this.parapharmacyId,
  }) : super(key: key);

  @override
  _ProductCategoryPageState createState() => _ProductCategoryPageState();
}

class _ProductCategoryPageState extends State<ProductCategoryPage>
    with SingleTickerProviderStateMixin {
  // Backend Service Instance
  final StoreService _storeService = StoreService();

  // Define a primary color to stick to the theme
  final Color primaryColor = const Color(0xFF2E7D32);

  // State variables
  String _selectedFilter = 'All';
  String _sortBy = 'Popular';
  RangeValues _priceRange = const RangeValues(0, 200);
  List<String> _selectedSkinTypes = [];
  String _searchQuery = '';
  bool _isSearchVisible = false;
  bool _isFilterExpanded = false;

  // Animation controller for filter expansion
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // Filter options
  List<String> _filters = ['All'];
  List<String> _skinTypes = ['All'];

  final List<String> _sortOptions = [
    'Popular',
    'Price: Low to High',
    'Price: High to Low',
    'Newest'
  ];

  // Backend Data
  List<Product> _products = [];
  List<Product> _allProducts = []; // Store all products for local filtering
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadFilterOptions();
    _fetchProducts();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadFilterOptions() async {
    try {
      // Load categories for this parapharmacy
      final categories =
          await _storeService.getParapharmacyCategories(widget.parapharmacyId);

      // Load skin types for this parapharmacy
      final skinTypes =
          await _storeService.getParapharmacySkinTypes(widget.parapharmacyId);

      setState(() {
        _filters = ['All', ...categories];
        _skinTypes = ['All', ...skinTypes];

        // If a category was specified in the constructor, select it
        if (widget.categoryName.isNotEmpty &&
            _filters.contains(widget.categoryName)) {
          _selectedFilter = widget.categoryName;
        }
      });
    } catch (e) {
      debugPrint('Error loading filter options: $e');
      // Don't show an error message to avoid disrupting the user experience
      // Just use the default filters
    }
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final products = await _storeService.getParapharmacyProducts(
        parapharmacyId: widget.parapharmacyId,
        category: _selectedFilter == 'All' ? null : _selectedFilter,
        skinType:
            _selectedSkinTypes.isEmpty || _selectedSkinTypes.contains('All')
                ? null
                : _selectedSkinTypes
                    .first, // Currently only supporting one skin type filter
        sortBy: _sortBy,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );

      setState(() {
        _allProducts = products; // Store all products
        _products = _applyLocalFilters(products); // Apply local filters
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching products: $e';
        _isLoading = false;
      });
      debugPrint(_errorMessage);
    }
  }

  // Handle search input with debounce
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query != _searchQuery) {
        setState(() {
          _searchQuery = query;
        });
        _fetchProducts();
      }
    });
  }

  // Apply all local filters
  List<Product> _applyLocalFilters(List<Product> products) {
    List<Product> filtered = List.from(products);

    // Apply price filter
    filtered = _applyPriceFilter(filtered);

    return filtered;
  }

  // Apply price filter locally (since the backend doesn't support price filtering)
  List<Product> _applyPriceFilter(List<Product> products) {
    return products.where((product) {
      final price = product.price;
      return price >= _priceRange.start && price <= _priceRange.end;
    }).toList();
  }

  // Toggle search bar visibility
  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        _searchQuery = '';
        _fetchProducts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _isSearchVisible
            ? _buildSearchField()
            : Text(
                widget.categoryName.isEmpty
                    ? 'All Products'
                    : widget.categoryName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search,
                color: Colors.black87),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: Icon(
              _isFilterExpanded ? Icons.filter_list_off : Icons.filter_list,
              color: Colors.black87,
            ),
            onPressed: () {
              setState(() {
                _isFilterExpanded = !_isFilterExpanded;
                if (_isFilterExpanded) {
                  _animationController.forward();
                } else {
                  _animationController.reverse();
                }
              });
            },
          ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: primaryColor,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading products...',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Something went wrong',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _fetchProducts,
                        icon: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                        ),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Animated Filter Panel - Fixed height and visibility issues
                    if (_isFilterExpanded)
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Filter Products',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    _showFilterBottomSheet(context);
                                  },
                                  icon: Icon(Icons.tune,
                                      size: 18, color: primaryColor),
                                  label: Text(
                                    'Advanced',
                                    style: TextStyle(color: primaryColor),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Categories',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 40,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _filters.length,
                                itemBuilder: (context, index) {
                                  final filter = _filters[index];
                                  final isSelected = _selectedFilter == filter;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: FilterChip(
                                      label: Text(filter),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          _selectedFilter = filter;
                                        });
                                        _fetchProducts();
                                      },
                                      selectedColor:
                                          primaryColor.withOpacity(0.2),
                                      checkmarkColor: primaryColor,
                                      backgroundColor: Colors.grey[100],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(
                                          color: isSelected
                                              ? primaryColor
                                              : Colors.transparent,
                                          width: 1,
                                        ),
                                      ),
                                      labelStyle: TextStyle(
                                        color: isSelected
                                            ? primaryColor
                                            : Colors.black87,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      elevation: isSelected ? 2 : 0,
                                      shadowColor: isSelected
                                          ? primaryColor.withOpacity(0.3)
                                          : Colors.transparent,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Skin Types',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 40,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _skinTypes.length,
                                itemBuilder: (context, index) {
                                  final skinType = _skinTypes[index];
                                  final isSelected =
                                      _selectedSkinTypes.contains(skinType);
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: FilterChip(
                                      label: Text(skinType),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          if (skinType == 'All') {
                                            _selectedSkinTypes =
                                                selected ? ['All'] : [];
                                          } else {
                                            if (selected) {
                                              _selectedSkinTypes.remove('All');
                                              _selectedSkinTypes.add(skinType);
                                            } else {
                                              _selectedSkinTypes
                                                  .remove(skinType);
                                            }

                                            if (_selectedSkinTypes.isEmpty) {
                                              _selectedSkinTypes.add('All');
                                            }
                                          }
                                        });
                                        _fetchProducts();
                                      },
                                      selectedColor:
                                          primaryColor.withOpacity(0.2),
                                      checkmarkColor: primaryColor,
                                      backgroundColor: Colors.grey[100],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(
                                          color: isSelected
                                              ? primaryColor
                                              : Colors.transparent,
                                          width: 1,
                                        ),
                                      ),
                                      labelStyle: TextStyle(
                                        color: isSelected
                                            ? primaryColor
                                            : Colors.black87,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      elevation: isSelected ? 2 : 0,
                                      shadowColor: isSelected
                                          ? primaryColor.withOpacity(0.3)
                                          : Colors.transparent,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Main Content
                    Expanded(
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          // Promotion Banner with carousel background
                          SliverToBoxAdapter(
                            child: Container(
                              height: 200,
                              margin: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  // Promotion Carousel as background
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: PromotionCarousel(
                                      imagePaths: const [
                                        'assets/website_landscapeArtboard_1_copy_2.webp',
                                        'assets/promotion2.jpg',
                                        'assets/promotion3.jpeg',
                                      ],
                                      interval: const Duration(seconds: 5),
                                      animationDuration:
                                          const Duration(milliseconds: 500),
                                    ),
                                  ),
                                  // Overlay gradient for readability
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.black.withOpacity(0.5),
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.2),
                                        ],
                                        stops: const [0.0, 0.6, 1.0],
                                      ),
                                    ),
                                  ),
                                  // Promotional text and deal tag
                                  Positioned(
                                    left: 20,
                                    top: 20,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color:
                                                primaryColor.withOpacity(0.9),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.2),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Text(
                                            'DEAL 50% OFF',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'HERE WE GO',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            shadows: [
                                              Shadow(
                                                offset: Offset(0, 2),
                                                blurRadius: 4,
                                                color: Colors.black45,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'Limited Time Offer',
                                            style: TextStyle(
                                              color: primaryColor,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Sort by row
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '${_products.length}',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                      const Text(
                                        ' Products',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      _showSortOptions(context);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            'Sort: $_sortBy',
                                            style: TextStyle(
                                              color: primaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(Icons.arrow_drop_down,
                                              color: primaryColor, size: 20),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Products grid
                          _products.isEmpty
                              ? SliverFillRemaining(
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.search_off,
                                            size: 80, color: Colors.grey[400]),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'No products found',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Try adjusting your filters or search',
                                          style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 16),
                                        ),
                                        const SizedBox(height: 24),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _searchController.clear();
                                              _searchQuery = '';
                                              _selectedFilter = 'All';
                                              _selectedSkinTypes = ['All'];
                                              _priceRange =
                                                  const RangeValues(0, 200);
                                            });
                                            _fetchProducts();
                                          },
                                          icon: const Icon(
                                            Icons.refresh,
                                            color: Colors.white,
                                          ),
                                          label: const Text('Reset Filters'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : SliverPadding(
                                  padding: const EdgeInsets.all(16),
                                  sliver: SliverGrid(
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.63,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                    ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final product = _products[index];
                                        final parapharmacy =
                                            "Green Pharmacy"; // Default parapharmacy

                                        return _buildProductCard(
                                          product: product,
                                          parapharmacy: parapharmacy,
                                        );
                                      },
                                      childCount: _products.length,
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
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
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (value) {
          _onSearchChanged(value);
        },
      ),
    );
  }

  Widget _buildProductCard({
    required Product product,
    required String parapharmacy,
  }) {
    final hasDiscount = product.hasDiscount;
    final originalPrice = product.price;
    final discountedPrice = hasDiscount
        ? originalPrice * (1 - product.discountPercentage / 100)
        : null;
    final isInStock =
        product.quantity > 0; // Add this line to check stock status

    // Get the image URL
    String imageUrl = '';
    if (product.imagePath.isNotEmpty) {
      imageUrl = _storeService.getFullImageUrl(product.imagePath);
    }

    // For demo purposes, use a placeholder if no image is available
    final imageIndex = product.id.hashCode % 5 + 1;

    return Hero(
      tag: 'product-${product.id}',
      child: Material(
        borderRadius: BorderRadius.circular(20),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsPage(
                  name: product.name,
                  brand: product.category,
                  price: originalPrice,
                  discountedPrice: discountedPrice,
                  rating: 4.5,
                  reviewCount: 128,
                  imageUrl: imageUrl.isNotEmpty
                      ? imageUrl
                      : 'assets/product$imageIndex.jpg',
                  description: product.description,
                  howToUse: product.howToUse,
                  parapharmacyPrices: [
                    {'name': parapharmacy, 'price': originalPrice},
                  ],
                  productId: product.id,
                  quantity:
                      product.quantity, // Pass the quantity to the details page
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image with discount badge overlay
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.grey[100]!,
                              Colors.white,
                            ],
                          ),
                        ),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error loading image: $error');
                                  return Image.asset(
                                    'assets/product$imageIndex.jpg',
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      height: 160,
                                      color: Colors.green[100],
                                      child: Icon(Icons.image,
                                          color: primaryColor, size: 50),
                                    ),
                                  );
                                },
                              )
                            : Image.asset(
                                'assets/product$imageIndex.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  height: 160,
                                  color: Colors.green[100],
                                  child: Icon(Icons.image,
                                      color: primaryColor, size: 50),
                                ),
                              ),
                      ),
                    ),
                    if (hasDiscount)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4), // Reduced padding
                          decoration: BoxDecoration(
                            color: Colors.red[600],
                            borderRadius:
                                BorderRadius.circular(8), // Smaller radius
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${product.discountPercentage.toInt()}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10, // Smaller font
                            ),
                          ),
                        ),
                      ),
                    // Add Out of Stock badge
                  ],
                ),
                // Product details text - made more compact
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8), // Reduced vertical padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.category,
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 10, // Smaller font
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2), // Reduced spacing
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12, // Smaller font
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4), // Reduced spacing
                      // Price section
                      if (hasDiscount) ...[
                        Text(
                          '${discountedPrice!.toStringAsFixed(2)}\DT',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14, // Smaller font
                          ),
                        ),
                        const SizedBox(height: 0), // Removed spacing
                        Text(
                          '${originalPrice.toStringAsFixed(2)}\DT',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            fontSize: 10, // Smaller font
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ] else
                        Text(
                          '${originalPrice.toStringAsFixed(2)}\DT',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14, // Smaller font
                          ),
                        ),
                      // Add stock status text
                      if (!isInStock)
                        Text(
                          'Out of stock',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Products',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Price Range
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Price Range',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_priceRange.start.toInt()} - ${_priceRange.end.toInt()} \DT',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          RangeSlider(
                            values: _priceRange,
                            min: 0,
                            max: 200,
                            divisions: 20,
                            activeColor: primaryColor,
                            inactiveColor: Colors.grey[300],
                            labels: RangeLabels(
                              '${_priceRange.start.toInt()}\DT',
                              '${_priceRange.end.toInt()}\DT',
                            ),
                            onChanged: (values) {
                              setModalState(() {
                                _priceRange = values;
                              });
                            },
                          ),
                          const SizedBox(height: 24),

                          // Categories
                          const Text(
                            'Categories',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _filters.map((filter) {
                              final isSelected = _selectedFilter == filter;
                              return FilterChip(
                                label: Text(filter),
                                selected: isSelected,
                                selectedColor: primaryColor.withOpacity(0.2),
                                checkmarkColor: primaryColor,
                                backgroundColor: Colors.grey[100],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected
                                        ? primaryColor
                                        : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? primaryColor
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                onSelected: (selected) {
                                  setModalState(() {
                                    _selectedFilter = filter;
                                  });
                                },
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 24),

                          // Skin Types
                          const Text(
                            'Skin Types',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _skinTypes.map((skinType) {
                              final isSelected =
                                  _selectedSkinTypes.contains(skinType);
                              return FilterChip(
                                label: Text(skinType),
                                selected: isSelected,
                                selectedColor: primaryColor.withOpacity(0.2),
                                checkmarkColor: primaryColor,
                                backgroundColor: Colors.grey[100],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected
                                        ? primaryColor
                                        : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? primaryColor
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                onSelected: (selected) {
                                  setModalState(() {
                                    if (skinType == 'All') {
                                      // If "All" is selected, clear other selections
                                      _selectedSkinTypes =
                                          selected ? ['All'] : [];
                                    } else {
                                      // If a specific type is selected, remove "All"
                                      if (selected) {
                                        _selectedSkinTypes.remove('All');
                                        _selectedSkinTypes.add(skinType);
                                      } else {
                                        _selectedSkinTypes.remove(skinType);
                                      }

                                      // If no specific types are selected, select "All"
                                      if (_selectedSkinTypes.isEmpty) {
                                        _selectedSkinTypes.add('All');
                                      }
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              _priceRange = const RangeValues(0, 200);
                              _selectedFilter = 'All';
                              _selectedSkinTypes = ['All'];
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            'Reset',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              // Apply filters
                              _priceRange = _priceRange;
                              _selectedFilter = _selectedFilter;
                              _selectedSkinTypes =
                                  List.from(_selectedSkinTypes);
                            });
                            _fetchProducts(); // Refetch products with new filters
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sort By',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              ..._sortOptions.map((option) {
                return ListTile(
                  title: Text(
                    option,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: _sortBy == option
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: _sortBy == option
                      ? Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 16),
                        )
                      : null,
                  onTap: () {
                    setState(() {
                      _sortBy = option;
                    });
                    _fetchProducts(); // Refetch products based on sort option
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}

// Carousel widget for promotions
class PromotionCarousel extends StatefulWidget {
  final List<String> imagePaths;
  final Duration interval;
  final Duration animationDuration;

  const PromotionCarousel({
    Key? key,
    required this.imagePaths,
    required this.interval,
    required this.animationDuration,
  }) : super(key: key);

  @override
  _PromotionCarouselState createState() => _PromotionCarouselState();
}

class _PromotionCarouselState extends State<PromotionCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(widget.interval, (timer) {
      if (_currentPage < widget.imagePaths.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
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
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemBuilder: (context, index) {
            return Image.asset(
              widget.imagePaths[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.green[100],
                child: Icon(Icons.image, color: Colors.green, size: 50),
              ),
            );
          },
        ),
        // Page indicator dots
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.imagePaths.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 16 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _currentPage == index
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                  boxShadow: _currentPage == index
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
