import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:project/verification%20_code_screen.dart';
import 'package:project/utils/snackbar_utils.dart'; // Import the new utility
import 'dart:convert';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _EnhancedForgotPasswordPageState createState() =>
      _EnhancedForgotPasswordPageState();
}

class _EnhancedForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _isSuccess = false;
      });

      final String email = _emailController.text.trim();

      try {
        final response = await http.post(
          Uri.parse('http://10.0.2.2:3000/auth/forgetpassword'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'email': email,
          }),
        );

        if (response.statusCode == 201) {
          setState(() {
            _isSuccess = true;
            _isLoading = false;
          });

          // Show success snackbar
          SnackbarUtils.showSuccessSnackbar(
              context, 'Password reset instructions sent to your email');

          // Navigate to the VerificationCodeScreen and pass the email
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VerificationCodeScreen(email: email),
            ),
          );
        } else {
          final responseData = jsonDecode(response.body);
          final errorMessage = responseData['message'] ??
              'Failed to reset password. Please try again.';

          setState(() {
            _errorMessage = errorMessage;
            _isLoading = false;
          });

          // Show error snackbar
          SnackbarUtils.showErrorSnackbar(context, errorMessage);
        }
      } catch (error) {
        final errorMessage =
            'An error occurred. Please check your connection and try again.';

        setState(() {
          _errorMessage = errorMessage;
          _isLoading = false;
        });

        // Show error snackbar
        SnackbarUtils.showErrorSnackbar(context, errorMessage);
      }
    } else {
      // Show validation error snackbar
      SnackbarUtils.showErrorSnackbar(
          context, 'Please enter a valid email address');
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
    ));

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2E7D32), // Dark Green
              Color(0xFF4CAF50), // Green
              Color(0xFF81C784), // Light Green
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 170),
                  const Icon(
                    Icons.spa_outlined,
                    size: 80,
                    color: Colors.white,
                  ),
                  Text(
                    'Forgot Password',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Enter your email and we\'ll send you instructions to reset your password',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.email, color: Color(0xFF2E7D32)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Color(0xFF2E7D32),
                      backgroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF2E7D32)))
                        : Text(
                            'Reset Password',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[400], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  if (_isSuccess)
                    Text(
                      'Password reset instructions sent to your email.',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'Back to Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
