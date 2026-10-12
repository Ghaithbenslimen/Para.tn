import 'package:flutter/material.dart';
import '../services/statistics_service.dart';
import '../services/auth_service.dart';
import 'dart:io';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final StatisticsService _statisticsService = StatisticsService();
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
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

      // Check if user is authenticated
      final isAuthenticated = await _authService.isAuthenticated();
      if (!isAuthenticated) {
        setState(() {
          _error = 'Not authenticated. Please log in.';
          _isLoading = false;
        });
        return;
      }

      // Check if user is a parapharmacy
      final isParapharmacie = await _authService.isParapharmacieUser();
      if (!isParapharmacie) {
        setState(() {
          _error = 'Only parapharmacies can access statistics.';
          _isLoading = false;
        });
        return;
      }

      // Get statistics for the logged-in parapharmacy
      final statistics = await _statisticsService.getMyStatistics();

      setState(() {
        _statistics = statistics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthlySales = _statisticsService.getMonthlySales(_statistics);
    final revenueByCategory =
        _statisticsService.getRevenueByCategory(_statistics);
    final topProducts = _statisticsService.getTopProducts(_statistics);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'View your business performance',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Overview Cards
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard(
                  'Total Revenue',
                  '${_statistics?['overview']['totalRevenue'].toStringAsFixed(2) ?? '0'} DT',
                  Icons.attach_money,
                  Colors.green,
                ),
                _buildStatCard(
                  'Total Orders',
                  '${_statistics?['overview']['totalOrders'] ?? '0'}',
                  Icons.shopping_bag,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Customers',
                  '${_statistics?['overview']['totalCustomers'] ?? '0'}',
                  Icons.people,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Avg. Order Value',
                  '${_statistics?['overview']['averageOrderValue'].toStringAsFixed(2) ?? '0'} DT',
                  Icons.trending_up,
                  Colors.purple,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sales Overview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sales Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
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

            const SizedBox(height: 24),

            // Top Selling Products
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
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
                        'Top Selling Products',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  topProducts.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Icon(Icons.inventory_2_outlined,
                                    size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No products data available',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            ...List.generate(
                              topProducts.length > 3 ? 3 : topProducts.length,
                              (index) {
                                final product = topProducts[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildTopProductItem(
                                    product,
                                    product['quantity'],
                                    index + 1,
                                    index == 0
                                        ? Colors.amber
                                        : index == 1
                                            ? Colors.blueGrey
                                            : Colors.brown,
                                  ),
                                );
                              },
                            ),
                            if (topProducts.length > 3) ...[
                              const SizedBox(height: 20),
                              const Divider(),
                              const SizedBox(height: 12),
                              ...List.generate(
                                topProducts.length > 5
                                    ? 2
                                    : topProducts.length - 3,
                                (index) {
                                  final actualIndex = index + 3;
                                  final product = topProducts[actualIndex];

                                  return Column(
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              '#${actualIndex + 1}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: _buildProductImage(
                                              product['image'] ?? '',
                                              40,
                                              40,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product['name'] ??
                                                      'Unknown Product',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${product['quantity']} sold',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${product['revenue'].toStringAsFixed(2)} DT',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      if (actualIndex < topProducts.length - 1)
                                        const Divider(height: 24),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Revenue by Category
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue by Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  revenueByCategory.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Icon(Icons.pie_chart_outline,
                                    size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No category data available',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: revenueByCategory.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = revenueByCategory[index];
                            final category = item['category'];
                            final revenue =
                                double.parse(item['revenue'].toString());
                            final percentage =
                                double.parse(item['percentage'].toString());

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        category,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${revenue.toStringAsFixed(2)} DT',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: percentage / 100,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.primaries[
                                        index % Colors.primaries.length],
                                  ),
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: Icon(Icons.image, color: Colors.grey),
          );
        },
      );
    } else if (imagePath.startsWith('uploads') || imagePath.contains('\\')) {
      final normalizedPath = imagePath.replaceAll('\\', '/');
      final fullImageUrl = '${_statisticsService.baseUrl}/$normalizedPath';

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
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: Icon(Icons.image, color: Colors.grey),
      );
    }
  }

  Widget _buildTopProductItem(
      Map<String, dynamic> product, int quantity, int rank, Color rankColor) {
    final revenue = product['revenue'] ?? (product['price'] * quantity);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: _buildProductImage(product['image'] ?? '', 80, 80),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: rankColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Unknown Product',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    product['category'] ?? '',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$quantity sold',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: quantity / 100,
                              backgroundColor: Colors.grey[200],
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(rankColor),
                              minHeight: 5,
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '${revenue.toStringAsFixed(2)} DT',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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
              fontSize: 20, // Reduced font size to prevent overflow
              overflow: TextOverflow.ellipsis,
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
