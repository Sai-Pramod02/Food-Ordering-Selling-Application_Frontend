// buyer_profile.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_buddies/pages/ api_service.dart';
import 'package:food_buddies/components/communityDropdown.dart';

class BuyerProfile extends StatefulWidget {
  @override
  _BuyerProfileState createState() => _BuyerProfileState();
}

class _BuyerProfileState extends State<BuyerProfile> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String? _selectedCommunity;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String phone = prefs.getString('phoneNumber') ?? '';

    final profile = await APIService.getBuyerProfile(phone);
    setState(() {
      _nameController.text = profile['buyer_name'];
      _phoneController.text = profile['buyer_phone'];
      _addressController.text = profile['buyer_address'];
      String community = prefs.getString('community') ?? '';
      _selectedCommunity = community;
    });
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String phone = prefs.getString('phoneNumber') ?? '';

      await APIService.updateBuyerProfile(
        phone: phone,
        name: _nameController.text,
        address: _addressController.text,
        community: _selectedCommunity!,
      );
      await prefs.setString('community', _selectedCommunity!);

      // Reload the profile to ensure the UI reflects the latest data
      await _loadProfile();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Buyer Profile')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
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
              CommunityDropdown(
                initialCommunity: _selectedCommunity,
                onChanged: (newValue) {
                  setState(() {
                    _selectedCommunity = newValue;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProfile,
                child: Text('Update Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
