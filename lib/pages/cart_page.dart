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
  String? _orderId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _fetchAndValidateItems();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchAndValidateItems() async {
    final cart = Provider.of<Cart>(context, listen: false);
    final sellerPhone = cart.getSellerPhone();

    if (sellerPhone != null) {
      List<Map<String, dynamic>> fetchedItems = await APIService.getSellerItems(sellerPhone);
      if (fetchedItems != null) {
        List fetchedItemIds = fetchedItems.map((item) => item['item_id']).toList();
        List<CartItem> itemsToRemove = [];

        for (var cartItem in cart.cartItems) {
          if (!fetchedItemIds.contains(cartItem.itemId)) {
            itemsToRemove.add(cartItem);
          }
        }

        for (var item in itemsToRemove) {
          cart.removeFromCart(item.itemId);
        }
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Update the order status on successful payment
    if (_orderId != null) {
      await _updateOrderStatus(_orderId!);

      // Retrieve seller_player_id from shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sellerPlayerId = prefs.getString('seller_player_id');

      if (sellerPlayerId != null) {
        // Send notification to seller
        await sendNotificationToDevice(sellerPlayerId, 'We are excited to inform you that you have received a new order!');
      }
    }
    // Clear the cart items after successful payment
    Provider.of<Cart>(context, listen: false).clearCart();
    Fluttertoast.showToast(msg: "Payment Success");
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
      final response = await APIService.placeOrder(buyerPhone, sellerPhone, items, userType);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _orderId = data['order_id'].toString(); // Store the order ID

        // Store seller_player_id in shared preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('seller_player_id', data['seller_player_id']);

        // Open payment checkout
        _openCheckout(cart.calculateTotalPrice());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to place order')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to place order: $e')));
      print(e);
    }
  }

  Future<void> _updateOrderStatus(String orderId) async {
    try {
      final response = await APIService.updateOrderStatus(orderId);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order completed successfully')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update order status')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update order status: $e')));
      print(e);
    }
  }

  Future<String> checkUserType() async {
    String userPhone = await getPhoneNumber(); // Get phone number from shared preferences
    var url = Uri.http(Config.apiURL, '/users/check-user-type-withoutplayerid');
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
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ₹${cart.calculateTotalPrice()}',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _placeOrder(context, cart),
                  child: Text('Place Order'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
