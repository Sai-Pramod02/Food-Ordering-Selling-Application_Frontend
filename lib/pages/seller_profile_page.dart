import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import ' api_service.dart';
import 'past_orders_page.dart';
import 'renew_membership_page.dart';
import 'login_otp_page.dart';
import 'updateProfile_page.dart';

class SellerProfile extends StatefulWidget {
  @override
  _SellerProfileState createState() => _SellerProfileState();
}

class _SellerProfileState extends State<SellerProfile> {
  DateTime? _membershipEndDate;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String phone = prefs.getString('phoneNumber') ?? '';
    final profile = await APIService.getSellerProfile(phone);
    setState(() {
      _membershipEndDate = DateTime.parse(profile['membership_end_date']);
    });
  }

  Future<void> _logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();  // Clear all stored preferences
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => loginOTPPage()),
          (route) => false,
    );
  }

  String _formatDate(DateTime date) {
    final day = DateFormat('d').format(date);
    final suffix = _getDayOfMonthSuffix(int.parse(day));
    final formattedDate = DateFormat('d MMM yyyy').format(date);
    return formattedDate.replaceFirst(RegExp(r'\d+'), '$day$suffix');
  }

  String _getDayOfMonthSuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  bool _isMembershipExpired() {
    if (_membershipEndDate == null) return false;
    return _membershipEndDate!.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seller Profile'),
        centerTitle: true,
        backgroundColor: Colors.deepOrangeAccent,
        elevation: 0,
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildHeaderSection(),
            SizedBox(height: 20),
            if (_isMembershipExpired()) _buildMembershipExpiredBanner(),
            if (_membershipEndDate != null && !_isMembershipExpired())
              Center(
                child: Text(
                  'Membership Active Till: ${_formatDate(_membershipEndDate!)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            SizedBox(height: 20),
            _buildMenuButton('Update Profile', Icons.edit, Colors.blue, UpdateProfilePage()),
            _buildMenuButton('Your Orders', Icons.shopping_cart, Colors.green, PastOrdersPage()),
            _buildMenuButton('Renew Membership', Icons.card_membership, Colors.orange, RenewMembershipPage()),
            _buildMenuButton('Logout', Icons.logout, Colors.red, null, _logout),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage('assets/logo.png'), // Seller's logo
          ),
          SizedBox(height: 10),
          Text(
            'Welcome, Seller',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 5),
        ],
      ),
    );
  }

  Widget _buildMembershipExpiredBanner() {
    return Container(
      padding: EdgeInsets.all(16.0),
      margin: EdgeInsets.only(bottom: 20.0),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your membership has expired. Please renew it to continue as a seller.',
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.pink.shade300,
              textStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RenewMembershipPage()),
              );
            },
            child: Text('Renew Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(String title, IconData icon, Color color, Widget? page, [VoidCallback? onTap]) {
    return Container(
      margin: EdgeInsets.only(bottom: 15.0),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: color,
          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        icon: Icon(icon, size: 24),
        label: Text(title),
        onPressed: onTap ?? () {
          if (page != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            );
          }
        },
      ),
    );
  }
}
