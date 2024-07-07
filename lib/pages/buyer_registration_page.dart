import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_buddies/pages/ api_service.dart';
import 'package:food_buddies/components/communityDropdown.dart';

class BuyerRegistration extends StatefulWidget {
  @override
  _BuyerRegistrationState createState() => _BuyerRegistrationState();
}

class _BuyerRegistrationState extends State<BuyerRegistration> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String? _selectedCommunity;

  @override
  void initState() {
    super.initState();
    getPhoneNumber().then((value) => _phoneController.text = value);
  }

  Future<void> storeCommunity(String community) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('community', community);
  }

  Future<void> registerBuyer() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCommunity == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a community')),
        );
        return;
      }
      await APIService.registerBuyer(
        context: context,
        buyerName: _nameController.text,
        buyerPhone: _phoneController.text,
        buyerAddress: _addressController.text,
        community: _selectedCommunity!,
      );
      await storeCommunity(_selectedCommunity!);  // Store community after successful registration
    }
  }

  Future<String> getPhoneNumber() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('phoneNumber') ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buyer Registration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Buyer Name'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Buyer Phone'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
                enabled: false,
              ),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Buyer Address'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter an address';
                  }
                  return null;
                },
              ),
              CommunityDropdown(
                onChanged: (newValue) {
                  setState(() {
                    _selectedCommunity = newValue;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: registerBuyer,
                child: Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
