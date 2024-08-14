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
  final TextEditingController _fssaiController = TextEditingController();
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

  Future<void> _pickImage() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      if (await Permission.photos.request().isGranted) {
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
        setState(() {
          if (pickedFile != null) {
            _image = File(pickedFile.path);
          } else {
            print('No image selected.');
          }
        });
      } else {
        print('Images permission denied');
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
        sellerFssai: _fssaiController.text,
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
          title: Text('Seller Registration', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.orange,
          elevation: 0,
        ),
        body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
    child: Form(
    key: _formKey,
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
    Text("Register as a Seller",
    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.deepOrangeAccent)),
    SizedBox(height: 20),
    TextFormField(
    controller: _nameController,
    decoration: InputDecoration(
    labelText: 'Seller Name',
    border: OutlineInputBorder(),
    prefixIcon: Icon(Icons.person),
    ),
    validator: (value) {
    if (value!.isEmpty) {
    return 'Please enter a name';
    }
    return null;
    },
    ),
    SizedBox(height: 20),
    TextFormField(
    controller: _phoneController,
    decoration: InputDecoration(
    labelText: 'Seller Phone',
    border: OutlineInputBorder(),
    prefixIcon: Icon(Icons.phone),
    ),
    validator: (value) {
    if (value!.isEmpty) {
    return 'Please enter a phone number';
    }
    return null;
    },
    enabled: false,
    ),
    SizedBox(height: 20),
    TextFormField(
    controller: _addressController,
    decoration: InputDecoration(
    labelText: 'Seller Address',
    border: OutlineInputBorder(),
    prefixIcon: Icon(Icons.location_on),
    ),
    validator: (value) {
    if (value!.isEmpty) {
    return 'Please enter an address';
    }
    return null;
    },
    ),
    SizedBox(height: 20),
    TextFormField(
    controller: _upiController,
    decoration: InputDecoration(
    labelText: 'Seller UPI',
    border: OutlineInputBorder(),
    prefixIcon: Icon(Icons.account_balance_wallet),
    ),
    validator: (value) {
    if (value!.isEmpty) {
    return 'Please enter a UPI ID';
    }
    return null;
    },
    ),
    SizedBox(height: 20),
    TextFormField(
    controller: _fssaiController,
    decoration: InputDecoration(
    labelText: 'FSSAI Code',
    border: OutlineInputBorder(),
    prefixIcon: Icon(Icons.qr_code),
    ),
    validator: (value) {
    if (value!.isEmpty) {
    return 'Please enter an FSSAI code';
    }
    return null;
    },
    ),
    SizedBox(height: 20),
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
    ? Text('No image selected.', style: TextStyle(color: Colors.red))
        : Image.file(_image!),
    SizedBox(height: 10),
    ElevatedButton.icon(
    onPressed: _pickImage,
    icon: Icon(Icons.camera_alt),
    label: Text('Pick Image'),
    style: ElevatedButton.styleFrom(
    foregroundColor: Colors.black, backgroundColor: Colors.yellow,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10),
    ),
    ),
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
    decoration: InputDecoration(
      labelText: 'Delivery Type',
      border: OutlineInputBorder(),
      prefixIcon: Icon(Icons.delivery_dining),
    ),
    ),
      SizedBox(height: 20),
      Text("Membership Duration",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ListTile(
        title: Text('1 Month (₹400)'),
        leading: Radio<int>(
          value: 1,
          groupValue: _selectedOption,
          onChanged: (int? value) {
            setState(() {
              _selectedOption = value!;
            });
          },
        ),
      ),
      ListTile(
        title: Text('3 Months (₹900)'),
        leading: Radio<int>(
          value: 3,
          groupValue: _selectedOption,
          onChanged: (int? value) {
            setState(() {
              _selectedOption = value!;
            });
          },
        ),
      ),
      ListTile(
        title: Text('6 Months (₹1200)'),
        leading: Radio<int>(
          value: 6,
          groupValue: _selectedOption,
          onChanged: (int? value) {
            setState(() {
              _selectedOption = value!;
            });
          },
        ),
      ),
      ListTile(
        title: Text('12 Months (₹1800)'),
        leading: Radio<int>(
          value: 12,
          groupValue: _selectedOption,
          onChanged: (int? value) {
            setState(() {
              _selectedOption = value!;
            });
          },
        ),
      ),
      SizedBox(height: 20),
      ElevatedButton(
        onPressed: _openCheckout,
        child: Text('Proceed to Payment'),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, backgroundColor: Colors.orange,
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
          textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    ],
    ),
    ),
        ),
    );
  }
}
