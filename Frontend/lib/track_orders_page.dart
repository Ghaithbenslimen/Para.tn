import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/track_order_service.dart';
import 'order_details_page.dart';

class TrackOrdersPage extends StatefulWidget {
  const TrackOrdersPage({Key? key}) : super(key: key);

  @override
  _TrackOrdersPageState createState() => _TrackOrdersPageState();
}

class _TrackOrdersPageState extends State<TrackOrdersPage> {
  final TrackOrderService _trackOrderService = TrackOrderService();
  bool _isLoading = true;
  List<dynamic> _orders = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final orders = await _trackOrderService.getOrders();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define our color palette
    const primaryGreen = Color(0xFF2E7D32);
    const backgroundColor = Color(0xFFF5F9F5);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: const Text(
          'My Orders',
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
            child: Icon(Icons.arrow_back, color: primaryGreen, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
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
              child: Icon(Icons.refresh, color: primaryGreen, size: 20),
            ),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: primaryGreen),
            )
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : _orders.isEmpty
                  ? _buildEmptyView()
                  : _buildOrdersList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          SizedBox(height: 16),
          Text(
            'Failed to load orders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadOrders,
            icon: Icon(Icons.refresh),
            label: Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No orders yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your order history will appear here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.shopping_cart_outlined),
            label: Text('Start Shopping'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: Color(0xFF2E7D32),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          final orderId = order['_id'];
          final orderDate = TrackOrderService.formatDate(order['createdAt']);
          final orderStatus = order['status'];
          final orderTotal = order['totalAmount'].toStringAsFixed(2);
          final productCount = order['products'].length;

          // Get the first product image for display
          String? productImage;
          if (order['products'].isNotEmpty &&
              order['products'][0]['product'] != null &&
              order['products'][0]['product']['image'] != null) {
            productImage = order['products'][0]['product']['image'];
          }

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailsPage(orderId: orderId),
                ),
              ).then((_) => _loadOrders()); // Refresh after returning
            },
            child: Container(
              margin: EdgeInsets.only(bottom: 16),
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
                children: [
                  // Order header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #${orderId.substring(0, 8)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              orderDate,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: TrackOrderService.getStatusColor(orderStatus)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                TrackOrderService.getStatusIcon(orderStatus),
                                size: 16,
                                color: TrackOrderService.getStatusColor(
                                    orderStatus),
                              ),
                              SizedBox(width: 4),
                              Text(
                                orderStatus.toUpperCase(),
                                style: TextStyle(
                                  color: TrackOrderService.getStatusColor(
                                      orderStatus),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  Divider(height: 1),

                  // Order preview
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Product image or placeholder
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildProductImage(productImage),
                        ),
                        SizedBox(width: 16),

                        // Order summary
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$productCount ${productCount > 1 ? 'items' : 'item'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Total: $orderTotal\DT',
                                style: TextStyle(
                                  color: Color(0xFF2E7D32),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Arrow icon
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductImage(String? imageUrl) {
    if (imageUrl == null) {
      return Container(
        width: 80,
        height: 80,
        color: Colors.grey[200],
        child: Icon(Icons.image, color: Colors.grey[400], size: 30),
      );
    }

    // Check if it's a network image or local path
    final isNetworkImage =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
    String fullImageUrl = imageUrl;

    // If it's a local path, construct the full URL
    if (!isNetworkImage) {
      // Replace backslashes with forward slashes for URLs
      String formattedPath = imageUrl.replaceAll('\\', '/');
      fullImageUrl = 'http://10.0.2.2:3000/$formattedPath';
    }

    return Image.network(
      fullImageUrl,
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 80,
          height: 80,
          color: Colors.grey[200],
          child: Icon(Icons.image, color: Colors.grey[400], size: 30),
        );
      },
    );
  }
}
