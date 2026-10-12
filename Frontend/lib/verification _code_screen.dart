import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:project/utils/snackbar_utils.dart'; // Import the new utility
import 'package:project/reset_password_screen.dart';

class VerificationCodeScreen extends StatefulWidget {
  final String email; // Pass the email from the previous screen
  const VerificationCodeScreen({super.key, required this.email});

  @override
  _VerificationCodeScreenState createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isSuccess = false;
    });

    // Combine the 6 characters into a single verification code
    final verificationCode =
        _controllers.map((controller) => controller.text).join();

    // Check if the verification code is complete
    if (verificationCode.length < 6) {
      setState(() {
        _isLoading = false;
      });
      SnackbarUtils.showErrorSnackbar(
          context, 'Please enter the complete verification code');
      return;
    }

    try {
      // Make a POST request to the verification API
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/auth/verify'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': widget.email,
          'verificationCode': verificationCode,
        }),
      );

      // Check the response status code
      if (response.statusCode == 200) {
        // Success
        final responseData = jsonDecode(response.body);
        final token =
            responseData['token']; // Extract the token from the response

        setState(() {
          _isSuccess = true;
          _isLoading = false;
        });

        // Show success snackbar
        SnackbarUtils.showSuccessSnackbar(context, 'Verification successful!');

        // Navigate to the next screen (e.g., reset password screen)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(token: token),
          ),
        );
      } else {
        // Handle errors
        final responseData = jsonDecode(response.body);
        final errorMessage =
            responseData['message'] ?? 'Invalid or expired verification code.';

        setState(() {
          _errorMessage = errorMessage;
          _isLoading = false;
        });

        // Show error snackbar
        SnackbarUtils.showErrorSnackbar(context, errorMessage);
      }
    } catch (error) {
      // Handle network or server errors
      final errorMessage =
          'An error occurred. Please check your connection and try again.';

      setState(() {
        _errorMessage = errorMessage;
        _isLoading = false;
      });

      // Show error snackbar
      SnackbarUtils.showErrorSnackbar(context, errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E7D32), // Dark Green
              Color(0xFF4CAF50), // Green
              Color(0xFF81C784), //
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_florist,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                Text(
                  'Verification Code',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter the verification code we sent to your email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    6,
                    (index) => SizedBox(
                      width: 45,
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        textAlign: TextAlign.center,
                        // Use TextInputType.text for alphanumeric input
                        keyboardType: TextInputType.text,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(1),
                          // Allow both letters and numbers
                          FilteringTextInputFormatter.allow(
                              RegExp('[a-zA-Z0-9]')),
                        ],
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.green.shade400),
                        )
                      : Text(
                          'Verify',
                          style: TextStyle(
                            color: Colors.green.shade400,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade200,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                if (_isSuccess)
                  Text(
                    'Verification successful!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Back to Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
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
}
