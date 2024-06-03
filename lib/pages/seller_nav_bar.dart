import 'package:flutter/material.dart';
import 'package:food_buddies/pages/buyer_nav_bar.dart';
import 'package:food_buddies/pages/home_page.dart';
import 'package:food_buddies/pages/manage_items.dart';
import 'package:food_buddies/pages/manage_orders_page.dart';
import 'package:food_buddies/pages/seller_profile_page.dart';


class SellerHomePage extends StatefulWidget {
  @override
  _SellerHomePageState createState() => _SellerHomePageState();
}

class _SellerHomePageState extends State<SellerHomePage> {
  int _currentIndex = 0;
  final List<Widget> _children = [
    ManageItemsPage(), // Placeholder for ManageItems page
    SellerProfile(), // Placeholder for Profile page
    HomePage(), // Home page
    ManageOrdersPage(), // Placeholder for ManageOrders page
  ];

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.blue, Colors.red],
          ),
        ),
        child: _children[_currentIndex],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          // sets the background color of the `BottomNavigationBar`
          canvasColor: Colors.grey[900],
          // sets the active color of the `BottomNavigationBar` if `Brightness` is light
          primaryColor: Colors.red,
          textTheme: Theme
              .of(context)
              .textTheme
              .copyWith(
            caption: TextStyle(color: Colors.white),
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
    );
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
