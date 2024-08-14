import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import ' api_service.dart';
import 'renew_membership_page.dart';
import 'package:food_buddies/components/communityDropdown.dart';

class UpdateProfilePage extends StatefulWidget {
  @override
  _UpdateProfilePageState createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
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
      _addressController.text = profile['seller_address'];
      _upiController.text = profile['seller_upi'];
      _selectedCommunity = prefs.getString('community') ?? '';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
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
        title: Text('Update Profile'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_isMembershipExpired())
                Container(
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: Colors.red),
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => RenewMembershipPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          padding: EdgeInsets.symmetric(
                              vertical: 14.0, horizontal: 24.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        child: Text('Renew Now'),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 20),
              _buildTextField(
                controller: _nameController,
                label: 'Name',
                icon: Icons.person,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter your name';
                  return null;
                },
              ),
              _buildTextField(
                controller: _addressController,
                label: 'Address',
                icon: Icons.location_on,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter your address';
                  return null;
                },
              ),
              _buildTextField(
                controller: _upiController,
                label: 'UPI',
                icon: Icons.payment,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter your UPI ID';
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
              _buildDropdown(
                value: _selectedDeliveryType,
                items: ['HOME DELIVERY', 'PICK UP'],
                label: 'Delivery Type',
                icon: Icons.delivery_dining,
                onChanged: (newValue) {
                  setState(() {
                    _selectedDeliveryType = newValue;
                  });
                },
              ),
              SizedBox(height: 20),
              if (_membershipEndDate != null && !_isMembershipExpired())
                Text(
                  'Membership Active Till: ${DateFormat.yMMMd().format(_membershipEndDate!)}',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProfile,
                style: ElevatedButton.styleFrom(
                  padding:
                  EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  backgroundColor: Colors.orange,
                ),
                child: Text('Update Profile',
                    style: TextStyle(
                        fontSize: 18.0, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.orange),
          filled: true,
          fillColor: Colors.grey.shade200,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String label,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        items: items
            .map(
              (item) => DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          ),
        )
            .toList(),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.orange),
          filled: true,
          fillColor: Colors.grey.shade200,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
