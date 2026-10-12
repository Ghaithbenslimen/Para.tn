import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/admin_order_service.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({Key? key}) : super(key: key);

  @override
  _AdminOrdersPageState createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final AdminOrderService _orderService = AdminOrderService();
  bool _isLoading = true;
  List<dynamic> _orders = [];
  String _errorMessage = '';
  String _selectedFilter = 'all';

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
      final orders = await _orderService.getParapharmacyOrders();
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

  List<dynamic> get _filteredOrders {
    if (_selectedFilter == 'all') {
      return _orders;
    }
    return _orders
        .where((order) =>
            order['status'].toLowerCase() == _selectedFilter.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 16),
              _buildFilterChips(),
              SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: Colors.green))
                    : _errorMessage.isNotEmpty
                        ? _buildErrorView()
                        : _orders.isEmpty
                            ? _buildEmptyView()
                            : _buildOrdersContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Orders Management',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Manage orders for your parapharmacy products',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: _loadOrders,
          icon: Icon(
            Icons.refresh,
            color: Colors.white,
          ),
          label: Text('Refresh'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('all', 'All Orders'),
          SizedBox(width: 8),
          _buildFilterChip('pending', 'Pending'),
          SizedBox(width: 8),
          _buildFilterChip('processing', 'Processing'),
          SizedBox(width: 8),
          _buildFilterChip('shipped', 'Shipped'),
          SizedBox(width: 8),
          _buildFilterChip('delivered', 'Delivered'),
          SizedBox(width: 8),
          _buildFilterChip('cancelled', 'Cancelled'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.green[100],
      checkmarkColor: Colors.green,
      labelStyle: TextStyle(
        color: isSelected ? Colors.green[800] : Colors.grey[800],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? Colors.green : Colors.grey[300]!,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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
            'No orders found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Orders for your products will appear here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersContent() {
    if (_filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list,
              size: 48,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No orders match the selected filter',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Use a responsive approach based on screen width
    final screenWidth = MediaQuery.of(context).size.width;

    // For smaller screens, use a card-based layout
    if (screenWidth < 800) {
      return _buildOrdersCardList();
    }
    // For larger screens, use a table layout
    else {
      return _buildOrdersTable();
    }
  }

  Widget _buildOrdersCardList() {
    return ListView.builder(
      itemCount: _filteredOrders.length,
      itemBuilder: (context, index) {
        final order = _filteredOrders[index];
        final orderId = order['_id'];
        final orderDate = AdminOrderService.formatDate(order['createdAt']);
        final orderStatus = order['status'];
        final productCount = order['products'].length;
        // Use totalAmount instead of parapharmacySubtotal
        final totalAmount = order['totalAmount']?.toStringAsFixed(2) ?? '0.00';
        final customerName = order['user']?['username'] ?? 'Unknown';

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#${orderId.substring(0, 8)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AdminOrderService.getStatusColor(orderStatus)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AdminOrderService.getStatusIcon(orderStatus),
                            size: 14,
                            color:
                                AdminOrderService.getStatusColor(orderStatus),
                          ),
                          SizedBox(width: 4),
                          Text(
                            orderStatus.toUpperCase(),
                            style: TextStyle(
                              color:
                                  AdminOrderService.getStatusColor(orderStatus),
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
                Divider(),
                SizedBox(height: 12),
                _buildInfoRow('Customer', customerName),
                SizedBox(height: 8),
                _buildInfoRow('Date', orderDate),
                SizedBox(height: 8),
                _buildInfoRow('Items', productCount.toString()),
                SizedBox(height: 8),
                _buildInfoRow('Total', '$totalAmount\DT',
                    valueStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                      fontSize: 16,
                    )),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () =>
                          _showUpdateStatusDialog(orderId, orderStatus),
                      icon: Icon(Icons.edit, size: 18),
                      label: Text('Update Status'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: BorderSide(color: Colors.orange),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showOrderDetails(orderId),
                      icon: Icon(
                        Icons.visibility,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text('View Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? valueStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: valueStyle ??
              TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
        ),
      ],
    );
  }

  Widget _buildOrdersTable() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Table header
              Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Order ID',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Customer',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Date',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Items',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Actions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              // Table rows
              Container(
                height: MediaQuery.of(context).size.height -
                    300, // Adjust height as needed
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _filteredOrders.length,
                  separatorBuilder: (context, index) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    final order = _filteredOrders[index];
                    final orderId = order['_id'];
                    final orderDate =
                        AdminOrderService.formatDate(order['createdAt']);
                    final orderStatus = order['status'];
                    final productCount = order['products'].length;
                    // Use totalAmount instead of parapharmacySubtotal
                    final totalAmount =
                        order['totalAmount']?.toStringAsFixed(2) ?? '0.00';
                    final customerName =
                        order['user']?['username'] ?? 'Unknown';

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      child: Row(
                        children: [
                          // Order ID
                          Expanded(
                            flex: 2,
                            child: Text(
                              '#${orderId.substring(0, 8)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Customer
                          Expanded(
                            flex: 2,
                            child: Text(
                              customerName,
                              style: TextStyle(
                                color: Colors.grey[800],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Date
                          Expanded(
                            flex: 2,
                            child: Text(
                              orderDate,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Items
                          Expanded(
                            flex: 1,
                            child: Text(
                              productCount.toString(),
                              style: TextStyle(
                                color: Colors.grey[800],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          // Total
                          Expanded(
                            flex: 2,
                            child: Text(
                              '$totalAmount\DT',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Status
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AdminOrderService.getStatusColor(
                                          orderStatus)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      AdminOrderService.getStatusIcon(
                                          orderStatus),
                                      size: 14,
                                      color: AdminOrderService.getStatusColor(
                                          orderStatus),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      orderStatus.toUpperCase(),
                                      style: TextStyle(
                                        color: AdminOrderService.getStatusColor(
                                            orderStatus),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Actions
                          Expanded(
                            flex: 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.visibility,
                                      color: Colors.blue),
                                  tooltip: 'View Details',
                                  onPressed: () {
                                    _showOrderDetails(orderId);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.orange),
                                  tooltip: 'Update Status',
                                  onPressed: () {
                                    _showUpdateStatusDialog(
                                        orderId, orderStatus);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetails(String orderId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminOrderDetailsPage(orderId: orderId),
      ),
    ).then((_) => _loadOrders()); // Refresh after returning
  }

  void _showUpdateStatusDialog(String orderId, String currentStatus) {
    String selectedStatus = currentStatus;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Update Order Status'),
            content: Container(
              width: double.minPositive,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select the new status for this order:'),
                  SizedBox(height: 16),
                  _buildStatusRadio('pending', 'Pending', selectedStatus,
                      (value) {
                    setState(() => selectedStatus = value!);
                  }),
                  _buildStatusRadio('processing', 'Processing', selectedStatus,
                      (value) {
                    setState(() => selectedStatus = value!);
                  }),
                  _buildStatusRadio('shipped', 'Shipped', selectedStatus,
                      (value) {
                    setState(() => selectedStatus = value!);
                  }),
                  _buildStatusRadio('delivered', 'Delivered', selectedStatus,
                      (value) {
                    setState(() => selectedStatus = value!);
                  }),
                  _buildStatusRadio('cancelled', 'Cancelled', selectedStatus,
                      (value) {
                    setState(() => selectedStatus = value!);
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white, // only Update text is white
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await _updateOrderStatus(orderId, selectedStatus);
                },
                child: Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusRadio(String value, String label, String groupValue,
      Function(String?) onChanged) {
    return RadioListTile<String>(
      title: Row(
        children: [
          Icon(
            AdminOrderService.getStatusIcon(value),
            color: AdminOrderService.getStatusColor(value),
            size: 18,
          ),
          SizedBox(width: 8),
          Text(label),
        ],
      ),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: Colors.green,
      dense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 0),
    );
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      final success = await _orderService.updateOrderStatus(orderId, status);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh orders
        await _loadOrders();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update order status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class AdminOrderDetailsPage extends StatefulWidget {
  final String orderId;

  const AdminOrderDetailsPage({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  _AdminOrderDetailsPageState createState() => _AdminOrderDetailsPageState();
}

class _AdminOrderDetailsPageState extends State<AdminOrderDetailsPage> {
  final AdminOrderService _orderService = AdminOrderService();
  bool _isLoading = true;
  Map<String, dynamic>? _orderDetails;
  String _errorMessage = '';
  bool _isUpdatingStatus = false;

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
      final orderDetails = await _orderService.getOrderDetails(widget.orderId);
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

  Future<void> _updateOrderStatus(String status) async {
    // Show confirmation dialog
    final shouldUpdate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Order Status'),
        content: Text('Are you sure you want to change the status to $status?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Update', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (shouldUpdate != true) return;

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      final success =
          await _orderService.updateOrderStatus(widget.orderId, status);
      if (success) {
        // Refresh order details
        await _loadOrderDetails();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update order status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUpdatingStatus = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Text(
          'Order Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadOrderDetails,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: Colors.green),
            )
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : _buildOrderDetailsView(),
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
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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
    final orderDate = AdminOrderService.formatDate(order['createdAt']);
    final products = List<Map<String, dynamic>>.from(order['products']);
    final shippingAddress = order['shippingAddress'] ?? {};
    final paymentMethod = order['paymentMethod'] ?? 'cash_on_delivery';
    // Use totalAmount instead of parapharmacySubtotal
    final totalAmount = order['totalAmount']?.toStringAsFixed(2) ?? '0.00';
    final customerInfo = order['user'] ?? {};

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order status card with actions
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${widget.orderId.substring(0, 8)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Placed on: $orderDate',
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
                          color: AdminOrderService.getStatusColor(orderStatus)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              AdminOrderService.getStatusIcon(orderStatus),
                              size: 16,
                              color:
                                  AdminOrderService.getStatusColor(orderStatus),
                            ),
                            SizedBox(width: 4),
                            Text(
                              orderStatus.toUpperCase(),
                              style: TextStyle(
                                color: AdminOrderService.getStatusColor(
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
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 16),
                  Text(
                    'Update Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 12),
                  _isUpdatingStatus
                      ? Center(
                          child: CircularProgressIndicator(color: Colors.green))
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildStatusButton(
                                  'pending', 'Pending', orderStatus),
                              SizedBox(width: 8),
                              _buildStatusButton(
                                  'processing', 'Processing', orderStatus),
                              SizedBox(width: 8),
                              _buildStatusButton(
                                  'shipped', 'Shipped', orderStatus),
                              SizedBox(width: 8),
                              _buildStatusButton(
                                  'delivered', 'Delivered', orderStatus),
                              SizedBox(width: 8),
                              _buildStatusButton(
                                  'cancelled', 'Cancelled', orderStatus),
                            ],
                          ),
                        ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Customer information
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.person_outline,
                    'Name',
                    customerInfo['username'] ?? 'N/A',
                  ),
                  SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.email_outlined,
                    'Email',
                    customerInfo['email'] ?? 'N/A',
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Order items
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: products.length,
                    separatorBuilder: (context, index) => Divider(height: 24),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final productData = product['product'] ?? {};
                      final productName =
                          productData['name'] ?? 'Unknown Product';
                      final productImage = productData['image'];
                      final productPrice =
                          product['price']?.toStringAsFixed(2) ?? '0.00';
                      final productQuantity = product['quantity'] ?? 1;

                      return Row(
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
                      );
                    },
                  ),

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
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Shipping information
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shipping Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
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
          ),

          SizedBox(height: 16),

          // Payment information
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
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
                      AdminOrderService.formatDate(order['paidAt']),
                    ),
                  ],
                ],
              ),
            ),
          ),

          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatusButton(String status, String label, String currentStatus) {
    final isCurrentStatus = status == currentStatus;

    return OutlinedButton.icon(
      onPressed: isCurrentStatus ? null : () => _updateOrderStatus(status),
      icon: Icon(
        AdminOrderService.getStatusIcon(status),
        size: 16,
      ),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: isCurrentStatus
            ? Colors.grey
            : AdminOrderService.getStatusColor(status),
        side: BorderSide(
          color: isCurrentStatus
              ? Colors.grey
              : AdminOrderService.getStatusColor(status),
        ),
        backgroundColor: isCurrentStatus
            ? Colors.grey.withOpacity(0.1)
            : AdminOrderService.getStatusColor(status).withOpacity(0.05),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
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
          color: Colors.green,
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
}
