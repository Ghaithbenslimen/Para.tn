import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isExpanded;

  const AdminSidebar({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isExpanded,
  }) : super(key: key);

  Future<void> _signOut(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final url = Uri.parse('http://10.0.2.2:3000/auth/signout');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        await prefs.remove('token');
        // Navigate directly to the LoginPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(height: 20),
          // Header: shows logo and text
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green[100],
                  child: Icon(Icons.local_pharmacy, color: Colors.green),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Green Pharmacy',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Admin Panel',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 30),
          // Navigation items
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildNavItem(
                    0, Icons.dashboard_outlined, 'Dashboard', context),
                _buildNavItem(
                    1, Icons.add_box_outlined, 'Add Product', context),
                _buildNavItem(
                    2, Icons.inventory_2_outlined, 'Inventory', context),
                _buildNavItem(
                    3, Icons.bar_chart_outlined, 'Statistics', context),
                _buildNavItem(4, Icons.people_outline, 'Customers', context),
                _buildNavItem(
                    5, Icons.shopping_bag_outlined, 'Orders', context),
                _buildNavItem(6, Icons.notifications_active_outlined,
                    'Notifications', context), // Add notifications item
                _buildNavItem(7, Icons.settings_outlined, 'Settings', context),
              ],
            ),
          ),
          Divider(),
          // Logout
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text(
              'Logout',
              overflow: TextOverflow.ellipsis,
            ),
            minLeadingWidth: 0,
            onTap: () => _signOut(context),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData icon, String title, BuildContext context) {
    final isSelected = selectedIndex == index;
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(
        icon,
        color: isSelected ? Colors.green : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.green : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      minLeadingWidth: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      tileColor: isSelected ? Colors.green.withOpacity(0.1) : null,
      onTap: () => onItemSelected(index),
      selected: isSelected,
      selectedTileColor: Colors.green.withOpacity(0.1),
      hoverColor: Colors.green.withOpacity(0.05),
    );
  }
}
