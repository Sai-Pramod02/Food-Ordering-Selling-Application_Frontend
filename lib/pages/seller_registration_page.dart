// seller_registration.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:food_buddies/pages/ api_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_buddies/components/communityDropdown.dart';

class SellerRegistration extends StatefulWidget {
  @override
  _SellerRegistrationState createState() => _SellerRegistrationState();
}

class _SellerRegistrationState extends State<SellerRegistration> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _upiController = TextEditingController();
  File? _image;
  String? _selectedCommunity;
  String _deliveryType = 'HOME DELIVERY';
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    getPhoneNumber().then((value) => _phoneController.text = value);
  }

  Future<void> pickImage() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      if (await Permission.storage.request().isGranted) {
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
        setState(() {
          if (pickedFile != null) {
            _image = File(pickedFile.path);
          } else {
            print('No image selected.');
          }
        });
      } else {
        print('Storage permission denied');
      }
    } else {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      setState(() {
        if (pickedFile != null) {
          _image = File(pickedFile.path);
        } else {
          print('No image selected.');
        }
      });
    }
  }

  Future<void> storeCommunity(String community) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('community', community);
  }

  Future<void> registerSeller() async {
    print(_deliveryType);
    if (_formKey.currentState!.validate()) {
      await APIService.registerSeller(
        context: context,
        sellerName: _nameController.text,
        sellerPhone: _phoneController.text,
        sellerAddress: _addressController.text,
        sellerUpi: _upiController.text,
        image: _image,
        community: _selectedCommunity!,
        deliveryType: _deliveryType,

      );
      await storeCommunity(_selectedCommunity!);
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
        title: Text('Seller Registration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Seller Name'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Seller Phone'),
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
                decoration: InputDecoration(labelText: 'Seller Address'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter an address';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _upiController,
                decoration: InputDecoration(labelText: 'Seller UPI'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a UPI ID';
                  }
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
              _image == null
                  ? Text('No image selected.')
                  : Image.file(_image!),
              ElevatedButton(
                onPressed: pickImage,
                child: Text('Pick Image'),
              ),
              SizedBox(height: 20),
              DropdownButtonFormField(
                value: _deliveryType,
                items: ['HOME DELIVERY', 'PICK UP'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _deliveryType = newValue!;
                  });
                },
                decoration: InputDecoration(labelText: 'Delivery Type'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: registerSeller,
                child: Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
