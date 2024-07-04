import 'package:flutter/material.dart';
import 'package:food_buddies/pages/ api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:animated_text_kit/animated_text_kit.dart';

class ManageOrdersPage extends StatefulWidget {
  @override
  _ManageOrdersPageState createState() => _ManageOrdersPageState();
}

class _ManageOrdersPageState extends State<ManageOrdersPage> {
  List<Map<String, dynamic>> _activeOrders = [];
  List<Map<String, dynamic>> _pastOrders = [];
  String _sellerDeliveryType = 'HOME DELIVERY'; // Default delivery type

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _fetchSellerProfile();
  }

  Future<void> _fetchOrders() async {
    final APIService apiService = APIService();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String phone = prefs.getString('phoneNumber') ?? '';

    final orders = await apiService.getOrdersForSeller(context);

    setState(() {
      _activeOrders = orders.where((order) => order['order_delivered'] == 0).toList().reversed.toList();
      _pastOrders = orders.where((order) => order['order_delivered'] == 1).toList().reversed.toList();

      // Fetch and update delivery type for each order
      _activeOrders.forEach((order) async {
        if (order['delivery_type'] == null) {
          // If order's delivery type is not set, fetch from seller profile
          order['delivery_type'] = _sellerDeliveryType;
        }
      });

      _pastOrders.forEach((order) async {
        if (order['delivery_type'] == null) {
          // If order's delivery type is not set, fetch from seller profile
          order['delivery_type'] = _sellerDeliveryType;
        }
      });
    });
  }

  Future<void> _fetchSellerProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String phone = prefs.getString('phoneNumber') ?? '';
    final sellerProfile = await APIService.getSellerProfile(phone);
    setState(() {
      _sellerDeliveryType = sellerProfile['delivery_type'] ?? 'HOME DELIVERY';
    });
  }

  void _markAsDelivered(int orderId) async {
    final APIService apiService = APIService();
    await apiService.markOrderAsDelivered(context, orderId);
    _fetchOrders();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order marked as delivered')));
  }

  void _showOrderDetails(int orderId) async {
    final APIService apiService = APIService();
    final orderItems = await apiService.getOrderItems(context, orderId);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: orderItems.map((item) {
              return ListTile(
                title: Text(item['item_name']),
                subtitle: Text('Price: \$${item['item_price']} Quantity: ${item['item_quantity']}'),
              );
            }).toList(),
          ),
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

  void _updateDeliveryType(int orderId, String deliveryType) async {
    final APIService apiService = APIService();
    await apiService.updateOrderDeliveryType(context, orderId, deliveryType);
    _fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Orders')),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: [
                Tab(text: 'Active Orders'),
                Tab(text: 'Past Orders'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildOrderList(_activeOrders, false),
                  _buildOrderList(_pastOrders, true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders, bool isPast) {
    return ListView.builder(
      padding: EdgeInsets.all(8.0),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        bool isHomeDelivery = order['delivery_type'] == 'HOME DELIVERY';
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order['buyer_name'],
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (!isPast)
                        ElevatedButton(
                          onPressed: () => _markAsDelivered(order['order_id']),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.green,
                            minimumSize: Size(110, 50), // Adjust button size as needed
                          ),
                          child: Text('Mark Delivered', style: TextStyle(fontSize: 15)),
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('Address: ${order['buyer_address']}'),
                  Text('Total Price: \$${order['order_total_price']}'),
                  if (!isPast) ...[
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text('PICK UP', style: TextStyle(fontSize: 12)),
                            Switch(
                              value: isHomeDelivery,
                              onChanged: (bool value) {
                                String newDeliveryType = value ? 'HOME DELIVERY' : 'PICK UP';
                                _updateDeliveryType(order['order_id'], newDeliveryType);
                              },
                              activeColor: Theme.of(context).primaryColor,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            Text('HOME DELIVERY', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
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
                                  Text('Buyer Phone Number', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 10),
                                  AnimatedTextKit(
                                    animatedTexts: [
                                      TypewriterAnimatedText(
                                        order['buyer_phone'],
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
                          'Contact Buyer',
                          style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 16, decoration: TextDecoration.underline),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
