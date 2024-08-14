import 'dart:io';
import 'package:food_buddies/components/loadingComponent.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_buddies/pages/add_items.dart';
import ' api_service.dart';

class ManageItemsPage extends StatefulWidget {
  @override
  _ManageItemsPageState createState() => _ManageItemsPageState();
}

class _ManageItemsPageState extends State<ManageItemsPage> {
  List<Map<String, dynamic>> activeItems = [];
  List<Map<String, dynamic>> pastItems = [];
  final String baseUrl = 'http://34.16.177.102:4000/';
  final String defaultImageUrl = 'https://i.imgur.com/bOCEVJg.png';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() {
      _isLoading = true;
    });
    final APIService apiService = APIService();
    final phoneNumber = await _getPhoneNumber();
    final items = await APIService.fetchItems(
        context, sellerPhone: phoneNumber);
    final currentTime = DateTime.now().toLocal();

    setState(() {
      activeItems = items.where((item) {
        final itemTimestamp = DateFormat("yyyy-MM-ddTHH:mm:ssZ").parse(
            item['item_del_end_timestamp']);
        return itemTimestamp.isAfter(currentTime) && item['item_quantity'] > 0;
      }).toList();

      pastItems = items.where((item) {
        final itemTimestamp = DateFormat("yyyy-MM-ddTHH:mm:ssZ").parse(
            item['item_del_end_timestamp']);
        return itemTimestamp.isBefore(currentTime) ||
            item['item_quantity'] == 0;
      }).toList();

      _isLoading = false;
    });
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
      orderEndDate: DateTime.now().toIso8601String(),
      itemPhoto: null,
    );
    _fetchItems();
  }

  void _navigateToAddItemPage({Map<String, dynamic>? item}) {
    if (item != null) {
      final currentTime = DateTime.now().toLocal();
      final itemTimestamp = DateFormat("yyyy-MM-ddTHH:mm:ssZ").parse(item['item_del_end_timestamp']);

      // Check if the item is in pastItems (i.e., the end timestamp is before the current time)
      if (itemTimestamp.isBefore(currentTime) || item['item_quantity'] == 0) {
        // Clear the timestamps if the item is in pastItems
        item['item_del_start_timestamp'] = '';
        item['item_del_end_timestamp'] = '';
        item['order_end_date'] = '';
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddItemPage(item: item),
      ),
    ).then((_) => _fetchItems());
  }

  bool isNetworkImage(String url) {
    Uri? uri = Uri.tryParse(url);
    return uri != null && uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }

  String getImageUrl(String itemPhoto) {
    return isNetworkImage(itemPhoto) ? itemPhoto : baseUrl + itemPhoto;
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Manage Items',
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.orange,
        elevation: 4,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: LoadingComponent())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => _navigateToAddItemPage(),
              child: Text(
                'Add New Item',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
            ),
          ),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Container(
                    color: Colors.orange,
                    child: TabBar(
                      labelStyle: TextStyle(fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                      indicatorColor: Colors.red,
                      tabs: [
                        Tab(text: 'Active Items'),
                        Tab(text: 'Past Items'),
                      ],
                    ),
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
      padding: EdgeInsets.all(8.0),
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
    final String? orderEnd = item['order_end_date'] != null
        ? _formatDateTime(item['order_end_date'])
        : null;

    return Card(
      elevation: 6.0,
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      color: Colors.orange[100],
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
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.network(
                        defaultImageUrl,
                        height: 120,
                        width: 120,
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
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        'Price: ₹${item['item_price']}',
                        style: TextStyle(fontSize: 16.0, color: Colors.black54),
                      ),
                      Text(
                        'Quantity: ${item['item_quantity']}',
                        style: TextStyle(fontSize: 16.0, color: Colors.black54),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        'Start: $startDate',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        'End: $endDate',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      if (orderEnd != null)
                        Text(
                          'Order End: $orderEnd',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      if (closingSoon && isActive)
                        Text(
                          'Closing Soon',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                      SizedBox(height: 8.0),
                      Text(
                        item['item_desc'],
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14.0, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isActive)
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () => _closeItem(item),
                  ),
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.orange),
                  onPressed: () => _navigateToAddItemPage(item: item),
                ),
              ],

            ),
          ],
        ),
      ),
    );
  }

}