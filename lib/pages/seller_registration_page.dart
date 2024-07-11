import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:food_buddies/pages/ api_service.dart';
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
  late Razorpay _razorpay;
  int _selectedOption = 1; // Default to 1 month

  Map<int, int> _options = {
    1: 400,
    3: 900,
    6: 1200,
    12: 1800,
  };

  @override
  void initState() {
    super.initState();
    getPhoneNumber().then((value) {
      setState(() {
        _phoneController.text = value;
      });
    });
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
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
        membershipDuration: _selectedOption,
      );
      await storeCommunity(_selectedCommunity!);
    }
  }

  Future<String> getPhoneNumber() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('phoneNumber') ?? '';
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    Fluttertoast.showToast(msg: "Payment Success");
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Payment successful'),
    ));
    await registerSeller(); // Call registerSeller method on successful payment
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Fluttertoast.showToast(msg: "Payment Failed");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('External wallet selected')));
  }

  void _openCheckout() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCommunity == null) {
        Fluttertoast.showToast(msg: "Please select a community");
        return;
      }

      var options = {
        'key': 'rzp_test_d15RxnRWKBC4rm',
        'amount': _options[_selectedOption]! * 100, // amount in paise
        'name': 'Food Buddies',
        'description': 'Seller Membership',
        'prefill': {
          'contact': '8639133665',
          'email': 'ravivammi@gmail.com',
        }
      };

      try {
        _razorpay.open(options);
      } catch (e) {
        print(e.toString());
      }
    } else {
      Fluttertoast.showToast(msg: "Please fill all the fields");
    }
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
              Column(
                children: _options.keys.map((int months) {
                  return RadioListTile(
                    title: Text('$months month(s) - ₹${_options[months]}'),
                    value: months,
                    groupValue: _selectedOption,
                    onChanged: (int? value) {
                      setState(() {
                        _selectedOption = value!;
                      });
                    },
                  );
                }).toList(),
              ),
              ElevatedButton(
                onPressed: _openCheckout,
                child: Text('Proceed to checkout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
