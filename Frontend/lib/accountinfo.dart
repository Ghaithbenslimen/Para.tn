import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/cartpage.dart';
import 'package:project/edit_profile_page.dart';
import 'package:project/home_screen.dart';
import 'package:project/parapharmacy_page.dart';
import 'package:project/payment_method.dart';
import 'package:project/test.dart'; // Import the WishlistScreen
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 3; // Profile tab
  bool _isLoading = true;
  String _fullName = '';
  String _email = '';
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  // Function to fetch profile data from the backend
  Future<void> _fetchProfileData() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No Token Found. Please Log In Again')),
      );
      setState(() {
        _isLoading = false;
        _fullName = 'Guest User';
        _email = '';
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

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final profileData = jsonDecode(response.body);
          setState(() {
            _fullName = profileData['fullName'] ?? 'User';
            _email = profileData['email'] ?? '';

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
            _fullName = 'User';
            _email = '';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _fullName = 'User';
          _email = '';
        });
      }
    } catch (error) {
      print('Error fetching profile data: $error');
      setState(() {
        _isLoading = false;
        _fullName = 'User';
        _email = '';
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WishlistScreen()),
      );
    } else if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ParapharmacyPage()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CartPage()),
      );
    }
  }

  // Function to handle logout
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    // Navigate to login or home page after logout
    // You can replace this with your actual login page
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => ParapharmacyPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: const Text(
          'Profile Info',
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
          ? Center(child: CircularProgressIndicator(color: Colors.green))
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _fetchProfileData,
                color: Colors.green,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Custom Avatar Frame
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
                          // Profile Image
                          _profileImageUrl != null
                              ? CircleAvatar(
                                  radius: 50,
                                  backgroundImage:
                                      NetworkImage(_profileImageUrl!),
                                  onBackgroundImageError:
                                      (exception, stackTrace) {
                                    print(
                                        'Error loading profile image: $exception');
                                  },
                                )
                              : CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.grey[200],
                                  child: Icon(Icons.person,
                                      size: 50, color: Colors.grey),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        _fullName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        _email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildMenuItem(
                      'Personal Information',
                      Icons.person_outline,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfilePage(),
                          ),
                        ).then((_) {
                          // Refresh profile data when returning from edit page
                          _fetchProfileData();
                        });
                      },
                    ),
                    _buildMenuItem('Contact Us', Icons.headset_mic_outlined,
                        onTap: () {}),
                    _buildMenuItem('Payment Method', Icons.payment_outlined,
                        onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PaymentMethodPage()));
                    }),
                    _buildMenuItem('Log Out', Icons.logout_outlined,
                        onTap: _logout),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            label: 'Wishlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.black87),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        trailing:
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
        onTap: onTap,
      ),
    );
  }
}
