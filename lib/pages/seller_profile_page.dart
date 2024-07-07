import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import ' api_service.dart';
import 'package:food_buddies/components/communityDropdown.dart';
import 'past_orders_page.dart';
import 'renew_membership_page.dart'; // Import the renew membership page
import 'package:intl/intl.dart'; // For date formatting
import 'login_otp_page.dart'; // Import the login page

class SellerProfile extends StatefulWidget {
  @override
  _SellerProfileState createState() => _SellerProfileState();
}

class _SellerProfileState extends State<SellerProfile> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _upiController = TextEditingController();
  String? _selectedCommunity;
  String? _selectedDeliveryType;
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
      _nameController.text = profile['seller_name'];
      _phoneController.text = profile['seller_phone'];
      _addressController.text = profile['seller_address'];
      _upiController.text = profile['seller_upi'];
      String community = prefs.getString('community') ?? '';
      _selectedCommunity = community;
      print("Selected community : "+ _selectedCommunity!);
      _selectedDeliveryType = profile['delivery_type'];
      _membershipEndDate = DateTime.parse(profile['membership_end_date']);
    });
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String phone = prefs.getString('phoneNumber') ?? '';
      await APIService.updateSellerProfile(
        phone: phone,
        name: _nameController.text,
        address: _addressController.text,
        upi: _upiController.text,
        community: _selectedCommunity!,
        deliveryType: _selectedDeliveryType!,
      );
      await prefs.setString('community', _selectedCommunity!);
      await _loadProfile();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
    }
  }

  Future<void> _logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('phoneNumber');
    await prefs.remove('community');
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
      appBar: AppBar(title: Text('Seller Profile')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_isMembershipExpired())
                Container(
                  padding: EdgeInsets.all(16.0),
                  margin: EdgeInsets.only(bottom: 20.0), // Add margin for better spacing
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
                          foregroundColor: Colors.white, backgroundColor: Colors.pink.shade300,
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
                ),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter your name';
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Phone'),
                enabled: false,
              ),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Address'),
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter your address';
                  return null;
                },
              ),
              TextFormField(
                controller: _upiController,
                decoration: InputDecoration(labelText: 'UPI'),
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter your UPI';
                  return null;
                },
              ),
              CommunityDropdown(
                initialCommunity: _selectedCommunity,
                onChanged: (newValue) {
                  setState(() {
                    _selectedCommunity = newValue;
                  });
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedDeliveryType,
                items: ['HOME DELIVERY', 'PICK UP'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedDeliveryType = newValue;
                  });
                },
                decoration: InputDecoration(labelText: 'Delivery Type'),
              ),
              SizedBox(height: 20),
              if (_membershipEndDate != null && !_isMembershipExpired())
                Text('Membership Active Till: ${_formatDate(_membershipEndDate!)}'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProfile,
                child: Text('Update Profile'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                  textStyle: TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
                onPressed: () async {
                  final SharedPreferences prefs = await SharedPreferences.getInstance();
                  String phoneNumber = prefs.getString('phoneNumber') ?? '';
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PastOrdersPage(buyerPhone: phoneNumber)),
                  );
                },
                child: Text('Your Orders'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                  textStyle: TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RenewMembershipPage()),
                  );
                },
                child: Text('Renew Membership'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                  textStyle: TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
                onPressed: _logout,
                child: Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
