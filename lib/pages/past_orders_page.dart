import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:fluttertoast/fluttertoast.dart'; // For Toast messages
import 'package:food_buddies/pages/ api_service.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class PastOrdersPage extends StatefulWidget {
  final String buyerPhone;

  PastOrdersPage({required this.buyerPhone});

  @override
  _PastOrdersPageState createState() => _PastOrdersPageState();
}

class _PastOrdersPageState extends State<PastOrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List activeOrders = [];
  List pastOrders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await APIService.getBuyerOrders(widget.buyerPhone);
      setState(() {
        activeOrders = orders
            .where((order) =>
        order['order_delivered'] == 0 && order['order_cancelled'] == 0)
            .toList()
            .reversed
            .toList();
        pastOrders = orders
            .where((order) =>
        order['order_delivered'] == 1 || order['order_cancelled'] == 1)
            .toList()
            .reversed
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load orders: $e')));
    }
  }

  void _showOrderDetails(int orderId) async {
    final APIService apiService = APIService();
    final orderItems = await apiService.getOrderItems(context, orderId);
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('Order Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: orderItems.map((item) {
                return ListTile(
                  title: Text(item['item_name']),
                  subtitle: Text(
                      'Price: ₹${item['item_price']} Quantity: ${item['item_quantity']}'),
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
    );
  }

  void _refreshOrder(int orderId, int orderRating, String orderReview) {
    setState(() {
      for (var order in pastOrders) {
        if (order['order_id'] == orderId) {
          order['order_rating'] = orderRating; // Update with the actual rating
          order['order_review'] = orderReview; // Update with the actual review
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Orders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Active Orders'),
            Tab(text: 'Past Orders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(activeOrders, false),
          _buildOrderList(pastOrders, true),
        ],
      ),
    );
  }

  Widget _buildOrderList(List orders, bool isPast) {
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final orderReviewed = order['order_rating'] != null &&
            order['order_review'] != null;
        final bool isCancelled = order['order_cancelled'] == 1;

        return Card(
          margin: EdgeInsets.symmetric(vertical: 8.0),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          elevation: 5,
          child: InkWell(
            onTap: () => _showOrderDetails(order['order_id']),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seller: ${order['seller_name']}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Total Price: ₹${order['order_total_price']}'),
                  Text(
                    'Delivery Type: ${order['delivery_type']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: order['delivery_type'] == 'HOME DELIVERY' ? Colors
                          .green : Colors.blue,
                    ),
                  ),
                  Text(
                    isCancelled ? 'Cancelled' : (isPast
                        ? 'Delivered'
                        : 'Yet to be Delivered'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCancelled ? Colors.red : (isPast
                          ? Colors.green
                          : Colors.red),
                    ),
                  ),
                  if (orderReviewed) ...[
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Your Rating: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        Text(
                          '${order['order_rating']}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Review:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(order['order_review']),
                  ],
                  if (isPast && !orderReviewed && !isCancelled)
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return RatingReviewDialog(
                              orderId: order['order_id'],
                              sellerPhone: order['seller_phone'],
                              onReviewSubmitted: (int rating, String review) {
                                _refreshOrder(order['order_id'], rating, review);
                              },
                            );
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[900], // Background color
                      ),
                      child: Text(
                        'Rate & Review',
                        style: TextStyle(color: Colors.amber), // Text color
                      ),
                    ),
                  SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return Container(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Seller Phone Number', style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                                SizedBox(height: 10),
                                AnimatedTextKit(
                                  animatedTexts: [
                                    TypewriterAnimatedText(
                                      order['seller_phone'],
                                      textStyle: TextStyle(
                                          fontSize: 16, color: Colors.black),
                                      speed: Duration(milliseconds: 100),
                                    ),
                                  ],
                                  totalRepeatCount: 1,
                                ),
                                SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(
                                            text: order['seller_phone']));
                                        Fluttertoast.showToast(
                                          msg: "Phone number copied to clipboard",
                                          toastLength: Toast.LENGTH_SHORT,
                                          gravity: ToastGravity.BOTTOM,
                                          timeInSecForIosWeb: 1,
                                          backgroundColor: Colors.black54,
                                          textColor: Colors.white,
                                          fontSize: 16.0,
                                        );
                                      },
                                      icon: Icon(Icons.copy),
                                      label: Text('Copy to Clipboard'),
                                    ),
                                    SizedBox(width: 10),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                          'Close', style: TextStyle(color: Theme
                                          .of(context)
                                          .primaryColor)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Contact Seller',
                        style: TextStyle(color: Theme
                            .of(context)
                            .primaryColor,
                            fontSize: 16,
                            decoration: TextDecoration.underline),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class RatingReviewDialog extends StatefulWidget {
  final int orderId;
  final String sellerPhone;
  final void Function(int, String) onReviewSubmitted;

  RatingReviewDialog({required this.orderId, required this.sellerPhone, required this.onReviewSubmitted});

  @override
  _RatingReviewDialogState createState() => _RatingReviewDialogState();
}

class _RatingReviewDialogState extends State<RatingReviewDialog> {
  int _rating = 3;
  final _reviewController = TextEditingController();

  void _submitReview() async {
    final review = _reviewController.text;
    if (review.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please write a review')));
      return;
    }

    final success = await APIService.submitRatingAndReview(
      orderId: widget.orderId,
      sellerPhone: widget.sellerPhone,
      rating: _rating,
      review: review,
    );

    if (success) {
      widget.onReviewSubmitted(_rating, review);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Review submitted successfully')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit review')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text(
        'Rate & Review',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () {
                  setState(() {
                    _rating = index + 1;
                  });
                },
              );
            }),
          ),
          TextField(
            controller: _reviewController,
            maxLines: 3,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Write your review here',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white54),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.white)),
        ),
        TextButton(
          onPressed: _submitReview,
          child: Text('Submit', style: TextStyle(color: Colors.amber)),
        ),
      ],
    );
  }
}
