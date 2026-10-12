import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import '../widgets/set_location_button.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  File? _imageFile;
  String? _existingImageUrl;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isFetching = true; // To track if data is being fetched

  // Location data
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _fetchParapharmacyData(); // Fetch parapharmacy data when the page loads
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Fetch parapharmacy data from the backend
  Future<void> _fetchParapharmacyData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final url = Uri.parse('http://10.0.2.2:3000/auth/profile');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Parapharmacy profile response: ${response.statusCode}');
      print('Parapharmacy profile body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          _nameController.text = responseData['name'] ?? '';
          _phoneController.text = responseData['phone'] ?? '';
          _emailController.text = responseData['email'] ?? '';
          _addressController.text = responseData['address'] ?? '';
          _descriptionController.text = responseData['description'] ?? '';
          _existingImageUrl = responseData['image'];

          // Set location coordinates if available
          if (responseData['location'] != null &&
              responseData['location']['coordinates'] != null &&
              responseData['location']['coordinates'].length >= 2) {
            try {
              // GeoJSON format is [longitude, latitude]
              _longitude = double.parse(
                  responseData['location']['coordinates'][0].toString());
              _latitude = double.parse(
                  responseData['location']['coordinates'][1].toString());
            } catch (e) {
              print('Error parsing coordinates: $e');
            }
          }

          _isFetching = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch parapharmacy data.')),
        );
        setState(() {
          _isFetching = false;
        });
      }
    } catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('An error occurred: $error')));
      setState(() {
        _isFetching = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  // Update location display
  void _updateLocationDisplay(
      double latitude, double longitude, String address) {
    setState(() {
      _latitude = latitude;
      _longitude = longitude;
      _addressController.text = address;
    });
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      try {
        String? imageUrl;

        // If an image is selected, upload it first.
        if (_imageFile != null) {
          final imageUploadUrl =
              Uri.parse('http://10.0.2.2:3000/auth/updateProfilePicture');

          final imageRequest = http.MultipartRequest('PUT', imageUploadUrl);
          imageRequest.headers['Authorization'] = 'Bearer $token';

          // Determine MIME type based on file extension.
          String mimeType = 'image/jpeg';
          if (_imageFile!.path.toLowerCase().endsWith('.png')) {
            mimeType = 'image/png';
          }
          final mimeParts = mimeType.split('/');

          imageRequest.files.add(await http.MultipartFile.fromPath(
            'profilePicture',
            _imageFile!.path,
            contentType: MediaType(mimeParts[0], mimeParts[1]),
          ));

          final imageStreamedResponse = await imageRequest.send();
          final imageResponse =
              await http.Response.fromStream(imageStreamedResponse);

          if (imageResponse.statusCode == 200) {
            final imageData = json.decode(imageResponse.body);
            imageUrl = imageData['imageUrl'];
          } else {
            throw Exception('Failed to upload image: ${imageResponse.body}');
          }
        }

        // Then update the parapharmacy info with (or without) the new image URL.
        final updateUrl =
            Uri.parse('http://10.0.2.2:3000/auth/update-parapharmacy');
        final updateBody = {
          'name': _nameController.text,
          'phone': _phoneController.text,
          'email': _emailController.text,
          'address': _addressController.text,
          'description': _descriptionController.text,
        };

        if (imageUrl != null) {
          updateBody['image'] = imageUrl;
        }

        final response = await http.put(
          updateUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(updateBody),
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);

          if (imageUrl != null) {
            setState(() {
              _existingImageUrl = imageUrl;
              _imageFile = null;
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ??
                  'Parapharmacy information saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          final responseData = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(responseData['message'] ??
                    'Failed to save parapharmacy information.')),
          );
        }
      } catch (error) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('An error occurred: $error')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isFetching
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Parapharmacy Information',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Update your parapharmacy details',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 24),
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      shape: BoxShape.circle,
                                      image: _imageFile != null
                                          ? DecorationImage(
                                              image: FileImage(_imageFile!),
                                              fit: BoxFit.cover,
                                            )
                                          : (_existingImageUrl != null &&
                                                  _existingImageUrl!.isNotEmpty)
                                              ? DecorationImage(
                                                  image: NetworkImage(
                                                      'http://10.0.2.2:3000/' +
                                                          _existingImageUrl!),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                        width: 2,
                                      ),
                                    ),
                                    child: (_imageFile == null &&
                                            (_existingImageUrl == null ||
                                                _existingImageUrl!.isEmpty))
                                        ? Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.local_pharmacy,
                                                color: Colors.green,
                                                size: 50,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Tap to add logo',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          )
                                        : null,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  _imageFile != null ||
                                          (_existingImageUrl != null &&
                                              _existingImageUrl!.isNotEmpty)
                                      ? 'Tap to change logo'
                                      : 'Parapharmacy Logo',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 32),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Parapharmacy Name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              prefixIcon: Icon(Icons.business),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the parapharmacy name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a phone number';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              prefixIcon: Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an email address';
                              }
                              if (!value.contains('@') ||
                                  !value.contains('.')) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          TextFormField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              labelText: 'Address',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              prefixIcon: Icon(Icons.location_on),
                            ),
                            maxLines: 2,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the parapharmacy address';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 4,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a description';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
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
                                            _latitude != null &&
                                                    _longitude != null
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
                                      isParapharmacy: true,
                                      onLocationUpdated: _updateLocationDisplay,
                                      initialLatitude: _latitude,
                                      initialLongitude: _longitude,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveSettings,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                disabledBackgroundColor:
                                    Colors.green.withOpacity(0.6),
                              ),
                              child: _isLoading
                                  ? CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                      strokeWidth: 2,
                                    )
                                  : Text(
                                      'Save Information',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
