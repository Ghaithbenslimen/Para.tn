import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/command_service.dart';
import '../services/cart_service.dart';
import '../utils/snackbar_utils.dart'; // Import the snackbar utility
import 'order_confirmation.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({Key? key}) : super(key: key);

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final CommandService _commandService = CommandService();
  final CartService _cartService = CartService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String _errorMessage = '';

  // Form fields
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  String _paymentMethod = 'cash_on_delivery';

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  // Validate all form fields and show appropriate snackbars
  bool _validateForm() {
    // Check if the form is valid according to the validators
    if (!_formKey.currentState!.validate()) {
      // Show error snackbar for invalid form
      SnackbarUtils.showErrorSnackbar(
          context, 'Please fix the errors in the form');
      return false;
    }

    // Additional validation for address
    if (_addressController.text.trim().isEmpty) {
      SnackbarUtils.showErrorSnackbar(context, 'Address cannot be empty');
      return false;
    }

    // Additional validation for city
    if (_cityController.text.trim().isEmpty) {
      SnackbarUtils.showErrorSnackbar(context, 'City cannot be empty');
      return false;
    } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(_cityController.text)) {
      SnackbarUtils.showErrorSnackbar(
          context, 'City should contain only letters');
      return false;
    }

    // Additional validation for postal code
    if (_postalCodeController.text.trim().isEmpty) {
      SnackbarUtils.showErrorSnackbar(context, 'Postal code cannot be empty');
      return false;
    } else if (_postalCodeController.text.length != 4) {
      SnackbarUtils.showErrorSnackbar(
          context, 'Postal code must be exactly 4 digits');
      return false;
    }

    // Additional validation for country
    if (_countryController.text.trim().isEmpty) {
      SnackbarUtils.showErrorSnackbar(context, 'Country cannot be empty');
      return false;
    } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(_countryController.text)) {
      SnackbarUtils.showErrorSnackbar(
          context, 'Country should contain only letters');
      return false;
    }

    return true;
  }

  Future<void> _placeOrder() async {
    // First validate the form with snackbar notifications
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Prepare shipping address
      final shippingAddress = {
        'address': _addressController.text,
        'city': _cityController.text,
        'postalCode': _postalCodeController.text,
        'country': _countryController.text,
      };

      // Create order
      final result = await _commandService.createOrder(
        shippingAddress: shippingAddress,
        paymentMethod: _paymentMethod,
      );

      // Show success snackbar
      SnackbarUtils.showSuccessSnackbar(context, 'Order placed successfully!');

      // Navigate to confirmation page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderConfirmationPage(
            orderId: result['command']['_id'],
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });

      // Show error snackbar
      SnackbarUtils.showErrorSnackbar(
          context, 'Failed to place order: ${e.toString()}');
    } finally {
      setState(() {
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
          'Checkout',
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
      body: StreamBuilder<List<dynamic>>(
        stream: _cartService.cartStream,
        initialData: _cartService.items,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final cartItems = snapshot.data ?? [];

          if (cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text('Return to Cart'),
                  ),
                ],
              ),
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Order summary
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
                        'Order Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      SizedBox(height: 16),
                      ...cartItems
                          .map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        item.imageUrl,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey[200],
                                            child: Icon(Icons.image,
                                                color: Colors.grey[400]),
                                          );
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '${item.quantity} x ${item.effectivePrice.toStringAsFixed(2)}\DT',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${(item.effectivePrice * item.quantity).toStringAsFixed(2)}\DT',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                      Divider(),
                      SizedBox(height: 8),
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
                            '${_cartService.totalPrice.toStringAsFixed(2)}\DT',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Shipping information
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
                        'Shipping Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Address',
                          hintText: 'Enter your street address',
                          prefixIcon: Icon(Icons.location_on_outlined,
                              color: primaryGreen),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: primaryGreen, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your address';
                          }
                          if (value.length < 5) {
                            return 'Address is too short';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                        onChanged: (value) {
                          // Clear any error when user starts typing
                          if (_formKey.currentState != null) {
                            _formKey.currentState!.validate();
                          }
                        },
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          labelText: 'City',
                          hintText: 'Enter your city',
                          prefixIcon:
                              Icon(Icons.location_city, color: primaryGreen),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: primaryGreen, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your city';
                          }
                          if (value.length < 2) {
                            return 'City name is too short';
                          }
                          // Check if city contains only letters and spaces
                          if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                            return 'City should contain only letters';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                        onChanged: (value) {
                          // Clear any error when user starts typing
                          if (_formKey.currentState != null) {
                            _formKey.currentState!.validate();
                          }
                        },
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _postalCodeController,
                              decoration: InputDecoration(
                                labelText: 'Postal Code',
                                hintText: '4 digits',
                                prefixIcon: Icon(Icons.markunread_mailbox,
                                    color: primaryGreen),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: primaryGreen, width: 2),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter postal code';
                                }
                                if (value.length != 4) {
                                  return 'Must be exactly 4 digits';
                                }
                                return null;
                              },
                              textInputAction: TextInputAction.next,
                              onChanged: (value) {
                                // Clear any error when user starts typing
                                if (_formKey.currentState != null) {
                                  _formKey.currentState!.validate();
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _countryController,
                              decoration: InputDecoration(
                                labelText: 'Country',
                                hintText: 'Enter your country',
                                prefixIcon:
                                    Icon(Icons.public, color: primaryGreen),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: primaryGreen, width: 2),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter country';
                                }
                                if (value.length < 3) {
                                  return 'Country name is too short';
                                }
                                // Check if country contains only letters and spaces
                                if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                                  return 'Country should contain only letters';
                                }
                                return null;
                              },
                              textInputAction: TextInputAction.done,
                              onChanged: (value) {
                                // Clear any error when user starts typing
                                if (_formKey.currentState != null) {
                                  _formKey.currentState!.validate();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Payment method
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
                        'Payment Method',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      SizedBox(height: 16),
                      RadioListTile<String>(
                        title: Row(
                          children: [
                            Icon(Icons.money, color: primaryGreen),
                            SizedBox(width: 12),
                            Text('Cash on Delivery'),
                          ],
                        ),
                        value: 'cash_on_delivery',
                        groupValue: _paymentMethod,
                        onChanged: (value) {
                          setState(() {
                            _paymentMethod = value!;
                          });
                        },
                        activeColor: primaryGreen,
                        contentPadding: EdgeInsets.symmetric(horizontal: 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _paymentMethod == 'cash_on_delivery'
                                ? primaryGreen
                                : Colors.grey[300]!,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      RadioListTile<String>(
                        title: Row(
                          children: [
                            Icon(Icons.credit_card, color: Colors.blue),
                            SizedBox(width: 12),
                            Text('Credit Card'),
                          ],
                        ),
                        value: 'credit_card',
                        groupValue: _paymentMethod,
                        onChanged: (value) {
                          setState(() {
                            _paymentMethod = value!;
                          });
                        },
                        activeColor: primaryGreen,
                        contentPadding: EdgeInsets.symmetric(horizontal: 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _paymentMethod == 'credit_card'
                                ? primaryGreen
                                : Colors.grey[300]!,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Error message
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ),

                SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
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
            onPressed: _isLoading ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Place Order',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        size: 20,
                        color: Colors.white,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
