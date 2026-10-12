import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/product_service.dart';
import '../models/product_model.dart';
import 'edit_product_page.dart'; // Import the edit page directly

class InventoryPage extends StatefulWidget {
  const InventoryPage({Key? key}) : super(key: key);

  @override
  _InventoryPageState createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _selectedInterfaceAsiss = 'All';
  String _searchQuery = '';
  String? _token;

  final List<String> _interfaceOptions = [
    'All',
    'none',
    'Acne',
    'Actinic Keratosis',
    'Basal Cell Carcinoma',
    'Eczema',
    'Rosacea'
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');

      if (_token == null) {
        // Handle missing token
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Authentication token not found. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get products from the service
      final products = await _productService.getProducts(_token!);

      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load products: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Product> _filterProducts(List<Product> products) {
    return products.where((product) {
      bool categoryMatch =
          _selectedCategory == 'All' || product.category == _selectedCategory;
      bool interfaceMatch = _selectedInterfaceAsiss == 'All' ||
          product.interfaceAsiss == _selectedInterfaceAsiss;
      bool searchMatch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return categoryMatch && interfaceMatch && searchMatch;
    }).toList();
  }

  Map<String, int> _getInventoryByCategory(List<Product> products) {
    final Map<String, int> inventoryByCategory = {};

    for (var product in products) {
      final category = product.category;
      inventoryByCategory[category] =
          (inventoryByCategory[category] ?? 0) + product.quantity;
    }

    return inventoryByCategory;
  }

  // Helper method to build product images handling server-relative paths
  Widget _buildProductImage(String imagePath, double width, double height) {
    if (imagePath.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: Icon(Icons.image, color: Colors.grey),
      );
    } else if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading network image: $error');
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: Icon(Icons.image, color: Colors.grey),
          );
        },
      );
    } else if (imagePath.startsWith('/')) {
      try {
        return Image.file(
          File(imagePath),
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading file image: $error');
            return Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: Icon(Icons.image, color: Colors.grey),
            );
          },
        );
      } catch (e) {
        print('Error loading file image: $e');
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: Icon(Icons.image, color: Colors.grey),
        );
      }
    } else if (imagePath.startsWith('uploads') || imagePath.contains('\\')) {
      final normalizedPath = imagePath.replaceAll('\\', '/');
      final fullImageUrl = '${_productService.baseUrl}/$normalizedPath';

      return Image.network(
        fullImageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading server image: $error');
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: Icon(Icons.image, color: Colors.grey),
          );
        },
      );
    } else {
      try {
        return Image.asset(
          imagePath,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading asset image: $error');
            return Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: Icon(Icons.image, color: Colors.grey),
            );
          },
        );
      } catch (e) {
        print('Error loading asset image: $e');
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: Icon(Icons.image, color: Colors.grey),
        );
      }
    }
  }

  // Delete product method
  Future<void> _deleteProduct(Product product) async {
    try {
      if (_token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No token found. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final success = await _productService.deleteProduct(product.id, _token!);

      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadProducts(); // Refresh the products list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete product'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show delete confirmation dialog
  void _showDeleteConfirmationDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteProduct(product);
            },
            child: Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  // Navigate to edit product page - fixed to use MaterialPageRoute directly
  void _navigateToEditProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductPage(product: product),
      ),
    ).then((_) => _loadProducts());
  }

  @override
  Widget build(BuildContext context) {
    final inventoryByCategory = _getInventoryByCategory(_products);
    final filteredProducts = _filterProducts(_products);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inventory Management',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Manage your product inventory',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 24),
                    // Inventory by Category Card
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Inventory by Category',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          inventoryByCategory.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      children: [
                                        Icon(Icons.inventory_2_outlined,
                                            size: 48, color: Colors.grey[400]),
                                        SizedBox(height: 16),
                                        Text(
                                          'No inventory data available',
                                          style: TextStyle(
                                              color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: inventoryByCategory.length,
                                  separatorBuilder: (context, index) =>
                                      SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final entry = inventoryByCategory.entries
                                        .elementAt(index);
                                    final category = entry.key;
                                    final count = entry.value;
                                    final total = inventoryByCategory.values
                                        .fold(0, (sum, value) => sum + value);
                                    final percentage =
                                        total > 0 ? count / total * 100 : 0;

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                category,
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w500),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              '$count items',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        LinearProgressIndicator(
                                          value: percentage / 100,
                                          backgroundColor: Colors.grey[200],
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.primaries[index %
                                                Colors.primaries.length],
                                          ),
                                          minHeight: 8,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    // Products List Card
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 4),
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
                                'All Products',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton.icon(
                                icon: Icon(Icons.add, color: Colors.green),
                                label: Text('Add Product',
                                    style: TextStyle(color: Colors.green)),
                                onPressed: () {},
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          // Filters
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  value: _selectedCategory,
                                  decoration: InputDecoration(
                                    labelText: 'Filter by Category',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                  items: [
                                    'All',
                                    ..._products
                                        .map((p) => p.category)
                                        .toSet()
                                        .toList()
                                  ].map((category) {
                                    return DropdownMenuItem<String>(
                                      value: category,
                                      child: Text(
                                        category,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCategory = value!;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  value: _selectedInterfaceAsiss,
                                  decoration: InputDecoration(
                                    labelText: 'Filter by InterfaceAsiss',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                  items: _interfaceOptions.map((option) {
                                    return DropdownMenuItem<String>(
                                      value: option,
                                      child: Text(
                                        option,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedInterfaceAsiss = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          // Search
                          TextField(
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search product by name',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                          SizedBox(height: 16),
                          // Products display
                          filteredProducts.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      children: [
                                        Icon(Icons.inventory_2_outlined,
                                            size: 48, color: Colors.grey[400]),
                                        SizedBox(height: 16),
                                        Text(
                                          'No products found. Try a different filter or add products.',
                                          style: TextStyle(
                                              color: Colors.grey[600]),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : _buildProductsGrid(filteredProducts),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // Fixed product grid with proper sizing to avoid overflow
  Widget _buildProductsGrid(List<Product> products) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.65, // Further reduced to fix 26px overflow
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final isLowStock = product.quantity < 30;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
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
              // Product image with status badge - fixed height
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: Container(
                      width: double.infinity,
                      height: 120, // Fixed height for image
                      child: _buildProductImage(
                          product.imagePath, double.infinity, 120),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLowStock ? Colors.red[100] : Colors.green[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isLowStock ? 'Low Stock' : 'In Stock',
                        style: TextStyle(
                          color:
                              isLowStock ? Colors.red[800] : Colors.green[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Product details - using Expanded with simplified layout
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Use min size
                    children: [
                      // Product name and category - fixed height section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            product.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      // Price and quantity
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${product.price.toStringAsFixed(2)}\DT',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Qty: ${product.quantity}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isLowStock ? Colors.red : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      // Spacer to push buttons to bottom
                      Spacer(),
                      // Action buttons - fixed height
                      Container(
                        height: 28, // Fixed height for buttons
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Edit button - using InkWell instead of IconButton to save space
                            InkWell(
                              onTap: () => _navigateToEditProduct(product),
                              child: Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.edit,
                                    color: Colors.blue, size: 20),
                              ),
                            ),
                            SizedBox(width: 8),
                            // Delete button - using InkWell instead of IconButton to save space
                            InkWell(
                              onTap: () =>
                                  _showDeleteConfirmationDialog(product),
                              child: Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.delete,
                                    color: Colors.red, size: 20),
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
        );
      },
    );
  }
}
