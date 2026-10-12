import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/login_page.dart'; // Ensure this import is correct
import 'package:project/signup_page.dart'; // Ensure this import is correct

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  // List of background images
  final List<String> _backgroundImages = [
    'assets/backgroundwelcomescreen.jpg',
    'assets/welcomebackground2.webp',
    'assets/welcomebackground3.jpg',
  ];

  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      lowerBound: 0.2,
      upperBound: 1.0,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 4, end: 16).animate(_controller);

    // Start a timer to change the background image every 5 seconds
    _startImageLoop();
  }

  void _startImageLoop() {
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _currentImageIndex =
              (_currentImageIndex + 1) % _backgroundImages.length;
        });
        _startImageLoop(); // Restart the timer
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
    ));

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // AnimatedSwitcher for background images
          AnimatedSwitcher(
            duration: Duration(seconds: 2), // Fade animation duration
            child: Container(
              key: ValueKey<String>(_backgroundImages[_currentImageIndex]),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(_backgroundImages[_currentImageIndex]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  // Logo or Icon
                  const Icon(
                    Icons.spa_outlined,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  // Title
                  const Text(
                    'Skin Care Made Simple',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Subtitle
                  Text(
                    'Discover your perfect skincare routine with ease',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.8),
                      height: 1.5,
                    ),
                  ),
                  const Spacer(),
                  // Create Account Button with Glow Animation
                  AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: _glowAnimation.value,
                              spreadRadius: _glowAnimation.value / 2,
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            // Navigate to SignUpScreen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SignupPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            backgroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Login Button
                  TextButton(
                    onPressed: () {
                      // Navigate to LoginPage
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginPage(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Already have an account? Log in',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
