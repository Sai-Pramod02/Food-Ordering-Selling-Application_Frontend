import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_buddies/pages/add_items.dart';
import 'package:food_buddies/pages/ api_service.dart';

class ManageItemsPage extends StatefulWidget {
  @override
  _ManageItemsPageState createState() => _ManageItemsPageState();
}

class _ManageItemsPageState extends State<ManageItemsPage> {
  List<Map<String, dynamic>> activeItems = [];
  List<Map<String, dynamic>> pastItems = [];
  final String baseUrl = 'http://localhost:4000/';
  final String defaultImageUrl = 'https://i.imgur.com/bOCEVJg.png';
  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    final APIService apiService = APIService();
    final phoneNumber = await _getPhoneNumber();
    final items = await apiService.fetchItems(context, sellerPhone: phoneNumber);
    final currentTime = DateTime.now();
    if (!mounted) return;
    setState(() {
      activeItems = items.where((item) =>
      DateFormat("yyyy-MM-ddTHH:mm:ssZ").parse(item['item_del_end_timestamp'], true).isAfter(currentTime) &&
          item['item_quantity'] > 0).toList();
      pastItems = items.where((item) =>
      DateFormat("yyyy-MM-ddTHH:mm:ssZ").parse(item['item_del_end_timestamp'], true).isBefore(currentTime) ||
          item['item_quantity'] == 0).toList();
    });
    print(activeItems);
  }

  Future<String> _getPhoneNumber() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('phoneNumber') ?? '';
  }

  Future<void> _closeItem(Map<String, dynamic> item) async {
    final APIService apiService = APIService();
    final updatedItem = {
      ...item,
      'item_del_end_timestamp': DateTime.now().toIso8601String(),
      'item_quantity': 0,
    };

    await apiService.updateItem(
      context: context,
      itemId: item['item_id'],
      itemName: item['item_name'],
      itemDesc: item['item_desc'],
      itemQuantity: '0',
      itemPrice: item['item_price'].toString(),
      itemDelStartTimestamp: item['item_del_start_timestamp'],
      itemDelEndTimestamp: DateTime.now().toIso8601String(),
      itemPhoto: null,
    );
    _fetchItems();
  }

  void _navigateToAddItemPage({Map<String, dynamic>? item}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddItemPage(item: item),
      ),
    ).then((_) => _fetchItems());
  }

  bool isNetworkImage(String url) {
    Uri? uri = Uri.tryParse(url);
    return uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  String getImageUrl(String itemPhoto) {
    return isNetworkImage(itemPhoto) ? itemPhoto : baseUrl + itemPhoto;
  }

  String _formatDateTime(String dateTimeStr) {
    final dateTime = DateFormat("yyyy-MM-ddTHH:mm:ssZ").parse(dateTimeStr, true);
    final formatter = DateFormat('EEE dd MMM hh:mma');
    return formatter.format(dateTime);
  }


  bool _isClosingSoon(String endTimestamp) {
    final endTime = DateTime.parse(endTimestamp);
    final currentTime = DateTime.now();
    return endTime.isBefore(currentTime.add(Duration(minutes: 30)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Manage Items'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => _navigateToAddItemPage(),
            child: Text('Add Item'),
          ),
          SizedBox(height: 20),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(text: 'Active Items'),
                      Tab(text: 'Past Items'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildItemList(activeItems, true),
                        _buildItemList(pastItems, false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(List<Map<String, dynamic>> items, bool isActive) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildItemCard(item, isActive);
      },
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, bool isActive) {
    final String startDate = _formatDateTime(item['item_del_start_timestamp']);
    final String endDate = _formatDateTime(item['item_del_end_timestamp']);
    final bool closingSoon = _isClosingSoon(item['item_del_end_timestamp']);

    return Card(
      elevation: 2.0,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
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
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Text('Price: ₹${item['item_price']}'),
                      Text('Quantity: ${item['item_quantity']}'),
                      SizedBox(height: 8.0),
                      Text(
                        'Start: $startDate',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'End: $endDate',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (closingSoon && isActive)
                        Text(
                          'Closing Soon',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      SizedBox(height: 8.0),
                      Text(
                        item['item_desc'],
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item['item_desc'].length > 100) // Adjust the length as needed
                        GestureDetector(
                          onTap: () {
                            // Show full description in a dialog or new screen
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(item['item_name']),
                                  content: Text(item['item_desc']),
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
              ],
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Row(
                children: [
                  if (isActive)
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _navigateToAddItemPage(item: item),
                    ),
                  if (isActive)
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red),
                      onPressed: () => _closeItem(item),
                    ),
                  if (!isActive)
                    IconButton(
                      icon: Icon(Icons.copy, color: Colors.green),
                      onPressed: () =>
                          _navigateToAddItemPage(
                            item: {
                              ...item,
                              'item_id': null,
                              'item_del_start_timestamp': '',
                              'item_del_end_timestamp': '',
                            },
                          ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
