// seller_items.dart
import 'package:flutter/material.dart';
import 'package:food_buddies/components/quantity_selector.dart';
import 'package:provider/provider.dart';
import 'package:food_buddies/models/cart_model.dart';
import 'package:food_buddies/pages/cart_page.dart';
import 'package:intl/intl.dart';

class SellerItemsList extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  SellerItemsList({required this.items});

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
      body: Consumer<Cart>(
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
                elevation: 2.0,
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          getImageUrl(item['imageUrl']),
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
                              item['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18.0,
                              ),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              'Price: ₹${item['price']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              'Available Quantity: ${item['quantity']}',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14.0,
                              ),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              'Taking orders till -  $orderendDate',
                              style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              'Start : $startDate',
                              style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              'End : $endDate',
                              style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (closingSoon)
                              Text(
                                'Closing Soon',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            SizedBox(height: 8.0),
                            Text(
                              item['description'] ?? '',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if ((item['description'] ?? '').length > 100)
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(item['name']),
                                        content: Text(item['description'] ?? ''),
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
                          ],
                        ),
                      ),
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
                                  name: item['name'],
                                  price: item['price'].toDouble(),
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
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CartPage(),
            ),
          );
        },
        child: Icon(Icons.shopping_cart),
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
              'Your cart contains dishes from a different seller. Do you want to discard the current selection and add dishes from this seller?'),
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
                  name: item['name'],
                  price: item['price'].toDouble(),
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
