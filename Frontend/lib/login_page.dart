import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/parapharmacy_page.dart';
import 'package:project/screens/admin_layout.dart';
import 'package:project/services/auth_service.dart';
import 'package:project/utils/snackbar_utils.dart'; // Import the new utility
import 'home_screen.dart';
import 'forgot_password.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers for the email and password fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Global key for form validation
  final _formKey = GlobalKey<FormState>();

  // Auth service instance
  final AuthService _authService = AuthService();

  // Loading state
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Function to call the login method from AuthService.
  /// It trims the input values to remove any trailing or leading spaces.
  Future<void> _loginUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // First, reset auth state to ensure clean login.
      await _authService.logout();

      // Trim email and password before calling login.
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Then attempt login using AuthService
      final success = await _authService.login(email, password);

      if (success) {
        // Check if user is authenticated and get user details
        final userId = await _authService.getCurrentUserId();
        final userName = await _authService.getCurrentUsername();
        // Use the dedicated method to check if the user is a parapharmacie user.
        final isParapharmacie = await _authService.isParapharmacieUser();

        debugPrint(
            'Login successful - User: $userName, ID: $userId, isParapharmacie: $isParapharmacie');

        // Navigate based on user type
        if (isParapharmacie) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminLayout()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ParapharmacyPage()),
          );
        }

        // Show success snackbar
        SnackbarUtils.showSuccessSnackbar(context, 'Login successful!');
      } else {
        setState(() {
          _errorMessage = 'Invalid email or password';
        });
        // Show error snackbar
        SnackbarUtils.showErrorSnackbar(context, 'Invalid email or password');
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'An error occurred: $error';
      });
      // Show error snackbar
      SnackbarUtils.showErrorSnackbar(context, 'An error occurred: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set the status bar color to transparent
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2E7D32),
              Color(0xFF4CAF50),
              Color(0xFF81C784),
            ],
          ),
        ),
        child: Center(
          // <-- Added Center widget here
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SingleChildScrollView(
                // <-- Added for scrollable content
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // <-- Center vertically
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.spa_outlined,
                        size: 80,
                        color: Colors.white,
                      ),
                      const Text(
                        'Welcome Back',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Log in to your account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Email Field
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
                          prefixIcon:
                              const Icon(Icons.email, color: Color(0xFF2E7D32)),
                        ),
                        validator: (value) {
                          final trimmedValue = value?.trim() ?? '';
                          if (trimmedValue.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(trimmedValue)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon:
                              const Icon(Icons.lock, color: Color(0xFF2E7D32)),
                        ),
                        validator: (value) {
                          final trimmedValue = value?.trim() ?? '';
                          if (trimmedValue.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Login Button
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  _loginUser();
                                } else {
                                  // Show validation error snackbar
                                  SnackbarUtils.showErrorSnackbar(
                                      context, 'Please fix the errors above');
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: const Color(0xFF2E7D32),
                          backgroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF2E7D32)),
                                ),
                              )
                            : const Text(
                                'Log In',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Text(
                            _errorMessage,
                            style: TextStyle(
                              color: Colors.red[100],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Forgot Password Button
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const ForgotPasswordPage()),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // Navigate to Sign Up
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(color: Colors.white),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const SignupPage()),
                              );
                            },
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
