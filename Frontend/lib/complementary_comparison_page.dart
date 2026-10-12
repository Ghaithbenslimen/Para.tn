import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/complementary_service.dart';
import '../models/product_model.dart';
import 'product_detailed_page.dart';

class ComplementaryComparisonPage extends StatefulWidget {
  final String productId;
  final String productName;
  final String category;
  final List<String> skinTypes;
  final String interfaceAsiss;

  const ComplementaryComparisonPage({
    Key? key,
    required this.productId,
    required this.productName,
    required this.category,
    required this.skinTypes,
    required this.interfaceAsiss,
  }) : super(key: key);

  @override
  _ComplementaryComparisonPageState createState() =>
      _ComplementaryComparisonPageState();
}

class _ComplementaryComparisonPageState
    extends State<ComplementaryComparisonPage> {
  final ComplementaryService _complementaryService = ComplementaryService();
  final Color primaryColor = const Color(0xFF2E7D32);

  List<Map<String, dynamic>> _complementaryProducts = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _sortBy = 'Price: Low to High';

  final List<String> _sortOptions = [
    'Price: Low to High',
    'Price: High to Low',
    'Name: A to Z',
    'Available Stores'
  ];

  @override
  void initState() {
    super.initState();
    _loadComplementaryProducts();
  }

  Future<void> _loadComplementaryProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final products = await _complementaryService
          .getComplementaryProducts(widget.productId);
      setState(() {
        _complementaryProducts = products;
        _applySorting();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applySorting() {
    switch (_sortBy) {
      case 'Price: Low to High':
        _complementaryProducts
            .sort((a, b) => a['lowestPrice'].compareTo(b['lowestPrice']));
        break;
      case 'Price: High to Low':
        _complementaryProducts
            .sort((a, b) => b['lowestPrice'].compareTo(a['lowestPrice']));
        break;
      case 'Name: A to Z':
        _complementaryProducts.sort((a, b) =>
            a['productInfo']['name'].compareTo(b['productInfo']['name']));
        break;
      case 'Available Stores':
        _complementaryProducts.sort(
            (a, b) => b['availableInStores'].compareTo(a['availableInStores']));
        break;
    }
  }

  // Helper method to get the full image URL (same as ProductDetailsPage)
  String _getFullImageUrl(String imagePath) {
    if (imagePath.isEmpty) return '';

    // If it's already a full URL, return it as is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // Otherwise, prepend the base URL
    // Replace backslashes with forward slashes for URL compatibility
    final normalizedPath = imagePath.replaceAll('\\', '/');
    return 'http://10.0.2.2:3000/$normalizedPath';
  }

  // Helper method to build product image widget (similar to ProductDetailsPage)
  Widget _buildProductImage(String imagePath, {double size = 60}) {
    final fullImageUrl = _getFullImageUrl(imagePath);

    if (fullImageUrl.isEmpty) {
      return Container(
        width: size,
        height: size,
        color: Colors.grey[100],
        child: Icon(Icons.image, color: primaryColor, size: size * 0.5),
      );
    }

    return Image.network(
      fullImageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        print('Error loading image: $error');
        return Container(
          width: size,
          height: size,
          color: Colors.grey[100],
          child: Icon(Icons.image, color: primaryColor, size: size * 0.5),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: size,
          height: size,
          color: Colors.grey[50],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: primaryColor,
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
  }

  void _navigateToProductDetails(
      Map<String, dynamic> productData, Map<String, dynamic> parapharmacyData) {
    // Get the full image URL for navigation
    final fullImageUrl = _getFullImageUrl(productData['image'] ?? '');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsPage(
          name: productData['name'],
          brand: productData['category'],
          price: parapharmacyData['originalPrice'].toDouble(),
          discountedPrice: parapharmacyData['hasDiscount']
              ? parapharmacyData['effectivePrice'].toDouble()
              : null,
          rating: parapharmacyData['parapharmacyRating']?.toDouble() ?? 4.0,
          reviewCount: 128,
          imageUrl: fullImageUrl, // Use the full URL
          description: productData['description'] ?? '',
          howToUse: '',
          parapharmacyPrices: [
            {
              'name': parapharmacyData['parapharmacyName'],
              'price': parapharmacyData['effectivePrice'],
              'rating': parapharmacyData['parapharmacyRating'] ?? 0.0,
            }
          ],
          productId: parapharmacyData['productId'],
          quantity: parapharmacyData['quantity'] ?? 0,
          // Add these if you have them available
          skinTypes: productData['skinTypes'] != null
              ? List<String>.from(productData['skinTypes'])
              : [],
          interfaceAsiss: productData['intelfaceassis'] ?? 'none',
          category: productData['category'],
        ),
      ),
    );
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Complementary Products',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              'Similar to ${widget.productName}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadComplementaryProducts,
          ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'Finding complementary products...',
                    style: TextStyle(color: Colors.grey[700]),
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
                      const Text(
                        'Something went wrong',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
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
                        onPressed: _loadComplementaryProducts,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Filter and Info Section
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
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
                                '${_complementaryProducts.length} Products Found',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _showSortOptions(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: primaryColor.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.sort,
                                          color: primaryColor, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        _sortBy,
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Products Table
                    Expanded(
                      child: _complementaryProducts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off,
                                      size: 80, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No complementary products found',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try browsing other categories',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _complementaryProducts.length,
                              itemBuilder: (context, index) {
                                final product = _complementaryProducts[index];
                                return _buildProductComparisonCard(product);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildProductComparisonCard(Map<String, dynamic> product) {
    final productInfo = product['productInfo'];
    final parapharmacies =
        List<Map<String, dynamic>>.from(product['parapharmacies']);
    final lowestPrice = product['lowestPrice'];
    final availableStores = product['availableInStores'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Product Image - FIXED: Now uses the helper method
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildProductImage(
                    productInfo['image'] ?? '',
                    size: 60,
                  ),
                ),
                const SizedBox(width: 12),
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productInfo['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        productInfo['category'],
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'From ${lowestPrice.toStringAsFixed(2)} DT',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: availableStores > 0
                                  ? Colors.green[100]
                                  : Colors.red[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$availableStores stores',
                              style: TextStyle(
                                color: availableStores > 0
                                    ? Colors.green[700]
                                    : Colors.red[700],
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
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

          // Parapharmacies List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: parapharmacies.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey[200],
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              final parapharmacy = parapharmacies[index];
              final isLowestPrice =
                  parapharmacy['effectivePrice'] == lowestPrice;
              final isInStock = parapharmacy['inStock'];

              return InkWell(
                onTap: () =>
                    _navigateToProductDetails(productInfo, parapharmacy),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color:
                        isLowestPrice ? primaryColor.withOpacity(0.05) : null,
                  ),
                  child: Row(
                    children: [
                      // Parapharmacy Info
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.store,
                                    color: primaryColor, size: 16),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    parapharmacy['parapharmacyName'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (parapharmacy['parapharmacyRating'] != null)
                              Row(
                                children: [
                                  Icon(Icons.star,
                                      color: Colors.amber, size: 12),
                                  const SizedBox(width: 2),
                                  Text(
                                    parapharmacy['parapharmacyRating']
                                        .toStringAsFixed(1),
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

                      // Price Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (parapharmacy['hasDiscount']) ...[
                              Text(
                                '${parapharmacy['originalPrice'].toStringAsFixed(2)} DT',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              Text(
                                '${parapharmacy['effectivePrice'].toStringAsFixed(2)} DT',
                                style: TextStyle(
                                  color: isLowestPrice
                                      ? primaryColor
                                      : Colors.black87,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ] else
                              Text(
                                '${parapharmacy['effectivePrice'].toStringAsFixed(2)} DT',
                                style: TextStyle(
                                  color: isLowestPrice
                                      ? primaryColor
                                      : Colors.black87,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (isLowestPrice)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Best Price',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Stock Status
                      Container(
                        width: 60,
                        alignment: Alignment.centerRight,
                        child: Column(
                          children: [
                            Icon(
                              isInStock ? Icons.check_circle : Icons.cancel,
                              color: isInStock ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            Text(
                              isInStock ? 'In Stock' : 'Out',
                              style: TextStyle(
                                color: isInStock ? Colors.green : Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Arrow
                      Icon(Icons.arrow_forward_ios,
                          color: Colors.grey[400], size: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                      fontSize: 18,
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
              ..._sortOptions.map((option) {
                return ListTile(
                  title: Text(option),
                  trailing: _sortBy == option
                      ? Icon(Icons.check, color: primaryColor)
                      : null,
                  onTap: () {
                    setState(() {
                      _sortBy = option;
                      _applySorting();
                    });
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
