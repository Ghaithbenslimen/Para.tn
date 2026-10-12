import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import '../widgets/set_location_button.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String? _profileImageUrl;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUploading = false;

  // Location data
  double? _latitude;
  double? _longitude;
  String _locationAddress = '';

  // Controllers For Form Fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  // Function To Fetch The Latest Profile Data From The Backend
  Future<void> _fetchProfileData() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No Token Found Please Log In Again')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final url = Uri.parse('http://10.0.2.2:3000/auth/profile');
    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print('Profile response status: ${response.statusCode}');
      print('Profile response body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final profileData = jsonDecode(response.body);
          setState(() {
            _nameController.text = profileData['fullName'] ?? '';
            _emailController.text = profileData['email'] ?? '';
            _phoneController.text = profileData['phone'] ?? '';

            // Handle location data
            if (profileData['location'] != null) {
              // Handle address
              if (profileData['location']['address'] != null) {
                _locationAddress = profileData['location']['address'];
                _cityController.text = _locationAddress;
              }

              // Handle coordinates - Fix for the type error
              if (profileData['location']['coordinates'] != null &&
                  profileData['location']['coordinates'] is List) {
                try {
                  // Safely parse coordinates
                  var coordinates = profileData['location']['coordinates'];
                  if (coordinates.length >= 2) {
                    // Convert to double safely
                    _longitude = double.tryParse(coordinates[0].toString());
                    _latitude = double.tryParse(coordinates[1].toString());
                  }
                } catch (e) {
                  print('Error parsing coordinates: $e');
                }
              }
            }

            // Set profile image URL if available
            if (profileData['profilePicture'] != null) {
              _profileImageUrl =
                  'http://10.0.2.2:3000/${profileData['profilePicture']}';
            } else if (profileData['image'] != null) {
              // Try alternative field name that might be used for parapharmacies
              _profileImageUrl = 'http://10.0.2.2:3000/${profileData['image']}';
            }

            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No Profile Data Found')),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        String errorMessage = 'Failed To Load Profile Data';
        try {
          final responseData = jsonDecode(response.body);
          errorMessage = responseData['message'] ?? errorMessage;
        } catch (e) {
          // If response body is not valid JSON
          errorMessage = 'Server returned status ${response.statusCode}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An Error Occurred: $error')),
      );
    }
  }

  // Function To Update Profile Data
  Future<void> _updateProfile() async {
    setState(() {
      _isSaving = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No Token Found Please Log In Again')),
      );
      setState(() {
        _isSaving = false;
      });
      return;
    }

    final url = Uri.parse('http://10.0.2.2:3000/auth/update');
    try {
      // Only send the address part of the location, not coordinates
      // Removed country field from the request
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          'fullName': _nameController.text,
          'phone': _phoneController.text,
          'location':
              _cityController.text, // This will be stored as location.address
        }),
      );

      print('Update response status: ${response.statusCode}');
      print('Update response body: ${response.body}');

      setState(() {
        _isSaving = false;
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile Updated Successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        String errorMessage = 'Update Failed Try Again';
        try {
          final responseData = jsonDecode(response.body);
          errorMessage = responseData['message'] ?? errorMessage;
        } catch (e) {
          // If response body is not valid JSON
          errorMessage = 'Server returned status ${response.statusCode}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An Error Occurred: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Function To Pick Image From Gallery
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compress image for faster upload
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        _uploadImage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  // Function To Upload Image To Backend
  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    setState(() {
      _isUploading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No Token Found Please Log In Again')),
      );
      setState(() {
        _isUploading = false;
      });
      return;
    }

    final url = Uri.parse('http://10.0.2.2:3000/auth/updateProfilePicture');

    try {
      // Get file extension and mime type
      final fileExtension = path.extension(_imageFile!.path).toLowerCase();
      final mimeType = lookupMimeType(_imageFile!.path) ?? 'image/jpeg';

      print('File path: ${_imageFile!.path}');
      print('File extension: $fileExtension');
      print('Detected mime type: $mimeType');

      // Create a multipart request
      final request = http.MultipartRequest('PUT', url);

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add the file with explicit mime type
      final file = await http.MultipartFile.fromPath(
        'profilePicture', // This must match the field name expected by your server
        _imageFile!.path,
        filename:
            'profile_image$fileExtension', // Ensure filename has extension
        contentType: MediaType.parse(mimeType),
      );
      request.files.add(file);

      // Send the request
      final streamedResponse = await request.send();

      // Get the response
      final response = await http.Response.fromStream(streamedResponse);

      setState(() {
        _isUploading = false;
      });

      // Debug information
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Try to parse the response
        try {
          final responseData = jsonDecode(response.body);

          // Check for image URL in the response
          String? imageUrl;
          if (responseData['imageUrl'] != null) {
            imageUrl = responseData['imageUrl'];
          } else if (responseData['profilePicture'] != null) {
            imageUrl = responseData['profilePicture'];
          } else if (responseData['image'] != null) {
            imageUrl = responseData['image'];
          }

          if (imageUrl != null) {
            setState(() {
              _profileImageUrl = 'http://10.0.2.2:3000/$imageUrl';
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Profile Picture Updated Successfully')),
          );
        } catch (e) {
          print('Error parsing response: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Profile Picture Updated But Could Not Parse Response')),
          );
          // Refresh profile data to get the updated image URL
          _fetchProfileData();
        }
      } else {
        String errorMessage = 'Failed To Update Profile Picture';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          // If response body is not valid JSON
          errorMessage =
              'Server returned status ${response.statusCode}: ${response.body}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (error) {
      print('Upload error: $error');
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An Error Occurred: $error')),
      );
    }
  }

  // Update location display
  void _updateLocationDisplay(
      double latitude, double longitude, String address) {
    setState(() {
      _latitude = latitude;
      _longitude = longitude;
      _locationAddress = address;
      _cityController.text = address;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: const Text(
          'Edit Profile Info',
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
            child: Icon(Icons.arrow_back, color: Colors.black, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.green,
                                width: 3,
                              ),
                            ),
                          ),
                          _isUploading
                              ? const CircularProgressIndicator(
                                  color: Colors.green)
                              : CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage: _getProfileImage(),
                                  child: _profileImageUrl == null &&
                                          _imageFile == null
                                      ? const Icon(Icons.person,
                                          size: 50, color: Colors.grey)
                                      : null,
                                ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 20),
                                onPressed: _isUploading ? null : _pickImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _isUploading ? null : _pickImage,
                        child: Text(
                          'Change Profile Picture',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField('Full Name', _nameController,
                          validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      }),
                      _buildTextField('Your Mail', _emailController,
                          readOnly: true),
                      _buildTextField('Phone', _phoneController,
                          validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      }),
                      _buildTextField('City, State', _cityController),
                      // Removed country field
                      const SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location Coordinates',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.location_on,
                                        color: Colors.green, size: 18),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _latitude != null && _longitude != null
                                            ? 'Lat: ${_latitude!.toStringAsFixed(6)}, Long: ${_longitude!.toStringAsFixed(6)}'
                                            : 'No coordinates set',
                                        style: TextStyle(
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                SetLocationButton(
                                  isParapharmacy: false,
                                  onLocationUpdated: _updateLocationDisplay,
                                  initialLatitude: _latitude,
                                  initialLongitude: _longitude,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: (_isSaving || _isUploading)
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  _updateProfile();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
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

  // Helper method to get the profile image
  ImageProvider? _getProfileImage() {
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    } else if (_profileImageUrl != null) {
      return NetworkImage(_profileImageUrl!);
    }
    return null;
  }

  // Helper Method To Build Text Fields
  Widget _buildTextField(String label, TextEditingController controller,
      {bool readOnly = false, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            validator: validator,
            decoration: InputDecoration(
              filled: true,
              fillColor: readOnly ? Colors.grey[100] : Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.green[100]!,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.green[300]!,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.red[300]!,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.red[500]!,
                  width: 2,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }
}
