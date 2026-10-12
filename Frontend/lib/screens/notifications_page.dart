import 'package:flutter/material.dart';
import 'package:project/services/notification_service.dart';
import 'package:project/services/auth_service.dart';
import 'package:project/services/product_service.dart'; // Using existing service
import 'package:project/models/product_model.dart'; // Using existing model
import 'package:project/utils/snackbar_utils.dart'; // Import the snackbar utility
import 'package:intl/intl.dart';
import 'dart:convert'; // For handling image paths

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  final ProductService _productService =
      ProductService(); // Using existing service

  late TabController _tabController;
  List<AppNotification> _notifications = [];
  List<Product> _products = []; // To store fetched products
  bool _isLoading = true;
  bool _isLoadingProducts = false; // For product loading state
  String _errorMessage = '';

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedType = 'general';
  String? _selectedProductId;
  String _selectedProductName = '';
  String _selectedProductImage = '';
  bool _isCreatingNotification = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final notifications = await _notificationService.getAdminNotifications();

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load notifications: $e';
      });
    }
  }

  // Add method to load products using your existing service
  Future<void> _loadProducts() async {
    if (_products.isNotEmpty) return; // Don't reload if already loaded

    try {
      setState(() {
        _isLoadingProducts = true;
      });

      final token = await _authService.getToken();
      if (token != null) {
        final products = await _productService.getProducts(token);

        setState(() {
          _products = products;
          _isLoadingProducts = false;
        });
      } else {
        setState(() {
          _isLoadingProducts = false;
          // Use enhanced error snackbar
          SnackbarUtils.showErrorSnackbar(
              context, 'Authentication token not available');
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
        // Use enhanced error snackbar
        SnackbarUtils.showErrorSnackbar(
            context, 'Failed to load products: ${e.toString()}');
      });
    }
  }

  // Validate form fields and show appropriate error messages
  bool _validateForm() {
    // Check if the form is valid according to the validators
    if (!_formKey.currentState!.validate()) {
      // Show error snackbar for invalid form
      SnackbarUtils.showErrorSnackbar(
          context, 'Please fix the errors in the form');
      return false;
    }

    // Additional validation for title
    if (_titleController.text.trim().isEmpty) {
      SnackbarUtils.showErrorSnackbar(
          context, 'Notification title cannot be empty');
      return false;
    }

    // Additional validation for message
    if (_messageController.text.trim().isEmpty) {
      SnackbarUtils.showErrorSnackbar(
          context, 'Notification message cannot be empty');
      return false;
    }

    // Additional validation for promotion type
    if (_selectedType == 'promotion' &&
        (_selectedProductId == null || _selectedProductId!.isEmpty)) {
      SnackbarUtils.showErrorSnackbar(
          context, 'Please select a product for the promotion notification');
      return false;
    }

    return true;
  }

  Future<void> _createNotification() async {
    // First validate the form
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isCreatingNotification = true;
    });

    try {
      final success = await _notificationService.createNotification(
        title: _titleController.text,
        message: _messageController.text,
        type: _selectedType,
        productId: _selectedProductId,
        productName: _selectedProductName,
        productImage: _selectedProductImage,
      );

      if (success) {
        // Use enhanced success snackbar
        SnackbarUtils.showSuccessSnackbar(
            context, 'Notification created successfully');

        // Clear form
        _titleController.clear();
        _messageController.clear();
        _selectedType = 'general';
        _selectedProductId = null;
        _selectedProductName = '';
        _selectedProductImage = '';

        // Reload notifications
        await _loadNotifications();

        // Switch to history tab
        _tabController.animateTo(1);
      } else {
        // Use enhanced error snackbar
        SnackbarUtils.showErrorSnackbar(
            context, 'Failed to create notification');
      }
    } catch (e) {
      // Use enhanced error snackbar
      SnackbarUtils.showErrorSnackbar(context, 'Error: ${e.toString()}');
    } finally {
      setState(() {
        _isCreatingNotification = false;
      });
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      final success = await _notificationService.deleteNotification(id);

      if (success) {
        // Use enhanced success snackbar
        SnackbarUtils.showSuccessSnackbar(
            context, 'Notification deleted successfully');

        // Reload notifications
        await _loadNotifications();
      } else {
        // Use enhanced error snackbar
        SnackbarUtils.showErrorSnackbar(
            context, 'Failed to delete notification');
      }
    } catch (e) {
      // Use enhanced error snackbar
      SnackbarUtils.showErrorSnackbar(context, 'Error: ${e.toString()}');
    }
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notification Type',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildTypeChip('general', 'General', Icons.notifications),
            _buildTypeChip('promotion', 'Promotion', Icons.local_offer),
            _buildTypeChip('update', 'Update', Icons.update),
            _buildTypeChip('reminder', 'Reminder', Icons.alarm),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeChip(String value, String label, IconData icon) {
    final isSelected = _selectedType == value;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
        ],
      ),
      selected: isSelected,
      selectedColor: Colors.green,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedType = value;

            // If switching to promotion type, load products
            if (value == 'promotion') {
              _loadProducts();
            }
          });
        }
      },
    );
  }

  Widget _buildCreateForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create New Notification',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
          SizedBox(height: 24),

          // Title field
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Notification Title',
              hintText: 'Enter a clear, concise title',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a title';
              }
              if (value.length > 100) {
                return 'Title must be less than 100 characters';
              }
              return null;
            },
            onChanged: (value) {
              // Clear any error when user starts typing
              if (_formKey.currentState != null) {
                _formKey.currentState!.validate();
              }
            },
          ),
          SizedBox(height: 16),

          // Message field
          TextFormField(
            controller: _messageController,
            decoration: InputDecoration(
              labelText: 'Notification Message',
              hintText: 'Enter the notification message',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.message),
              alignLabelWithHint: true,
            ),
            maxLines: 5,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a message';
              }
              return null;
            },
            onChanged: (value) {
              // Clear any error when user starts typing
              if (_formKey.currentState != null) {
                _formKey.currentState!.validate();
              }
            },
          ),
          SizedBox(height: 16),

          // Type selector
          _buildTypeSelector(),
          SizedBox(height: 16),

          // Product selector (for promotions)
          if (_selectedType == 'promotion')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Product',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: Icon(Icons.shopping_bag),
                  label: Text(_selectedProductName.isEmpty
                      ? 'Select a Product'
                      : 'Product: $_selectedProductName'),
                  onPressed: () {
                    // Show product selection dialog
                    _showProductSelectionDialog();
                  },
                ),
                if (_selectedProductName.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Product selection is required for promotion notifications',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (_selectedProductName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Chip(
                      label: Text(_selectedProductName),
                      onDeleted: () {
                        setState(() {
                          _selectedProductId = null;
                          _selectedProductName = '';
                          _selectedProductImage = '';
                        });
                      },
                      backgroundColor: Colors.green[100],
                    ),
                  ),
              ],
            ),

          SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: Icon(Icons.send),
              label: Text(
                  _isCreatingNotification ? 'Sending...' : 'Send Notification'),
              onPressed: _isCreatingNotification ? null : _createNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProductSelectionDialog() {
    // Show real products from API
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select a Product'),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: _isLoadingProducts
              ? Center(child: CircularProgressIndicator())
              : _products.isEmpty
                  ? Center(child: Text('No products available'))
                  : ListView.builder(
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        return _buildProductItem(product);
                      },
                    ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    // Format the image path correctly
    String imageUrl = '';
    if (product.imagePath.isNotEmpty) {
      if (product.imagePath.startsWith('http')) {
        imageUrl = product.imagePath;
      } else {
        // Handle server-relative paths
        final normalizedPath = product.imagePath.replaceAll('\\', '/');
        imageUrl = 'http://10.0.2.2:3000/$normalizedPath';
      }
    }

    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[200],
        ),
        child: imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.shopping_bag, color: Colors.grey);
                  },
                ),
              )
            : Icon(Icons.shopping_bag, color: Colors.grey),
      ),
      title: Text(product.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${product.price.toStringAsFixed(2)} TND',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.green[700])),
          Text(product.category,
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
      isThreeLine: true,
      onTap: () {
        setState(() {
          _selectedProductId = product.id;
          _selectedProductName = product.name;
          _selectedProductImage = imageUrl;
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildNotificationsList() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(_errorMessage),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNotifications,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Create your first notification using the form',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getNotificationColor(notification.type),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: Colors.white,
              ),
            ),
            title: Text(notification.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.message,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      DateFormat('MMM d, yyyy • h:mm a')
                          .format(notification.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (notification.type == 'promotion' &&
                        notification.productName.isNotEmpty)
                      Expanded(
                        child: Text(
                          ' • Product: ${notification.productName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red[300]),
              onPressed: () => _showDeleteConfirmation(notification.id),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Notification'),
        content: Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteNotification(id);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'promotion':
        return Colors.orange;
      case 'update':
        return Colors.blue;
      case 'reminder':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'promotion':
        return Icons.local_offer;
      case 'update':
        return Icons.update;
      case 'reminder':
        return Icons.alarm;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Text(
                  'Notifications Management',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Tab bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.green,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: Colors.green,
                tabs: [
                  Tab(
                    icon: Icon(Icons.add_alert),
                    text: 'Create',
                  ),
                  Tab(
                    icon: Icon(Icons.history),
                    text: 'History',
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Create tab
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildCreateForm(),
                    ),
                  ),

                  // History tab
                  RefreshIndicator(
                    onRefresh: _loadNotifications,
                    child: _buildNotificationsList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
