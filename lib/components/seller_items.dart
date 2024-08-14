import 'package:flutter/material.dart';
import 'package:food_buddies/components/quantity_selector.dart';
import 'package:provider/provider.dart';
import 'package:food_buddies/models/cart_model.dart';
import 'package:food_buddies/pages/cart_page.dart';
import 'package:food_buddies/pages/ api_service.dart'; // Import your API service
import 'package:intl/intl.dart';

class SellerItemsList extends StatefulWidget {
  final List<Map<String, dynamic>> initialItems;
  final String fssai_code;
  final String sellerPhone;

  SellerItemsList({required this.initialItems, required this.fssai_code, required this.sellerPhone});

  @override
  _SellerItemsListState createState() => _SellerItemsListState();
}

class _SellerItemsListState extends State<SellerItemsList> {
  late List<Map<String, dynamic>> items;
  bool _isLoading = true; // Added loading state

  @override
  void initState() {
    super.initState();
    items = widget.initialItems;
    fetchLatestItems();
  }

  Future<void> fetchLatestItems() async {
    try {
      List<Map<String, dynamic>> fetchedItems = await APIService.getSellerItems(widget.sellerPhone);
      setState(() {
        items = fetchedItems;
        _isLoading = false; // Update loading state
      });
    } catch (e) {
      // Handle error
      print('Error fetching latest items: $e');
      setState(() {
        _isLoading = false; // Stop loading if there's an error
      });
    }
  }

  final String baseUrl = 'http://34.16.177.102:4000/';
  final String defaultImageUrl = 'https://i.imgur.com/bOCEVJg.png';

  String _formatDateTime(String dateTimeStr) {
    final dateTime = DateTime.parse(dateTimeStr);
    final formatter = DateFormat('EEE dd MMM hh:mma');
    return formatter.format(dateTime);
  }

  bool _isClosingSoon(String endTimestamp) {
    final endTime = DateTime.parse(endTimestamp);
    final currentTime = DateTime.now();
    return endTime.isBefore(currentTime.add(Duration(minutes: 30)));
  }

  bool isNetworkImage(String url) {
    Uri? uri = Uri.tryParse(url);
    return uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  String getImageUrl(String? itemPhoto) {
    if (itemPhoto == null || itemPhoto.isEmpty) {
      return defaultImageUrl;
    }
    return isNetworkImage(itemPhoto) ? itemPhoto : baseUrl + itemPhoto;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seller Items'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //CircularProgressIndicator(), // Loading animation
            SizedBox(height: 16.0),
            Image.asset(
              'assets/logo.png', // Your logo asset
              height: 100, // Adjust as needed
              width: 100,  // Adjust as needed
            ),
            SizedBox(height: 16.0),
            Text(
              'Fetching items...',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      )
          : Column(
        children: [
          Flexible(
            child: Consumer<Cart>(
              builder: (context, cart, child) {
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final initialQuantity = cart.getQuantity(item['item_id']);
                    final startDate = _formatDateTime(item['item_del_start_timestamp']);
                    final endDate = _formatDateTime(item['item_del_end_timestamp']);
                    final orderendDate = _formatDateTime(item['order_end_date']);
                    final closingSoon = _isClosingSoon(item['item_del_end_timestamp']);

                    return Card(
                      elevation: 4.0,
                      margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12.0),
                                  child: Image.network(
                                    getImageUrl(item['item_photo']),
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.network(
                                        defaultImageUrl,
                                        height: 100,
                                        width: 100,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(width: 16.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['item_name'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20.0,
                                        ),
                                      ),
                                      SizedBox(height: 8.0),
                                      Text(
                                        'Price: ₹${item['item_price']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18.0,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Text(
                                        'Available Quantity: ${item['item_quantity']}',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 16.0,
                                        ),
                                      ),
                                      if (closingSoon)
                                        Text(
                                          'Closing Soon',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                            fontSize: 16.0,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.0),
                            Text(
                              'Taking orders till: $orderendDate',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              'Delivery Start: $startDate',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              'Delivery End: $endDate',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16.0),
                            Text(
                              item['item_desc'] ?? '',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.0,
                                color: Colors.black54,
                              ),
                            ),
                            if ((item['item_desc'] ?? '').length > 100)
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(item['item_name']),
                                        content: Text(item['item_desc'] ?? ''),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text('Close'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: Text(
                                  'Read More',
                                  style: TextStyle(
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            SizedBox(height: 16.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                QuantitySelector(
                                  initialQuantity: initialQuantity,
                                  onChanged: (quantity) {
                                    if (quantity == 0) {
                                      cart.removeFromCart(item['item_id']);
                                    } else {
                                      final existingSellerPhone = cart.getSellerPhone();
                                      if (existingSellerPhone != null && existingSellerPhone != item['seller_phone']) {
                                        _showSellerChangeDialog(context, cart, item, quantity);
                                      } else {
                                        if (cart.getQuantity(item['item_id']) == 0 && quantity > 0) {
                                          cart.addToCart(CartItem(
                                            itemId: item['item_id'],
                                            name: item['item_name'],
                                            price: item['item_price'].toDouble(),
                                            quantity: quantity,
                                            seller_phone: item['seller_phone'],
                                          ));
                                        } else {
                                          cart.updateQuantity(item['item_id'], quantity);
                                        }
                                      }
                                    }
                                  },
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    if (initialQuantity > 0) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CartPage(),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Please select quantity before adding to cart'),
                                        ),
                                      );
                                    }
                                  },
                                  child: Text('Add to Cart'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            color: Colors.grey[200],
            padding: EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                'FSSAI Code: ${widget.fssai_code}',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSellerChangeDialog(BuildContext context, Cart cart, Map<String, dynamic> item, int quantity) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change Seller'),
          content: Text(
              'Your cart already contains items from another seller. Do you want to remove those items and add items from this seller?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                cart.clearCart();
                cart.addToCart(CartItem(
                  itemId: item['item_id'],
                  name: item['item_name'],
                  price: item['item_price'].toDouble(),
                  quantity: quantity,
                  seller_phone: item['seller_phone'],
                ));
                Navigator.of(context).pop();
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }
}
