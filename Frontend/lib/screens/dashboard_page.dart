import 'dart:io';
import 'package:flutter/material.dart';
import 'package:project/screens/edit_product_page.dart';
import '../services/product_service.dart';
import '../services/dashboard_service.dart';
import '../models/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  DashboardPage({Key? key}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ProductService _productService = ProductService();
  final DashboardService _dashboardService = DashboardService();
  List<Product> _products = [];
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  String? _token;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');

      if (_token == null) {
        // Handle missing token
        setState(() {
          _isLoading = false;
          _error = 'Authentication token not found. Please log in again.';
        });
        return;
      }

      // Load products and statistics in parallel
      final productsAndStatsFuture = Future.wait([
        _productService.getProducts(_token!),
        _dashboardService.getDashboardStatistics(),
      ]);

      final results = await productsAndStatsFuture;

      setState(() {
        _products = results[0] as List<Product>;
        _statistics = results[1] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
        _error = 'Failed to load data: $e';
      });
    }
  }

  // Helper method to build product images that handles network vs local images
  Widget _buildProductImage(String imagePath, double width, double height) {
    if (imagePath.isEmpty) {
      // Handle empty image path
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: Icon(Icons.image, color: Colors.grey),
      );
    } else if (imagePath.startsWith('http')) {
      // Handle network images that are already full URLs
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: Icon(Icons.image, color: Colors.grey),
          );
        },
      );
    } else if (imagePath.startsWith('/')) {
      // Handle absolute file paths
      try {
        return Image.file(
          File(imagePath),
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: Icon(Icons.image, color: Colors.grey),
            );
          },
        );
      } catch (e) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: Icon(Icons.image, color: Colors.grey),
        );
      }
    } else if (imagePath.startsWith('uploads') || imagePath.contains('\\')) {
      // Handle server-relative paths like "uploads\\products\\filename.jpg"
      // Convert backslashes to forward slashes for URLs
      final normalizedPath = imagePath.replaceAll('\\', '/');
      final fullImageUrl = '${_productService.baseUrl}/$normalizedPath';

      return Image.network(
        fullImageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: Icon(Icons.image, color: Colors.grey),
          );
        },
      );
    } else {
      // Handle asset images or other relative paths
      try {
        return Image.asset(
          imagePath,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: Icon(Icons.image, color: Colors.grey),
            );
          },
        );
      } catch (e) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: Icon(Icons.image, color: Colors.grey),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get monthly sales from statistics
    final monthlySales = _dashboardService.getMonthlySales(_statistics);

    // Get total revenue, customers, and orders from statistics
    final totalRevenue = _statistics?['overview']?['totalRevenue'] ?? 0;
    final totalCustomers = _statistics?['overview']?['totalCustomers'] ?? 0;
    final totalOrders = _statistics?['overview']?['totalOrders'] ?? 0;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Welcome back, ${_statistics?['parapharmacy']?['name'] ?? 'Admin'}!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            // Stats cards
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard(
                  'Total Products',
                  '${_products.length}',
                  Icons.inventory_2,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Total Sales',
                  '${totalRevenue.toStringAsFixed(2)} DT',
                  Icons.attach_money,
                  Colors.green,
                ),
                _buildStatCard(
                  'Customers',
                  '$totalCustomers',
                  Icons.people,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Low Stock',
                  '${_products.where((p) => p.quantity < 30).length}',
                  Icons.warning,
                  Colors.red,
                ),
              ],
            ),
            SizedBox(height: 24),
            // Sales chart (improved to fix overflow)
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
                    'Monthly Sales',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Wrap the chart in a Container with fixed height to prevent overflow
                  Container(
                    height: 200,
                    child: monthlySales.isEmpty
                        ? Center(
                            child: Text(
                              'No sales data available',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              // Calculate the width available for each bar
                              final double availableWidth =
                                  constraints.maxWidth;
                              final double barWidth =
                                  (availableWidth / monthlySales.length) - 8;

                              // Find the maximum sales value to normalize heights
                              final double maxSales = monthlySales
                                  .map((item) =>
                                      double.parse(item['sales'].toString()))
                                  .reduce((a, b) => a > b ? a : b);

                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: monthlySales.map((data) {
                                  // Safely convert sales to double
                                  final double salesValue =
                                      double.parse(data['sales'].toString());

                                  // Calculate normalized height (max height is 150 to leave room for labels)
                                  final double barHeight = maxSales > 0
                                      ? (salesValue / maxSales) * 150
                                      : 0;

                                  return Container(
                                    width: barWidth,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          height: barHeight,
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(4),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          data['month'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${salesValue.toStringAsFixed(0)} DT',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[600],
                                          ),
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            // Recent products
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
                        'Recent Products',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        icon: Icon(Icons.add, color: Colors.green),
                        label: Text('Add Product',
                            style: TextStyle(color: Colors.green)),
                        onPressed: () {
                          Navigator.of(context).pushNamed('/add-product');
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _products.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Icon(Icons.inventory_2_outlined,
                                    size: 48, color: Colors.grey[400]),
                                SizedBox(height: 16),
                                Text(
                                  'No products found. Add some products to get started!',
                                  style: TextStyle(color: Colors.grey[600]),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: [
                              DataColumn(label: Text('Image')),
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Category')),
                              DataColumn(label: Text('Interface Asiss')),
                              DataColumn(label: Text('Price')),
                              DataColumn(label: Text('Quantity')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: _products.map((product) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: _buildProductImage(
                                          product.imagePath, 50, 50),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      width: 200,
                                      child: Text(
                                        product.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(product.category)),
                                  DataCell(Text(product.interfaceAsiss)),
                                  DataCell(Text(
                                      '${product.price.toStringAsFixed(2)} DT')),
                                  DataCell(
                                    Row(
                                      children: [
                                        Text('${product.quantity}'),
                                        SizedBox(width: 8),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: product.quantity < 30
                                                ? Colors.red[100]
                                                : Colors.green[100],
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            product.quantity < 30
                                                ? 'Low'
                                                : 'In Stock',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: product.quantity < 30
                                                  ? Colors.red[800]
                                                  : Colors.green[800],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit,
                                              color: Colors.blue, size: 20),
                                          constraints: BoxConstraints(),
                                          padding: EdgeInsets.all(4),
                                          onPressed: () {
                                            // Navigate to edit product page with the product data
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    EditProductPage(
                                                        product: product),
                                              ),
                                            ).then((_) {
                                              // Refresh the products list when returning from edit page
                                              _loadData();
                                            });
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete,
                                              color: Colors.red, size: 20),
                                          constraints: BoxConstraints(),
                                          padding: EdgeInsets.all(4),
                                          onPressed: () {
                                            // Show delete confirmation
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text('Delete Product'),
                                                content: Text(
                                                    'Are you sure you want to delete ${product.name}?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(),
                                                    child: Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () async {
                                                      try {
                                                        await _productService
                                                            .deleteProduct(
                                                                product.id,
                                                                _token!);
                                                        Navigator.of(context)
                                                            .pop();
                                                        _loadData(); // Refresh the products list
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                                'Product deleted successfully'),
                                                            backgroundColor:
                                                                Colors.green,
                                                          ),
                                                        );
                                                      } catch (e) {
                                                        Navigator.of(context)
                                                            .pop();
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                                'Failed to delete product: $e'),
                                                            backgroundColor:
                                                                Colors.red,
                                                          ),
                                                        );
                                                      }
                                                    },
                                                    child: Text('Delete'),
                                                    style: TextButton.styleFrom(
                                                        foregroundColor:
                                                            Colors.red),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
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
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
