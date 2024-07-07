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
        });
        _showMembershipDialog();
      } else if (response.statusCode == 200) {
        // Additional check for confirmation (assuming a confirmation endpoint exists)
          print("Membership Confirmed - Active");
          setState(() {
            _isMembershipActive = true;
          });
      }
    } catch (e) {
      print('Error checking membership status: $e');
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false; // Disable the back button
      },
      child: Scaffold(
        body: Container(
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
            // sets the background color of the `BottomNavigationBar`
            canvasColor: Colors.grey[900],
            // sets the active color of the `BottomNavigationBar` if `Brightness` is light
            primaryColor: Colors.red,
            textTheme: Theme.of(context).textTheme.copyWith(
              bodySmall: TextStyle(color: Colors.white),
            ),
          ),
          child: BottomNavigationBar(
            onTap: onTabTapped,
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
          ),
        ),
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

