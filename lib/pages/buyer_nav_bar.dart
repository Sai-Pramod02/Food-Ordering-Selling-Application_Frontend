import 'package:flutter/material.dart';
import 'package:food_buddies/pages/buyer_profile_page.dart';
import 'package:food_buddies/pages/home_page.dart';
import 'package:food_buddies/pages/past_orders_page.dart';
import 'package:food_buddies/pages/seller_registration_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BuyerHomePage extends StatefulWidget {
  @override
  _BuyerHomePageState createState() => _BuyerHomePageState();
}

class _BuyerHomePageState extends State<BuyerHomePage> {
  int _currentIndex = 0;
  String? phoneNumber;
  late List<Widget> _children;

  @override
  void initState() {
    super.initState();
    _loadPhoneNumber();
  }

  Future<void> _loadPhoneNumber() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      phoneNumber = prefs.getString('phoneNumber') ?? '';
      _children = [
        HomePage(), // Placeholder for Home page
        BuyerProfile(), // Placeholder for Profile page
        PastOrdersPage(buyerPhone: phoneNumber!), // Placeholder for Past Orders page
        SellerRegistration(), // Seller registration page
      ];
    });
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: phoneNumber == null
          ? Center(child: CircularProgressIndicator())
          : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.blue, Colors.red],
          ),
        ),
        child: _children[_currentIndex],
      ),
      bottomNavigationBar: phoneNumber == null
          ? SizedBox()
          : Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.grey[900],
          primaryColor: Colors.red,
          textTheme: Theme.of(context).textTheme.copyWith(
            caption: TextStyle(color: Colors.white),
          ),
        ),
        child: BottomNavigationBar(
          onTap: onTabTapped,
          currentIndex: _currentIndex,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'Past Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.store),
              label: 'Become a Seller',
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
