import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/add_card_page.dart';

class PaymentMethodPage extends StatefulWidget {
  const PaymentMethodPage({Key? key}) : super(key: key);

  @override
  _PaymentMethodPageState createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  int? _selectedMethod;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
    );

    return Scaffold(
      backgroundColor: Color(0xFFF1F8F1), // Light green background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color.fromARGB(255, 2, 2, 2)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Payment method',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Payment Method Options
            _buildPaymentOption(
              0,
              'My Card',
              Icons.credit_card,
              'assets/card_icon.png',
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              1,
              'PayPal',
              Icons.payment,
              'assets/paypal.png',
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              2,
              'Google Pay',
              Icons.g_mobiledata,
              'assets/googlepay.png',
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              3,
              'Apple Pay',
              Icons.apple,
              'assets/appel pay.png',
            ),
            const Spacer(),
            // Confirm Payment Button
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: _selectedMethod != null
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddCardPage(cardType: _selectedMethod!),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFF2E7D32),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Confirm Payment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    int index,
    String title,
    IconData fallbackIcon,
    String assetPath,
  ) {
    bool isSelected = _selectedMethod == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Color(0xFF2E7D32) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Color(0xFFEEEEEE),
                  width: 1,
                ),
              ),
              child: Icon(
                fallbackIcon,
                color: Color(0xFF2E7D32),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2E7D32),
              ),
            ),
            Spacer(),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Color(0xFF2E7D32) : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
