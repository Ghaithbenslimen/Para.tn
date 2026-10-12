import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/track_order_service.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  const OrderDetailsPage({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final TrackOrderService _trackOrderService = TrackOrderService();
  bool _isLoading = true;
  Map<String, dynamic>? _orderDetails;
  String _errorMessage = '';
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final orderDetails =
          await _trackOrderService.getOrderDetails(widget.orderId);
      setState(() {
        _orderDetails = orderDetails;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelOrder() async {
    // Show confirmation dialog
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Order'),
        content: Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldCancel != true) return;

    setState(() {
      _isCancelling = true;
    });

    try {
      final success = await _trackOrderService.cancelOrder(widget.orderId);
      if (success) {
        // Refresh order details
        await _loadOrderDetails();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel order: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCancelling = false;
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
          'Order Details',
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
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: primaryGreen),
            )
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : _buildOrderDetailsView(),
      bottomNavigationBar: _buildBottomBar(),
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
            'Failed to load order details',
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
            onPressed: _loadOrderDetails,
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

  Widget _buildOrderDetailsView() {
    if (_orderDetails == null) {
      return Center(child: Text('No order details available'));
    }

    final order = _orderDetails!;
    final orderStatus = order['status'];
    final orderDate = TrackOrderService.formatDate(order['createdAt']);
    final products = List<Map<String, dynamic>>.from(order['products']);
    final shippingAddress = order['shippingAddress'] ?? {};
    final paymentMethod = order['paymentMethod'] ?? 'cash_on_delivery';
    final totalAmount = order['totalAmount']?.toStringAsFixed(2) ?? '0.00';

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // Order status card
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${widget.orderId.substring(0, 8)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
                          color: TrackOrderService.getStatusColor(orderStatus),
                        ),
                        SizedBox(width: 4),
                        Text(
                          orderStatus.toUpperCase(),
                          style: TextStyle(
                            color:
                                TrackOrderService.getStatusColor(orderStatus),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Placed on: $orderDate',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 20),

        // Order items
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
              Text(
                'Order Items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              SizedBox(height: 16),
              ...products.map((product) {
                final productData = product['product'] ?? {};
                final productName = productData['name'] ?? 'Unknown Product';
                final productImage = productData['image'];
                final productPrice =
                    product['price']?.toStringAsFixed(2) ?? '0.00';
                final productQuantity = product['quantity'] ?? 1;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      // Product image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildProductImage(productImage),
                      ),
                      SizedBox(width: 12),

                      // Product details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productName,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              '$productQuantity x $productPrice\DT',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Item total
                      Text(
                        '${(productQuantity * double.parse(productPrice)).toStringAsFixed(2)}\DT',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              Divider(),
              SizedBox(height: 8),

              // Order total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$totalAmount\DT',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 20),

        // Shipping information
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
              Text(
                'Shipping Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              SizedBox(height: 16),
              _buildInfoRow(
                Icons.location_on_outlined,
                'Address',
                shippingAddress['address'] ?? 'N/A',
              ),
              SizedBox(height: 12),
              _buildInfoRow(
                Icons.location_city,
                'City',
                shippingAddress['city'] ?? 'N/A',
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      Icons.markunread_mailbox,
                      'Postal Code',
                      shippingAddress['postalCode'] ?? 'N/A',
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoRow(
                      Icons.public,
                      'Country',
                      shippingAddress['country'] ?? 'N/A',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 20),

        // Payment information
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
              Text(
                'Payment Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              SizedBox(height: 16),
              _buildInfoRow(
                paymentMethod == 'cash_on_delivery'
                    ? Icons.money
                    : Icons.credit_card,
                'Payment Method',
                paymentMethod == 'cash_on_delivery'
                    ? 'Cash on Delivery'
                    : 'Credit Card',
              ),
              SizedBox(height: 12),
              _buildInfoRow(
                Icons.payment,
                'Payment Status',
                order['isPaid'] == true ? 'Paid' : 'Not Paid',
                valueColor:
                    order['isPaid'] == true ? Colors.green : Colors.orange,
              ),
              if (order['paidAt'] != null) ...[
                SizedBox(height: 12),
                _buildInfoRow(
                  Icons.calendar_today,
                  'Paid On',
                  TrackOrderService.formatDate(order['paidAt']),
                ),
              ],
            ],
          ),
        ),

        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Color(0xFF2E7D32),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductImage(String? imageUrl) {
    if (imageUrl == null) {
      return Container(
        width: 60,
        height: 60,
        color: Colors.grey[200],
        child: Icon(Icons.image, color: Colors.grey[400], size: 24),
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
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 60,
          height: 60,
          color: Colors.grey[200],
          child: Icon(Icons.image, color: Colors.grey[400], size: 24),
        );
      },
    );
  }

  Widget? _buildBottomBar() {
    if (_orderDetails == null) return null;

    final orderStatus = _orderDetails!['status'];

    // Only show cancel button for pending or processing orders
    if (!['pending', 'processing'].contains(orderStatus)) {
      return null;
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isCancelling ? null : _cancelOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: _isCancelling
              ? CircularProgressIndicator(color: Colors.white)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cancel, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Cancel Order',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
