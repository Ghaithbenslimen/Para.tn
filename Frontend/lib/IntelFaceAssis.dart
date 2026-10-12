import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './FormIntelFaceAssis.dart';

class IntelFaceAssistPage extends StatefulWidget {
  const IntelFaceAssistPage({Key? key}) : super(key: key);

  @override
  _IntelFaceAssistPageState createState() => _IntelFaceAssistPageState();
}

class _IntelFaceAssistPageState extends State<IntelFaceAssistPage>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _buttonGlowController;
  late AnimationController _scanAnimationController;

  // Animations
  late Animation<double> _fadeInAnimation;
  late Animation<double> _fadeOutAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _scanPulseAnimation;

  // List of image assets for the face scan animation
  final List<String> _images = [
    'assets/intelfaceass4.jpg',
    'assets/intelfaceass5.jpg',
    'assets/intelface3.jpeg',
  ];

  // Track current and next image indexes
  int _currentImageIndex = 0;
  int _nextImageIndex = 1;

  @override
  void initState() {
    super.initState();

    // Initialize the fade controller for image transitions
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            // Update current image to be the next image
            _currentImageIndex = _nextImageIndex;
            // Calculate the new next image
            _nextImageIndex = (_currentImageIndex + 1) % _images.length;
          });
          // Reset and restart the animation
          _fadeController.reset();
          _fadeController.forward();
        }
      });

    // Create fade in/out animations with specific timing
    // Fade out current image from 1.0 to 0.0 over the full duration
    _fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Fade in next image from 0.0 to 1.0 starting at the midpoint
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Initialize the button glow animation controller
    _buttonGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(
        parent: _buttonGlowController,
        curve: Curves.easeInOut,
      ),
    );

    // Initialize the scan animation controller
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _scanPulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _scanAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start the first transition
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _buttonGlowController.dispose();
    _scanAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Set the status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Current image with fade out animation
          AnimatedBuilder(
            animation: _fadeOutAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeOutAnimation.value,
                child: Image.asset(
                  _images[_currentImageIndex],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              );
            },
          ),

          // Next image with fade in animation
          AnimatedBuilder(
            animation: _fadeInAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeInAnimation.value,
                child: Image.asset(
                  _images[_nextImageIndex],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              );
            },
          ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.green.withOpacity(0.6),
                  Colors.green.withOpacity(0.3),
                ],
              ),
            ),
          ),

          // Center scan icon with animation
          Center(
            child: AnimatedBuilder(
              animation: _scanPulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scanPulseAnimation.value,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.width * 0.7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.6),
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Center scan icon
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.greenAccent.withOpacity(0.5),
                                  blurRadius: 15,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.face_retouching_natural,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),

                        // Corner indicators
                        Positioned(
                          top: 0,
                          left: 0,
                          child: _buildCornerIndicator(),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: _buildCornerIndicator(rotate: 90),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: _buildCornerIndicator(rotate: 180),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: _buildCornerIndicator(rotate: 270),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Content: Title text and Get Started button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const Spacer(),
                  // Title Text
                  const Text(
                    'Start your face scan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                      fontFamily: 'Poppins',
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Subtitle text
                  Text(
                    'IntelFaceAssis AI-powered facial analysis',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontFamily: 'Poppins',
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Get Started Button with glowing animation
                  AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.6),
                              blurRadius: _glowAnimation.value * 2,
                              spreadRadius: _glowAnimation.value / 2,
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const SkincareFormPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            backgroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 60),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Get Started',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins'),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerIndicator({double rotate = 0}) {
    return Transform.rotate(
      angle: rotate * 3.14159 / 180,
      child: Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white, width: 3),
            left: BorderSide(color: Colors.white, width: 3),
          ),
        ),
      ),
    );
  }
}
