import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/command_service.dart';
import '../models/order.dart';
import 'parapharmacy_page.dart';

class OrderConfirmationPage extends StatefulWidget {
  final String orderId;

  const OrderConfirmationPage({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  _OrderConfirmationPageState createState() => _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends State<OrderConfirmationPage> {
  final CommandService _commandService = CommandService();
  bool _isLoading = true;
  Map<dynamic, dynamic>? _mainOrderDetails;
  List<dynamic> _relatedOrders = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      print("Loading order details for ID: ${widget.orderId}");
      final orderData = await _commandService.getOrderDetails(widget.orderId);
      print("Order data received: $orderData");

      setState(() {
        // Handle different response structures
        if (orderData.containsKey('command')) {
          _mainOrderDetails = orderData['command'];
          _relatedOrders = orderData['relatedCommands'] ?? [];
        } else if (orderData.containsKey('success') &&
            orderData['success'] == true) {
          _mainOrderDetails = orderData;
          _relatedOrders = [];
        } else {
          _mainOrderDetails = orderData;
          _relatedOrders = [];
        }
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading order details: $e");
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Safely get a value from a nested map, handling any map type
  dynamic _safeGet(dynamic map, String key, [dynamic defaultValue]) {
    if (map == null) return defaultValue;
    if (map is Map) {
      return map.containsKey(key) ? map[key] : defaultValue;
    }
    return defaultValue;
  }

  // Convert any numeric value to double
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  // Calculate total amount across all orders
  double get _totalAmount {
    double total = _toDouble(_safeGet(_mainOrderDetails, 'totalAmount', 0.0));

    for (var order in _relatedOrders) {
      total += _toDouble(_safeGet(order, 'totalAmount', 0.0));
    }
    return total;
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
          'Order Confirmation',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: primaryGreen),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Error loading order details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(_errorMessage),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ParapharmacyPage(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text('Return to Home'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Success icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: primaryGreen,
                          size: 64,
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Order Placed Successfully!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your order has been confirmed',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 32),

                      // Order details
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
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
                                  'Order ID',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '#${widget.orderId.substring(0, min(widget.orderId.length, 8))}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Date',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  _safeGet(_mainOrderDetails, 'createdAt') !=
                                          null
                                      ? DateTime.parse(_safeGet(
                                              _mainOrderDetails, 'createdAt'))
                                          .toString()
                                          .substring(0, 16)
                                      : 'N/A',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Status',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _safeGet(_mainOrderDetails, 'status',
                                            'PENDING')
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: primaryGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Amount',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '${_totalAmount.toStringAsFixed(2)}\DT',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Show orders from different parapharmacies
                      if (_mainOrderDetails != null) ...[
                        SizedBox(height: 24),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _relatedOrders.isNotEmpty
                                    ? 'Your order was split across multiple parapharmacies'
                                    : 'Order Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 16),

                              // Main order parapharmacy
                              _buildParapharmacyCard(_mainOrderDetails!),

                              // Related orders from other parapharmacies
                              ..._relatedOrders.map(
                                  (order) => _buildParapharmacyCard(order)),
                            ],
                          ),
                        ),
                      ],

                      SizedBox(height: 32),

                      // Continue shopping button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ParapharmacyPage(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Continue Shopping',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildParapharmacyCard(Map<dynamic, dynamic> order) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_safeGet(_safeGet(order, 'parapharmacy'), 'image') != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _safeGet(_safeGet(order, 'parapharmacy'), 'image'),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 40,
                        height: 40,
                        color: Colors.grey[200],
                        child: Icon(Icons.store, color: Colors.grey[400]),
                      );
                    },
                  ),
                )
              else
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.store, color: Colors.grey[400]),
                ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _safeGet(_safeGet(order, 'parapharmacy'), 'name',
                          'Parapharmacy'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(_safeGet(order, 'products', []) as List).length} items · ${_toDouble(_safeGet(order, 'totalAmount', 0.0)).toStringAsFixed(2)}\DT',
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
          SizedBox(height: 12),
          // List of products in this order
          ...(_safeGet(order, 'products', []) as List).map(
            (product) {
              final quantity = _safeGet(product, 'quantity', 0);
              final price = _toDouble(_safeGet(product, 'price', 0.0));
              final total = price * quantity;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$quantity x ${_safeGet(product, 'name', 'Unknown Product')}',
                        style: TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${total.toStringAsFixed(2)}\DT',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
          ).toList(),
        ],
      ),
    );
  }
}

// Helper function to get the minimum of two integers
int min(int a, int b) {
  return a < b ? a : b;
}
