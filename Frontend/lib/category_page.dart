import 'package:flutter/material.dart';
import 'package:project/accountinfo.dart';
import 'package:project/cartpage.dart';
import 'package:project/home_screen.dart';
import 'package:project/test.dart';
import 'package:project/product_presentation.dart'; // For CleanserPage

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final List<Map<String, dynamic>> categories = [
    {
      'name': 'Cleansers',
      'image': 'assets/Cleansers.jpg', // Local image
      'items': '24 items',
      'description': 'Gentle and effective facial cleansers'
    },
    {
      'name': 'Moisturizers',
      'image': 'assets/Moisturizers.jpg', // Local image
      'items': '32 items',
      'description': 'Hydrating creams and lotions'
    },
    {
      'name': 'Eye creams',
      'image': 'assets/eyescreams.jpeg', // Local image
      'items': '18 items',
      'description': 'Targeted care for delicate eye area'
    },
    {
      'name': 'Sheet masks',
      'image': 'assets/Masks.webp', // Local image
      'items': '15 items',
      'description': 'Intensive treatment masks'
    },
    {
      'name': 'Serums',
      'image': 'assets/serums.webp', // Local image
      'items': '28 items',
      'description': 'Concentrated treatment solutions'
    },
    {
      'name': 'Sunscreens',
      'image': 'assets/sunscreen.webp', // Local image
      'items': '20 items',
      'description': 'UV protection for daily use'
    },
    {
      'name': 'parfumes',
      'image': 'assets/perfumes.webp', // Local image
      'items': '21 items',
      'description': 'UV protection for daily use'
    },
  ];

  int _selectedIndex = 0; // Default to the Home tab

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
    } else if (index == 0) {
      // Home
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: Colors.green[50],
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: primaryGreen,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Categories',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Color(0xFF43A047),
                      Color(0xFF2E7D32),
                    ],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          // Grid with padding
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.grey.shade100,
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            // Navigate to CleanserPage with selected category
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CleanserPage(
                                  category: categories[index]['name'],
                                  products: [],
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image section
                              Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image:
                                        AssetImage(categories[index]['image']),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              // Text section
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      categories[index]['name'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      categories[index]['items'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      categories[index]['description'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
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
                },
                childCount: categories.length,
              ),
            ),
          ),
        ],
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: primaryGreen,
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
}
