import 'dart:async';
import 'package:flutter/material.dart';
import 'package:project/accountinfo.dart'; // Ensure this import is correct
import 'package:project/cartpage.dart';
import 'package:project/category_page.dart';
import 'package:project/chat_screen.dart'; // Ensure this import is correct
import 'package:project/login_page.dart';
import 'package:project/parapharmacy_page.dart';
import 'package:project/product_presentation.dart';
import 'package:project/screens/admin_layout.dart';
import 'package:project/search_page.dart';
import 'package:project/test.dart'; // Ensure this import is correct
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Home tab
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Future<bool> signOutUser() async {
    final url = Uri.parse('http://10.0.2.2:3000/auth/signout');
    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        print('Sign out successful: ${response.body}');
        return true;
      } else {
        print('Sign out failed: ${response.body}');
        return false;
      }
    } catch (error) {
      print('Error signing out: $error');
      return false;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 3) {
      // Profile
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage()),
      );
    } else if (index == 2) {
      // Wishlist
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WishlistScreen()),
      );
    } else if (index == 1) {
      // Cart
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CartPage()),
      );
    }
  }

  void _onLogoClicked() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: _onLogoClicked,
          child: Image.asset('assets/—Pngtree—women nature logo_7598961.png'),
        ),
        title: Text(
          'Derma Tracker',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchPage()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Dermatrack',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your Skincare Companion',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.favorite),
              title: Text('Favorites'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WishlistScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.chat),
              title: Text('DearmAI'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text('Manage Account'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => AdminLayout()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () async {
                bool result = await signOutUser();
                if (result) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout successful!'),
                      backgroundColor: Colors.black,
                    ),
                  );
                  // Navigate to the login page after successful logout.
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logout failed. Please try again.')),
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Promotion Banner with carousel background
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 200,
                    margin: EdgeInsets.all(16),
                    // Remove the decoration image so that we can use a carousel in the stack
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.green, width: 1),
                    ),
                    child: Stack(
                      children: [
                        // The promotion carousel as background
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: PromotionCarousel(
                            imagePaths: [
                              'assets/website_landscapeArtboard_1_copy_2.webp',
                              'assets/promotion2.jpg', // Add more images as needed
                              'assets/promotion3.jpeg',
                            ],
                            interval: Duration(seconds: 5),
                            animationDuration: Duration(milliseconds: 500),
                          ),
                        ),
                        // Overlay gradient
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.black.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        // Positioned promotional text and deal tag
                        Positioned(
                          left: 20,
                          top: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'DEAL 50% OFF',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'HERE WE GO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 1),
                                      blurRadius: 3,
                                      color: Colors.black.withOpacity(0.3),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Categories section
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Our categories',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => CategoryPage()),
                            );
                          },
                          child: Text(
                            'see all',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        GestureDetector(
                          onTap: () {
                            // Handle the press action for Cleansers
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => CleanserPage(
                                          category: 'cleanser',
                                          products: [
                                            {
                                              'name': 'Biossance eye cream',
                                              'description':
                                                  'Squalane + Marine Algae Eye Cream',
                                              'price': 74,
                                              'rating': 4.5,
                                              'reviews': 128,
                                              'image':
                                                  'https://v0.dev/placeholder.svg',
                                              'isFavorite': false
                                            },
                                          ])),
                            );
                            print('Cleansers pressed');
                          },
                          child: _buildCategoryItem(
                              'assets/Cleansers.jpg', 'Cleansers'),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => CleanserPage(
                                        category: 'Moisturizers',
                                        products: [],
                                      )),
                            );
                            // Handle the press action for Moisturizers
                            print('Moisturizers pressed');
                          },
                          child: _buildCategoryItem(
                              'assets/Moisturizers.jpg', 'Moisturizers'),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => CleanserPage(
                                        category: 'Eye Creams',
                                        products: [],
                                      )),
                            );
                            // Handle the press action for Eye Creams
                            print('Eye Creams pressed');
                          },
                          child: _buildCategoryItem(
                              'assets/eyescreams.jpeg', 'Eye Creams'),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => CleanserPage(
                                        category: 'Masks',
                                        products: [],
                                      )),
                            );
                            // Handle the press action for Masks
                            print('Masks pressed');
                          },
                          child:
                              _buildCategoryItem('assets/Masks.webp', 'Masks'),
                        ),
                      ],
                    ),
                  ),
                  // Best sellers title
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Best sellers',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Best sellers grid
            SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.80,
                mainAxisSpacing: 16,
                crossAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildProductCard(
                    context,
                    index == 0
                        ? 'Skessence\neye cream'
                        : 'The Ordinary\nface mask',
                    index == 0 ? '\$74' : '\$50',
                    index == 0
                        ? 'assets/bestsales1.png'
                        : 'assets/bestsales2.png',
                  );
                },
                childCount: 2,
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),
          ],
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

  Widget _buildCategoryItem(String imagePath, String title) {
    return Padding(
      padding: EdgeInsets.only(right: 20),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green, width: 2),
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white,
              backgroundImage: AssetImage(imagePath),
            ),
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
      BuildContext context, String title, String price, String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.asset(
              imageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 150,
                  color: Colors.grey[200],
                  child: Icon(Icons.error, color: Colors.grey),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

///
/// PromotionCarousel Widget
///
class PromotionCarousel extends StatefulWidget {
  final List<String> imagePaths;
  final Duration interval;
  final Duration animationDuration;

  const PromotionCarousel({
    super.key,
    required this.imagePaths,
    this.interval = const Duration(seconds: 5),
    this.animationDuration = const Duration(milliseconds: 500),
  });

  @override
  _PromotionCarouselState createState() => _PromotionCarouselState();
}

class _PromotionCarouselState extends State<PromotionCarousel> {
  late final PageController _pageController;
  late Timer _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: _currentPage);

    _timer = Timer.periodic(widget.interval, (Timer timer) {
      if (mounted) {
        _currentPage = (_currentPage + 1) % widget.imagePaths.length;
        _pageController.animateToPage(
          _currentPage,
          duration: widget.animationDuration,
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.imagePaths.length,
      itemBuilder: (context, index) {
        return Image.asset(
          widget.imagePaths[index],
          fit: BoxFit.cover,
        );
      },
    );
  }
}
