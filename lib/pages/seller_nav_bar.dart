import 'package:flutter/material.dart';
import 'package:food_buddies/pages/home_page.dart';
import 'package:food_buddies/pages/seller_profile_page.dart';
import 'package:http/http.dart' as http;

import '../pages/renew_membership_page.dart';
import '../pages/manage_items.dart';
import '../pages/manage_orders_page.dart';
import 'package:food_buddies/components/membership_dialougeBox.dart'; // Import the membership dialog
import 'package:food_buddies/pages/ api_service.dart'; // Corrected import path

class SellerHomePage extends StatefulWidget {
  @override
  _SellerHomePageState createState() => _SellerHomePageState();
}

class _SellerHomePageState extends State<SellerHomePage> {
  int _currentIndex = 0;
  bool _isMembershipActive = true; // State variable to track membership status
  bool _isLoading = true; // State variable to track loading status
  bool _hasError = false; // State variable to track error status

  final List<Widget> _children = [
    ManageItemsPage(), // ManageItems page (conditionally displayed)
    SellerProfile(), // Profile page
    HomePage(), // Home page
    ManageOrdersPage(), // ManageOrders page (conditionally displayed)
  ];

  @override
  void initState() {
    super.initState();
    _checkMembershipStatus(); // Check membership status when the page is initialized
  }

  void _checkMembershipStatus() async {
    final phone = await APIService.getPhoneNumber();
    try {
      final response = await http.get(Uri.parse('http://34.16.177.102:4000/sellers/membershipStatus?phone=$phone')); // Corrected URL
      if (response.statusCode == 403) {
        // Membership expired, show dialog and update state
        setState(() {
          _isMembershipActive = false;
          _isLoading = false;
        });
        _showMembershipDialog();
      } else if (response.statusCode == 200) {
        // Membership active, update state
        setState(() {
          _isMembershipActive = true;
          _isLoading = false;
        });
      } else {
        // Handle unexpected status codes
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking membership status: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void onTabTapped(int index) {
    _checkMembershipStatus(); // Check membership status when a new tab is selected
    setState(() {
      _currentIndex = index;
    });
  }

  void _showMembershipDialog() {
    showDialog(
      context: context,
      builder: (context) => MembershipDialog(),
    );
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _checkMembershipStatus();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false; // Disable the back button
      },
      child: Scaffold(
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _hasError
            ? _buildErrorContent()
            : Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Colors.blue, Colors.red],
            ),
          ),
          child: _getCurrentPage(_currentIndex),
        ),
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            canvasColor: Colors.grey[900],
            primaryColor: Colors.red,
            textTheme: Theme.of(context).textTheme.copyWith(
              bodySmall: TextStyle(color: Colors.white),
            ),
          ),
          child: BottomNavigationBar(
            onTap: onTabTapped,
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.list),
                label: 'Manage Items',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart),
                label: 'Manage Orders',
              ),
            ],
            selectedItemColor: Colors.orange,
            unselectedItemColor: Colors.white,
            backgroundColor: Colors.grey[900],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 50, color: Colors.red),
          Text(
            'There is some issue with the connection.\nPlease wait for a while and try again.',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _retry,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _getCurrentPage(int index) {
    if (!_isMembershipActive && (index == 0 || index == 3)) {
      return LockedContent(); // Show locked content if membership is not active
    }
    return _children[index];
  }
}

class PlaceholderWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Page under construction'),
    );
  }
}

class LockedContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 50),
          Text('This content is locked. Please renew your membership.'),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RenewMembershipPage()),
              );
            },
            child: Text('Renew'),
          ),
        ],
      ),
    );
  }
}
