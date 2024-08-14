import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:food_buddies/pages/ api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CancelOrderPage extends StatefulWidget {
  final int orderId;
  final double orderTotalPrice;
  final List<Map<String, dynamic>> orderItems;
  CancelOrderPage({required this.orderId, required this.orderTotalPrice, required this.orderItems});

  @override
  _CancelOrderPageState createState() => _CancelOrderPageState();
}

class _CancelOrderPageState extends State<CancelOrderPage> {
  Razorpay _razorpay = Razorpay();
  double _cancellationFee = 0.0;
  String _playerId = '';

  @override
  void initState() {
    super.initState();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _calculateCancellationFee();
  }

  Future<void> sendNotificationToDevice(String playerId, String message) async {
    final url = Uri.parse('https://onesignal.com/api/v1/notifications');
    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Basic YOUR_API_KEY', // Replace with your OneSignal API key
    };

    final body = jsonEncode({
      'app_id': 'e970f590-077b-44bf-9fad-a5f9571be7f5', // Replace with your OneSignal App ID
      'contents': {'en': message},
      'include_player_ids': [playerId],
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      throw Exception('Failed to send notification');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final APIService apiService = APIService();
    try {
      if (_playerId.isNotEmpty) {
        await sendNotificationToDevice(_playerId, 'Your order has been cancelled by the seller.');

        // Show dialog to remind the user to update the available quantity
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Update Available Quantity"),
              content: Text("Please ensure that you update the available quantity of the cancelled items."),
              actions: [
                TextButton(
                  child: Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pop(context, true); // Return to the previous page with success status
                  },
                ),
              ],
            );
          },
        );
      } else {
        print("Missing playerId data");
      }
    } catch (e) {
      print("Error handling payment success: $e");
    }
  }


  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}')),
    );
  }

  void _calculateCancellationFee() {
    setState(() {
      _cancellationFee = widget.orderTotalPrice * 0.05;
    });
  }

  Future<void> _cancelOrderAndOpenCheckout() async {
    try {
      final apiService = APIService();
      final cancelRes = await APIService.cancelOrder(context, widget.orderId);
      final Map<String, dynamic> cancelResponseBody = jsonDecode(cancelRes.body);

      if (cancelRes.statusCode == 200) {
        _playerId = cancelResponseBody['player_id'];

        var options = {
          'key': 'rzp_test_d15RxnRWKBC4rm',
          'amount': (_cancellationFee * 100).toInt(), // amount in paise
          'name': 'Food Buddies',
          'description': 'Order Cancellation Fee',
          'prefill': {
            'contact': '8639133665',
            'email': 'ravivammi@gmail.com',
          }
        };

        _razorpay.open(options);
      } else {
        print("Cancellation failed");
      }
    } catch (e) {
      print("Error opening Razorpay: $e");
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cancel Order')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.orderItems.length,
              itemBuilder: (context, index) {
                final item = widget.orderItems[index];
                return ListTile(
                  title: Text(item['item_name']),
                  subtitle: Text('Price: ₹${item['item_price']} Quantity: ${item['item_quantity']}'),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('Total Cancellation Fee: ₹$_cancellationFee', style: TextStyle(fontSize: 18)),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _cancelOrderAndOpenCheckout,
                  child: Text('Proceed to Payment'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
