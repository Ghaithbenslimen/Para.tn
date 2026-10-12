import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddCardPage extends StatefulWidget {
  final int cardType; // 0: My Card, 1: PayPal, 2: Google Pay, 3: Apple Pay
  const AddCardPage({Key? key, required this.cardType}) : super(key: key);

  @override
  _AddCardPageState createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  final _formKey = GlobalKey<FormState>();
  String cardNumber = '';
  String cardHolder = '';
  String expiryDate = '';
  String cvv = '';

  @override
  Widget build(BuildContext context) {
    // Choose the card icon based on card type
    String cardIcon;
    switch (widget.cardType) {
      case 0:
        cardIcon = 'assets/card_icon.png'; // My Card
        break;
      case 1:
        cardIcon = 'assets/paypal.png'; // PayPal
        break;
      case 2:
        cardIcon = 'assets/googlepay.png'; // Google Pay
        break;
      case 3:
        cardIcon = 'assets/appel pay.png'; // Apple Pay
        break;
      default:
        cardIcon = 'assets/mastercard.png'; // fallback icon
    }

    // Define card decoration and text color based on card type
    BoxDecoration cardDecoration;
    Color textColor = Colors.white; // default text color for dark backgrounds

    switch (widget.cardType) {
      case 0: // My Card design (green gradient)
        cardDecoration = BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        );
        break;
      case 1: // PayPal design (blue gradient)
        cardDecoration = BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF003087), Color(0xFF009CDE)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        );
        break;
      case 2: // Google Pay design (white background)
        cardDecoration = BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        );
        textColor = Colors.black; // dark text on a light background
        break;
      case 3: // Apple Pay design (sleek black card)
        cardDecoration = BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black87, Colors.black],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        );
        break;
      default:
        cardDecoration = BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF1F8F1), // Light green background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF2E7D32)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Add card',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Preview Container with dynamic design
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: cardDecoration,
                  child: Stack(
                    children: [
                      // Chip Image (skip chip for Google Pay if desired)
                      if (widget.cardType != 2)
                        Positioned(
                          top: 20,
                          left: 20,
                          child: Image.asset(
                            'assets/chip.png',
                            height: 40,
                            width: 40,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.credit_card_rounded,
                              color: textColor.withOpacity(0.7),
                              size: 40,
                            ),
                          ),
                        ),
                      // Card Details (number, holder name, expiry date)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              cardNumber.isEmpty
                                  ? '0000 0000 0000 0000'
                                  : cardNumber,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 22,
                                letterSpacing: 2,
                                fontFamily: 'monospace',
                              ),
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CARD HOLDER',
                                      style: TextStyle(
                                        color: textColor.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      cardHolder.isEmpty
                                          ? 'FULL NAME'
                                          : cardHolder.toUpperCase(),
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'EXPIRES',
                                      style: TextStyle(
                                        color: textColor.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      expiryDate.isEmpty ? 'MM/YY' : expiryDate,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Card Icon based on selection
                      Positioned(
                        top: 20,
                        right: 20,
                        child: Image.asset(
                          cardIcon,
                          height: 40,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.payment,
                            color: textColor.withOpacity(0.7),
                            size: 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),
                // Card Holder Name Input
                TextFormField(
                  decoration: _buildInputDecoration('Card Holder Name'),
                  onChanged: (value) {
                    setState(() {
                      cardHolder = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter card holder name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                // Card Number Input
                TextFormField(
                  decoration: _buildInputDecoration('Card Number'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                    _CardNumberFormatter(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      cardNumber = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter card number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                // Expiry Date and CVV inputs
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: _buildInputDecoration('MM/YY'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                          _ExpiryDateFormatter(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            expiryDate = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: _buildInputDecoration('CVV'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        onChanged: (value) {
                          setState(() {
                            cvv = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32),
                // Add Card Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Process card data
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Processing Card Details...'),
                            backgroundColor: Color(0xFF2E7D32),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Add Card',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Custom InputDecoration for form fields
  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600]),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFF2E7D32).withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFF2E7D32)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}

// Formatter to add spaces in the card number
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    String numbers = newValue.text.replaceAll(' ', '');
    String newString = '';
    for (int i = 0; i < numbers.length; i++) {
      if (i > 0 && i % 4 == 0) newString += ' ';
      newString += numbers[i];
    }
    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}

// Formatter to add a slash in the expiry date
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    String numbers = newValue.text.replaceAll('/', '');
    String newString = '';
    for (int i = 0; i < numbers.length; i++) {
      if (i == 2) newString += '/';
      newString += numbers[i];
    }
    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}
