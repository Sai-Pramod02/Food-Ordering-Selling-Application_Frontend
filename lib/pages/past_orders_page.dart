import 'package:flutter/material.dart';
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
        activeOrders = orders.where((order) => order['order_delivered'] == 0).toList();
        pastOrders = orders.where((order) => order['order_delivered'] == 1).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load orders: $e')));
    }
  }

  void _showOrderDetails(int orderId) async {
    final APIService apiService = APIService();
    final orderItems = await apiService.getOrderItems(context, orderId);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: orderItems.map((item) {
            return ListTile(
              title: Text(item['item_name']),
              subtitle: Text('Price: ₹${item['item_price']} Quantity: ${item['item_quantity']}'),
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
        print(order);
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                      color: order['delivery_type'] == 'HOME DELIVERY' ? Colors.green : Colors.blue,
                    ),
                  ),
                  Text(
                    isPast ? 'Delivered' : 'Yet to be Delivered',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPast ? Colors.green : Colors.red,
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
                                Text('Seller Phone Number', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                SizedBox(height: 10),
                                AnimatedTextKit(
                                  animatedTexts: [
                                    TypewriterAnimatedText(
                                      order['seller_phone'],
                                      textStyle: TextStyle(fontSize: 16, color: Colors.black),
                                      speed: Duration(milliseconds: 100),
                                    ),
                                  ],
                                  totalRepeatCount: 1,
                                ),
                                SizedBox(height: 10),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Close', style: TextStyle(color: Theme.of(context).primaryColor)),
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
                        style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 16, decoration: TextDecoration.underline),
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
