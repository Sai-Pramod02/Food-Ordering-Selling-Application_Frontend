import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import ' api_service.dart';

class RenewMembershipPage extends StatefulWidget {
  @override
  _RenewMembershipPageState createState() => _RenewMembershipPageState();
}

class _RenewMembershipPageState extends State<RenewMembershipPage> {
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

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Update membership end date in backend
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String phone = prefs.getString('phoneNumber') ?? '';
    await APIService.renewMembership(phone, _selectedOption);

    // Show success message
    Fluttertoast.showToast(msg: "Payment Success");
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Membership renewed successfully'),
    ));
    Navigator.of(context).pop(); // Navigate back to the profile page
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Fluttertoast.showToast(msg: "Payment Failed");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('External wallet selected')));
  }

  void _openCheckout() async {
    var options = {
      'key': 'rzp_test_d15RxnRWKBC4rm',
      'amount': _options[_selectedOption]! * 100, // amount in paise
      'name': 'Food Buddies',
      'description': 'Membership Renewal',
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Renew Membership')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCheckout,
        child: Icon(Icons.payment),
      ),
    );
  }
}
