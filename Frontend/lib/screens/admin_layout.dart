import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/screens/notifications_page.dart';

import '../widgets/admin_sidebar.dart';
import 'dashboard_page.dart';
import 'add_product_page.dart';
import 'inventory_page.dart';
import 'statistics_page.dart';
import 'customers_page.dart';
import 'admin_orders_page.dart';
import 'settings_page.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({Key? key}) : super(key: key);

  @override
  _AdminLayoutState createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;
  bool _isExpanded = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        title: Text(
          'Parapharmacy Dashboard',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Stack(
        children: [
          // Main content - always takes full width
          Container(
            width: double.infinity,
            height: double.infinity,
            child: _buildContent(),
          ),

          // Sidebar - overlays on top when expanded
          if (_isExpanded)
            AdminSidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              isExpanded: _isExpanded,
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return DashboardPage();
      case 1:
        return AddProductPage();
      case 2:
        return InventoryPage();
      case 3:
        return StatisticsPage();
      case 4:
        return CustomersPage();
      case 5:
        return AdminOrdersPage();
      case 6:
        return NotificationsPage(); // Add the new notifications page
      case 7:
        return SettingsPage();
      default:
        return DashboardPage();
    }
  }
}
