import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_buddies/pages/ api_service.dart';
import 'package:food_buddies/components/communityDropdown.dart';
import 'login_otp_page.dart';

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

      await _loadProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(),
                SizedBox(height: 30),
                _buildTextField(
                  controller: _nameController,
                  labelText: 'Name',
                  icon: Icons.person,
                  validator: (value) {
                    if (value!.isEmpty) return 'Please enter your name';
                    return null;
                  },
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _phoneController,
                  labelText: 'Phone',
                  icon: Icons.phone,
                  enabled: false,
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _addressController,
                  labelText: 'Address',
                  icon: Icons.home,
                  validator: (value) {
                    if (value!.isEmpty) return 'Please enter your address';
                    return null;
                  },
                ),
                SizedBox(height: 20),
                _buildCommunityDropdown(),
                SizedBox(height: 30),
                _buildUpdateButton(),
                SizedBox(height: 20),
                _buildLogoutButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: AssetImage('assets/logo.png'),
        ),
        SizedBox(width: 20),
        Text(
          'Welcome,',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.black),
        prefixIcon: Icon(icon, color: Colors.orange),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.orange),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
      enabled: enabled,
    );
  }

  Widget _buildCommunityDropdown() {
    return CommunityDropdown(
      initialCommunity: _selectedCommunity,
      onChanged: (newValue) {
        setState(() {
          _selectedCommunity = newValue;
        });
      },
    );
  }

  Widget _buildUpdateButton() {
    return ElevatedButton(
      onPressed: _updateProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        padding: EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 5,
      ),
      child: Center(
        child: Text(
          'Update Profile',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton(
      onPressed: _logout,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        padding: EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 5,
      ),
      child: Center(
        child: Text(
          'Logout',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}
