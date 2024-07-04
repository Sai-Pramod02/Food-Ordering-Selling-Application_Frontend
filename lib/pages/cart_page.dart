import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_buddies/models/cart_model.dart';
import 'package:food_buddies/pages/ api_service.dart';
import 'package:food_buddies/components/quantity_selector.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Razorpay _razorpay;

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
    // Process the order on successful payment
    final cart = Provider.of<Cart>(context, listen: false);
    await _placeOrder(context, cart);
    Fluttertoast.showToast(msg: "Payment Success");
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Fluttertoast.showToast(msg: "Payment Failed, please retry");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('External wallet selected')));
  }

  void _openCheckout(double amount) async {
    var options = {
      'key': 'rzp_test_d15RxnRWKBC4rm',
      'amount': amount * 100, // amount in paise
      'name': 'Food Buddies',
      'description': 'Order Payment',
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

  Future<void> _placeOrder(BuildContext context, Cart cart) async {
    try {
      // Retrieve the user phone and type
      String userPhone = await getPhoneNumber();
      String userType = await checkUserType();

      // Initialize buyerPhone and sellerPhone
      String buyerPhone = userPhone;
      String? sellerPhone;

      // Check if the cart is empty
      if (cart.cartItems.isEmpty) {
        print("Cart is empty");
        return;
      }

      // Fetch the latest item details from the server to validate quantities
      for (var item in cart.cartItems) {
        final latestItem = await APIService.fetchItemDetails(item.itemId.toString());
        if (latestItem == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item not found: ${item.name}')));
          return;
        }
        if (item.quantity > latestItem['item_quantity']) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Not enough quantity for item: ${item.name}')));
          return;
        }
      }

      // Assuming all items have the same sellerPhone
      sellerPhone = cart.cartItems.first.seller_phone.toString();

      // Prepare items data
      List<Map<String, dynamic>> items = cart.cartItems.map((item) {
        return {
          'item_id': item.itemId,
          'quantity': item.quantity,
          'seller_phone': item.seller_phone ?? '',
        };
      }).toList();

      // Pass the user type to the placeOrder function
      await APIService.placeOrder(buyerPhone, sellerPhone, items, userType);

      // Clear the cart items after placing the order successfully
      cart.clearCart();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order placed successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to place order: $e')));
      print(e);
    }
  }

  Future<String> checkUserType() async {
    String userPhone = await getPhoneNumber(); // Get phone number from shared preferences
    var url = Uri.http(Config.apiURL, Config.checkUserTypeAPI);
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"phone": userPhone}),
    );
    print(response.body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['userType'];
    } else {
      throw Exception('Failed to check user type');
    }
  }

  Future<String> getPhoneNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String phoneNumber = prefs.getString('phoneNumber') ?? '';
    print(phoneNumber);
    return phoneNumber;
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<Cart>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
      ),
      body: cart.cartItems.isEmpty
          ? Center(
        child: Text(
          'Cart is empty',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 16.0,
          ),
        ),
      )
          : ListView.builder(
        itemCount: cart.cartItems.length,
        itemBuilder: (context, index) {
          final item = cart.cartItems[index];
          return ListTile(
            title: Text(item.name),
            subtitle: Text('₹${item.price}'),
            trailing: SizedBox(
              width: 100.0,
              child: QuantitySelector(
                initialQuantity: item.quantity,
                onChanged: (quantity) {
                  if (quantity == 0) {
                    cart.removeFromCart(item.itemId);
                  } else {
                    cart.updateQuantity(item.itemId, quantity);
                  }
                },
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Total: ₹${cart.calculateTotalPrice()}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
              SizedBox(width: 20.0),
              ElevatedButton(
                onPressed: () {
                  double totalAmount = cart.calculateTotalPrice();
                  _openCheckout(totalAmount);
                },
                child: Text('Place Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
