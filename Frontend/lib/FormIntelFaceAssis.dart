import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import './recommandation_page.dart';

class SkincareFormPage extends StatefulWidget {
  const SkincareFormPage({super.key});

  @override
  State<SkincareFormPage> createState() => _SkincareFormPageState();
}

class _SkincareFormPageState extends State<SkincareFormPage>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  String? _morningSkinFeel;
  final Set<String> _skinReactions = {};
  int? _age;
  String? _gender;
  bool _faceScanConsent = false;
  bool _isScanning = false;
  bool _isProcessing = false;
  bool _isFullScreenCamera = false;
  bool _isAnalysisComplete = false;
  Map<String, dynamic>? _analysisResults;

  // Age validation error
  String? _ageError;

  // Camera variables
  List<CameraDescription>? _cameras;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  File? _capturedImage;
  bool _isCameraPermissionDenied = false;

  // Image picker
  final ImagePicker _picker = ImagePicker();

  // Animation controller for page transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Green color scheme with enhanced aesthetics
  final Color _primaryColor = const Color(0xFF1E8449); // Deeper green
  final Color _secondaryColor = const Color(0xFF58D68D); // Brighter green
  final Color _accentColor = const Color(0xFFFF9800); // Orange accent
  final Color _backgroundColor = const Color(0xFFF8F9FA); // Lighter background
  final Color _cardColor = Colors.white;
  final Color _textColor = const Color(0xFF2C3E50); // Darker text
  final Color _hintColor = const Color(0xFF7F8C8D); // Slate hint text
  final Color _errorColor = Colors.red.shade700; // Error color

  // API endpoint
  // final String _apiUrl = 'http://10.0.2.2:5000/predict'; // For Android emulator
  // Use 'http://127.0.0.1:5000/predict' for iOS simulator

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();

    // Initialize camera
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Get available cameras
      _cameras = await availableCameras();

      if (_cameras != null && _cameras!.isNotEmpty) {
        // Initialize the front camera if available, otherwise use the first camera
        final frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );

        await _initializeCameraController(frontCamera);
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      setState(() {
        _isCameraPermissionDenied = true;
      });
    }
  }

  Future<void> _initializeCameraController(
      CameraDescription cameraDescription) async {
    // Create a new camera controller
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // Initialize the controller
    try {
      await cameraController.initialize();

      if (mounted) {
        setState(() {
          _cameraController = cameraController;
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera controller: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      // Take the picture
      final XFile photo = await _cameraController!.takePicture();

      // Save the picture to a file
      final File savedImage = File(photo.path);

      if (mounted) {
        setState(() {
          _capturedImage = savedImage;
          _isFullScreenCamera = false;
          _isScanning = false;
          _isProcessing = false;
          // Reset analysis state when taking a new picture
          _isAnalysisComplete = false;
          _analysisResults = null;
        });
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  // API method to analyze face image
  Future<Map<String, dynamic>> _analyzeFaceImageApi(File imageFile) async {
    try {
      // API endpoint
      final String apiUrl =
          'http://10.0.2.2:5000/predict'; // For Android emulator
      // Use 'http://127.0.0.1:5000/predict' for iOS simulator

      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      // Add file to request
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ));

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Parse response
        return json.decode(response.body);
      } else {
        // Handle error
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // Method to analyze face image with backend
  Future<void> _analyzeFaceImage() async {
    // Check if user has consented to face scan
    if (!_faceScanConsent) {
      _showErrorDialog(
          'You must consent to the face scan before analyzing your skin.');
      return;
    }

    if (_capturedImage == null) {
      _showErrorDialog('Please take a photo first.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _isAnalysisComplete = false;
      _analysisResults = null;
    });

    try {
      // Use the internal API method
      Map<String, dynamic> results =
          await _analyzeFaceImageApi(_capturedImage!);

      setState(() {
        _analysisResults = results;
        _isAnalysisComplete = true;
        _isProcessing = false;
      });

      // Show analysis results dialog
      _showAnalysisResultsDialog();
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorDialog('Error: ${e.toString()}');
    }
  }

  // New method to pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        setState(() {
          _capturedImage = File(pickedFile.path);
          _isScanning = false;
          // Reset analysis state when picking a new image
          _isAnalysisComplete = false;
          _analysisResults = null;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showAnalysisResultsDialog() {
    if (_analysisResults == null) return;

    // Check if confidence is under 40%
    final double confidence = _analysisResults!['confidence'] as double;
    final bool noIssues = confidence < 0.4; // 40% threshold

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 24), // Add padding
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8, // Limit height
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    children: [
                      Icon(noIssues ? Icons.check_circle : Icons.analytics,
                          color: noIssues ? Colors.green : _accentColor,
                          size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Skin Analysis Results',
                        style: TextStyle(
                          color: _textColor,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (noIssues)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'You have no issue with your face!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade800,
                                    fontSize: 16,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Primary Condition:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _textColor,
                                fontSize: 16,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber,
                                      color: _primaryColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _analysisResults!['predicted_class'] ??
                                          'Unknown',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: _textColor,
                                        fontSize: 16,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      Text(
                        'Confidence: ${(_analysisResults!['confidence'] * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: _textColor.withOpacity(0.8),
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!noIssues) ...[
                        Text(
                          'Other Potential Conditions:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _textColor,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_analysisResults!.containsKey('all_probs'))
                          ..._buildProbabilityBars(
                              _analysisResults!['all_probs']),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: _primaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'CLOSE',
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          // Disable the button when no issues are detected
                          disabledBackgroundColor: Colors.grey.shade400,
                          disabledForegroundColor: Colors.white,
                        ),
                        // Set onPressed to null when no issues are detected to disable the button
                        onPressed: noIssues
                            ? null
                            : () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RecommendationPage(
                                      analysisResults: _analysisResults,
                                    ),
                                  ),
                                );
                              },
                        child: const Text(
                          'VIEW RECOMMENDATIONS',
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildProbabilityBars(Map<String, dynamic> probabilities) {
    // Sort probabilities in descending order
    List<MapEntry<String, dynamic>> sortedEntries = probabilities.entries
        .toList()
      ..sort((a, b) => (b.value as double).compareTo(a.value as double));

    // Skip the first one as it's already shown as the primary condition
    sortedEntries = sortedEntries.skip(1).take(3).toList();

    return sortedEntries.map((entry) {
      double probability = entry.value as double;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 14,
                    color: _textColor,
                  ),
                ),
                Text(
                  '${(probability * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _textColor,
                      fontFamily: 'Poppins'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: probability,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(_secondaryColor),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
      );
    }).toList();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            const Text(
              'Error',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If in full screen camera mode, show only the camera
    if (_isFullScreenCamera) {
      return _buildFullScreenCamera();
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'IntelFaceAssis',
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Colors.white,
              fontFamily: 'Poppins'),
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Custom progress indicator
          _buildProgressIndicator(),

          // Main content
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: _buildCurrentStep(),
                ),
              ),
            ),
          ),

          // Navigation buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildFullScreenCamera() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full screen camera view
          SizedBox.expand(
            child: _buildCameraPreview(isFullScreen: true),
          ),

          // Top bar with close button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                right: 8,
                bottom: 8,
              ),
              color: Colors.black.withOpacity(0.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _isFullScreenCamera = false;
                        _isScanning = false;
                      });
                    },
                  ),
                  Text(
                    'IntelFaceAssis',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins'),
                  ),
                  const SizedBox(width: 48), // Balance the layout
                ],
              ),
            ),
          ),

          // Capture button at bottom
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: _accentColor,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _accentColor.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _accentColor,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Face outline overlay
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _accentColor,
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.3),
                    blurRadius: 16,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
          ),

          // Corner indicators
          Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: Stack(
                children: [
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
          ),

          // Instructions
          Positioned(
            bottom: 130,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Text(
                  'Align your face with the circle',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: _primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of ${_getTotalSteps()}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins'),
              ),
              Text(
                '${((_currentStep + 1) / _getTotalSteps() * 100).toInt()}%',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _getTotalSteps(),
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  int _getTotalSteps() {
    return _faceScanConsent ? 5 : 4;
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildMorningSkinFeelSection();
      case 1:
        return _buildSkinReactionsSection();
      case 2:
        return _buildDemographicsSection();
      case 3:
        return _buildFaceScanConsentSection();
      case 4:
        return _buildFaceScanSection();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            OutlinedButton.icon(
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text(
                'BACK',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              onPressed: _previousStep,
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryColor,
                side: BorderSide(color: _primaryColor),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          else
            const SizedBox(width: 100),
          ElevatedButton.icon(
            icon: Icon(
              Icons.arrow_forward,
              size: 18,
              color: Colors.white,
            ),
            label: Text(
              'NEXT',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            onPressed: _isNextButtonEnabled() ? _nextStep : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _primaryColor.withOpacity(0.5),
              disabledForegroundColor: Colors.white.withOpacity(0.7),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  bool _isNextButtonEnabled() {
    switch (_currentStep) {
      case 0:
        return _morningSkinFeel != null;
      case 1:
        return _skinReactions.isNotEmpty;
      case 2:
        return _age != null && _gender != null && _ageError == null;
      case 3:
        return _faceScanConsent; // Only enabled when consent is given
      case 4:
        return _isAnalysisComplete; // Only enabled when analysis is complete
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_currentStep < _getTotalSteps() - 1) {
      setState(() {
        _currentStep += 1;
        _animationController.reset();
      });
      _animationController.forward();
    } else {
      // Navigate to recommendations page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecommendationPage(
            analysisResults: _analysisResults,
          ),
        ),
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
        _animationController.reset();
      });
      _animationController.forward();
    }
  }

  Widget _buildMorningSkinFeelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Morning Skin Feel',
          'How does your skin feel when you wake up?',
          Icons.wb_sunny_outlined,
        ),
        const SizedBox(height: 24),
        ...['Normal', 'Dry', 'Oily', 'Combination', 'Sensitive']
            .map((option) => _buildCheckboxOption(option, isSingleSelect: true))
            .toList(),
      ],
    );
  }

  Widget _buildSkinReactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Skin Reactions',
          'How does your skin react to skincare products or external conditions?',
          Icons.healing_outlined,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Select all that apply',
            style: TextStyle(
                fontSize: 14,
                color: _hintColor,
                fontStyle: FontStyle.italic,
                fontFamily: 'Poppins'),
          ),
        ),
        const SizedBox(height: 24),
        ...[
          'Redness/Irritation',
          'Breakouts',
          'Dryness/Flaking',
          'Shine (excess oil)',
          'No reaction'
        ].map((option) => _buildCheckboxOption(option)).toList(),
      ],
    );
  }

  Widget _buildDemographicsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Demographics',
          'Please provide some basic information about yourself',
          Icons.person_outline,
        ),
        const SizedBox(height: 24),

        // Age Field
        Text(
          'What is your age?',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _textColor,
              fontFamily: 'Poppins'),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            decoration: InputDecoration(
              hintText: 'Enter your age (must be 18+)',
              hintStyle: TextStyle(fontFamily: 'Poppins'),
              prefixIcon: Icon(Icons.person_outline, color: _primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: _cardColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              errorText: _ageError,
              errorStyle: TextStyle(
                color: _errorColor,
                fontFamily: 'Poppins',
              ),
            ),
            keyboardType: TextInputType.number,
            style: TextStyle(
                fontSize: 16, color: _textColor, fontFamily: 'Poppins'),
            onChanged: (value) {
              final age = int.tryParse(value);
              setState(() {
                if (age == null) {
                  _age = null;
                  _ageError = 'Please enter a valid age';
                } else if (age < 18) {
                  _age = null;
                  _ageError = 'You must be 18 or older to use this app';
                } else if (age > 120) {
                  _age = null;
                  _ageError = 'Please enter a valid age';
                } else {
                  _age = age;
                  _ageError = null;
                }
              });
            },
          ),
        ),

        const SizedBox(height: 24),

        // Gender Field
        Text(
          'What is your gender?',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _textColor,
              fontFamily: 'Poppins'),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.person, color: _primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: _cardColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            value: _gender,
            style: TextStyle(
                fontSize: 16, color: _textColor, fontFamily: 'Poppins'),
            items: const [
              DropdownMenuItem(
                value: 'Female',
                child: Text(
                  'Female',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
              ),
              DropdownMenuItem(
                value: 'Male',
                child: Text(
                  'Male',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _gender = value;
              });
            },
            hint: Text('Select your gender',
                style: TextStyle(color: _hintColor, fontFamily: 'Poppins')),
            icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
            dropdownColor: _cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }

  Widget _buildFaceScanConsentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'AI-Powered Face Scan',
          'Get personalized skin analysis with our advanced technology',
          Icons.face_retouching_natural,
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.face_retouching_natural,
                  size: 40,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Enhance Your Skincare Journey',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                    fontFamily: 'Poppins'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Our AI technology analyzes your skin to provide personalized recommendations tailored to your unique needs.',
                style: TextStyle(
                    fontSize: 14,
                    color: _textColor.withOpacity(0.8),
                    height: 1.5,
                    fontFamily: 'Poppins'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: Text(
                  'I consent to the face scan',
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: _textColor,
                      fontFamily: 'Poppins'),
                ),
                subtitle: Text(
                  'Your data is processed securely and never stored',
                  style: TextStyle(
                      fontSize: 12, color: _hintColor, fontFamily: 'Poppins'),
                ),
                value: _faceScanConsent,
                onChanged: (value) {
                  setState(() {
                    _faceScanConsent = value;
                    // Reset analysis state when consent changes
                    if (!value) {
                      _isAnalysisComplete = false;
                      _analysisResults = null;
                    }
                  });
                },
                activeColor: _accentColor,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor:
                    _faceScanConsent ? _primaryColor.withOpacity(0.05) : null,
              ),
            ],
          ),
        ),
        if (_faceScanConsent)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Container(
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: _accentColor,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Privacy Notice',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _textColor,
                              fontSize: 14,
                              fontFamily: 'Poppins'),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your face scan is processed locally and securely. No images are stored on our servers.',
                          style: TextStyle(
                              fontSize: 12,
                              color: _textColor.withOpacity(0.8),
                              height: 1.4,
                              fontFamily: 'Poppins'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFaceScanSection() {
    if (_isProcessing) {
      return _buildProcessingView();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Face Scan',
          'Let\'s analyze your skin for personalized recommendations',
          Icons.camera_alt_outlined,
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: _isScanning
                    ? _buildCameraPreview()
                    : _capturedImage != null
                        ? _buildCapturedImagePreview()
                        : _buildPreScanView(),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: _isScanning
                    ? Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.fullscreen,
                                  size: 20, color: Colors.white),
                              label: const Text(
                                'FULL SCREEN',
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isFullScreenCamera = true;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.camera_alt,
                                  size: 20, color: Colors.white),
                              label: const Text(
                                'CAPTURE',
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accentColor,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _takePicture,
                            ),
                          ),
                        ],
                      )
                    : _capturedImage != null
                        ? Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(
                                    Icons.refresh,
                                    size: 20,
                                  ),
                                  label: const Text(
                                    'RETAKE',
                                    style: TextStyle(fontFamily: 'Poppins'),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _primaryColor,
                                    side: BorderSide(color: _primaryColor),
                                    minimumSize: const Size(0, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _capturedImage = null;
                                      _isScanning = true;
                                      // Reset analysis state when retaking photo
                                      _isAnalysisComplete = false;
                                      _analysisResults = null;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.check_circle,
                                      size: 20, color: Colors.white),
                                  label: const Text(
                                    'ANALYZE',
                                    style: TextStyle(fontFamily: 'Poppins'),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primaryColor,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(0, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: _faceScanConsent
                                      ? _analyzeFaceImage
                                      : () => _showErrorDialog(
                                          'You must consent to the face scan before analyzing.'),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.camera_alt,
                                    size: 20, color: Colors.white),
                                label: const Text(
                                  'TAKE A PHOTO',
                                  style: TextStyle(fontFamily: 'Poppins'),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  if (_isCameraPermissionDenied) {
                                    _showCameraPermissionDialog();
                                  } else {
                                    setState(() {
                                      _isScanning = true;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.photo_library, size: 20),
                                label: const Text(
                                  'UPLOAD FROM GALLERY',
                                  style: TextStyle(fontFamily: 'Poppins'),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _primaryColor,
                                  side: BorderSide(color: _primaryColor),
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _pickImageFromGallery,
                              ),
                            ],
                          ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tips for best results:',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                    fontSize: 14,
                    fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 12),
              _buildTipItem('Ensure good lighting on your face'),
              _buildTipItem('Remove glasses and pull back hair'),
              _buildTipItem('Face the camera directly'),
              _buildTipItem('Keep a neutral expression'),
            ],
          ),
        ),

        // Analysis status indicator
        if (_capturedImage != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              decoration: BoxDecoration(
                color: _isAnalysisComplete
                    ? _primaryColor.withOpacity(0.1)
                    : _errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isAnalysisComplete
                      ? _primaryColor.withOpacity(0.3)
                      : _errorColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _isAnalysisComplete
                        ? Icons.check_circle
                        : Icons.warning_amber_rounded,
                    color: _isAnalysisComplete ? _primaryColor : _errorColor,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _isAnalysisComplete
                          ? 'Analysis complete! You can now view your recommendations.'
                          : 'Please click "ANALYZE" to process your skin image.',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color:
                            _isAnalysisComplete ? _primaryColor : _errorColor,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showCameraPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Camera Permission Required',
          style: TextStyle(
              color: _textColor,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins'),
        ),
        content: Text(
          'Please grant camera permission in your device settings to use the face scan feature.',
          style: TextStyle(
              color: _textColor.withOpacity(0.8), fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: _primaryColor, fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapturedImagePreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16),
          ),
          child: Image.file(
            _capturedImage!,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            decoration: BoxDecoration(
              color: _isAnalysisComplete ? _primaryColor : _accentColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isAnalysisComplete ? Icons.check_circle : Icons.check,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreScanView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.face,
            size: 60,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Ready to scan your skin',
          style: TextStyle(
              color: _textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins'),
        ),
        const SizedBox(height: 8),
        Text(
          'Position your face in good lighting',
          style:
              TextStyle(color: _hintColor, fontSize: 14, fontFamily: 'Poppins'),
        ),
      ],
    );
  }

  Widget _buildCameraPreview({bool isFullScreen = false}) {
    if (_isCameraPermissionDenied) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.no_photography,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Camera permission denied',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                  fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 8),
            Text(
              'Please enable camera access in settings',
              style: TextStyle(
                  fontSize: 14, color: _hintColor, fontFamily: 'Poppins'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!_isCameraInitialized || _cameraController == null) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
        ),
      );
    }

    return ClipRRect(
      borderRadius: isFullScreen
          ? BorderRadius.zero
          : const BorderRadius.vertical(top: Radius.circular(16)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController!),

          // Add a semi-transparent overlay to darken the camera preview slightly
          Container(
            color: Colors.black.withOpacity(0.15),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Processing',
          'Analyzing your skin profile',
          Icons.analytics_outlined,
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              if (_capturedImage != null)
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _primaryColor,
                      width: 3,
                    ),
                    image: DecorationImage(
                      image: FileImage(_capturedImage!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              if (_capturedImage == null)
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                    strokeWidth: 6,
                  ),
                ),
              const SizedBox(height: 32),
              Text(
                'Analyzing your skin...',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                    fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 16),
              Text(
                'We\'re processing your skin data to create personalized recommendations',
                style: TextStyle(
                    fontSize: 14,
                    color: _hintColor,
                    height: 1.5,
                    fontFamily: 'Poppins'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                backgroundColor: Colors.grey[200],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: _primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                  fontFamily: 'Poppins'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            subtitle,
            style: TextStyle(
                fontSize: 16,
                color: _textColor.withOpacity(0.8),
                fontFamily: 'Poppins'),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxOption(String option, {bool isSingleSelect = false}) {
    final isSelected = isSingleSelect
        ? _morningSkinFeel == option
        : _skinReactions.contains(option);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              if (isSingleSelect) {
                _morningSkinFeel = option;
              } else {
                if (isSelected) {
                  _skinReactions.remove(option);
                } else {
                  _skinReactions.add(option);
                }
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? _primaryColor : Colors.grey[200]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: isSelected ? _primaryColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? _primaryColor : _hintColor,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: _textColor,
                        fontFamily: 'Poppins'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: _accentColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                  fontSize: 14,
                  color: _textColor.withOpacity(0.8),
                  fontFamily: 'Poppins'),
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
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: _accentColor, width: 3),
            left: BorderSide(color: _accentColor, width: 3),
          ),
        ),
      ),
    );
  }
}
