import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:food_buddies/models/login_response_model.dart';
import 'package:food_buddies/models/seller_item_model.dart';
import 'package:food_buddies/pages/buyer_nav_bar.dart';
import 'package:food_buddies/pages/home_page.dart';
import 'package:food_buddies/pages/seller_nav_bar.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

class APIService {
  static var client = http.Client();

  static Future<LoginResponseModel> otpLogin(String mobileNo) async {
    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
    };
    var url = Uri.http(Config.apiURL, Config.otpLoginAPI);

    var response = await client.post(
      url,
      headers: requestHeaders,
      body: jsonEncode({"phone": mobileNo}),
    );

    return loginResponseJson(response.body);
  }

  static Future<LoginResponseModel> verifyOtp(
      String mobileNo,
      String otpHash,
      String otpCode,
      ) async {
    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
    };

    var url = Uri.http(Config.apiURL, Config.verifyOTPAPI);

    var response = await client.post(
      url,
      headers: requestHeaders,
      body: jsonEncode({"phone": mobileNo, "otp": otpCode, "hash": otpHash}),
    );

    return loginResponseJson(response.body);
  }

  static Future<List<SellerItemModel>> getSellersWithItems(String community) async {
    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
    };
    var url = Uri.http('localhost:4000', '/buyers/by-community', {'community': community});

    var response = await client.get(
      url,
      headers: requestHeaders,
    );
  print(response.body);
    if (response.statusCode == 200) {
      Iterable jsonResponse = json.decode(response.body);
      List<SellerItemModel> sellersWithItems = jsonResponse
          .map((model) => SellerItemModel.fromJson(model))
          .toList();
      return sellersWithItems;
    } else {
      throw Exception('Failed to load sellers with items');
    }
  }

  static Future<void> registerSeller({
    required BuildContext context,
    required String sellerName,
    required String sellerPhone,
    required String sellerAddress,
    required String sellerUpi,
    File? image,
    required String community,
    required String deliveryType,

  }) async {
    var url = Uri.http(Config.apiURL, Config.sellerRegistrationAPI);

    var request = http.MultipartRequest('POST', url);
    request.fields['seller_name'] = sellerName;
    request.fields['seller_phone'] = sellerPhone;
    request.fields['seller_address'] = sellerAddress;
    request.fields['seller_upi'] = sellerUpi;
    request.fields['community'] = community;
    request.fields['delivery_type'] = deliveryType;
    print(request.fields);
    if (image != null) {
      var stream = http.ByteStream(image.openRead());
      var length = await image.length();
      var multipartFile = http.MultipartFile('image', stream, length,
          filename: basename(image.path));
      request.files.add(multipartFile);
    }

    var response = await request.send();
    if (response.statusCode == 200) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SellerHomePage()),
      );
    } else {
      print('Failed to register seller');
    }
  }
  static const String baseUrl = 'http://localhost:4000/';
  Future<String> getPhoneNumber() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('phoneNumber') ?? '';
  }
  Future<List<Map<String, dynamic>>> fetchItems({required String sellerPhone}) async {
    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
    };
    var url = Uri.http('localhost:4000', '/sellers/items', {'sellerPhone': sellerPhone});
    var response = await client.get(
      url,
      headers: requestHeaders
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load items');
    }
  }
  static Future<List<String>> fetchCommunities() async {
    // Replace with your actual API endpoint
    final response = await http.get(Uri.parse('http://localhost:4000/users/communities'));
    if (response.statusCode == 200) {
      List<dynamic> communities = jsonDecode(response.body);
      return communities.map((community) => community['community_name'].toString()).toList();
    } else {
      throw Exception('Failed to load communities');
    }
  }

  static Future<void> registerBuyer({
    required BuildContext context,
    required String buyerName,
    required String buyerPhone,
    required String buyerAddress,
    required String community,
  }) async {
    final response = await http.post(
      Uri.parse('http://localhost:4000/buyers/register-buyer'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'buyer_name': buyerName,
        'buyer_phone': buyerPhone,
        'buyer_address': buyerAddress,
        'community': community,
      }),
    );

    if (response.statusCode == 200) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BuyerHomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to register buyer')));
    }
  }
  Future<void> addItem({
    required BuildContext context, // Add this line
    required String sellerPhone,
    required String itemName,
    required String itemDesc,
    required String itemQuantity,
    required String itemPrice,
    required String itemDelStartTimestamp,
    required String itemDelEndTimestamp,
    required File? itemPhoto,
  }) async {
    try {
      final String phoneNumber = await getPhoneNumber();
      var url = Uri.http(Config.apiURL, Config.addItemsAPI);

      var request = http.MultipartRequest('POST', url);
      request.fields['seller_phone'] = phoneNumber;
      request.fields['item_name'] = itemName;
      request.fields['item_desc'] = itemDesc;
      request.fields['item_quantity'] = itemQuantity;
      request.fields['item_price'] = itemPrice;
      request.fields['item_del_start_timestamp'] = itemDelStartTimestamp;
      request.fields['item_del_end_timestamp'] = itemDelEndTimestamp;

      if (itemPhoto != null) {
        var stream = http.ByteStream(itemPhoto.openRead());
        var length = await itemPhoto.length();
        var multipartFile = http.MultipartFile(
          'item_photo',
          stream,
          length,
          filename: basename(itemPhoto.path),
        );
        request.files.add(multipartFile);
      }
      var response = await request.send();

      if (response.statusCode == 201) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SellerHomePage()),
        );
      } else {
        throw Exception('Failed to add item');
      }
    } catch (e) {
      throw Exception('Failed to add item: $e');
    }
  }
  Future<void> updateItem({
    required BuildContext context,
    required int itemId,
    required String itemName,
    required String itemDesc,
    required String itemQuantity,
    required String itemPrice,
    required String itemDelStartTimestamp,
    required String itemDelEndTimestamp,
    File? itemPhoto,
  }) async {
    DateTime startDateTime = DateTime.parse(itemDelStartTimestamp);
    DateTime endDateTime = DateTime.parse(itemDelEndTimestamp);
    String formattedStartDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(startDateTime);
    String formattedEndDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(endDateTime);
    var url = Uri.http(Config.apiURL, '/sellers/updateItem/$itemId'); // Include itemId in the URL path
    print(url);
    var request = http.MultipartRequest('POST', url);
    request.fields['item_name'] = itemName; // Use the same field names as expected by the backend
    request.fields['item_desc'] = itemDesc;
    request.fields['item_quantity'] = itemQuantity;
    request.fields['item_price'] = itemPrice;
    request.fields['item_del_start_timestamp'] = formattedStartDateTime;
    request.fields['item_del_end_timestamp'] = formattedEndDateTime;

    if (itemPhoto != null) {
      request.files.add(
        await http.MultipartFile.fromPath('item_photo', itemPhoto.path), // Use the same field name as expected by the backend
      );
    }

    final response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Failed to update item');
    }
  }
  static const String _baseUrl = 'http://localhost:4000';
  static Future<Map<String, dynamic>> getBuyerProfile(String phone) async {
    final response = await http.get(Uri.parse('$_baseUrl/buyers/buyer/$phone'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load buyer profile');
    }
  }

  static Future<void> updateBuyerProfile({required String phone, required String name, required String address, required String community}) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/buyers/buyer/$phone'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'buyer_name': name, 'buyer_address': address, 'community': community}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update buyer profile');
    }
  }

  static Future<Map<String, dynamic>> getSellerProfile(String phone) async {
    final response = await http.get(Uri.parse('$_baseUrl/sellers/seller/$phone'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load seller profile');
    }
  }

  static Future<void> updateSellerProfile({required String phone, required String name, required String address, required String upi, required String community, required String deliveryType}) async {
    print(deliveryType);
    final response = await http.put(
      Uri.parse('$_baseUrl/sellers/seller/$phone'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'seller_name': name, 'seller_address': address, 'seller_upi': upi, 'community': community, 'delivery_type' : deliveryType}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update seller profile');
    }
  }
  static Future<void> placeOrder(
      String buyerPhone, String sellerPhone, List<Map<String, dynamic>> items, String userType) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/buyers/placeOrder'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "buyer_phone": buyerPhone,
        "seller_phone": sellerPhone,
        "items": items,
        "buyer_role": userType
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to place order');
    }
  }
  static Future<Map<String, dynamic>?> fetchItemDetails(String itemId) async {
    final response = await http.get(Uri.parse('$_baseUrl/buyers/items/$itemId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
       print(jsonDecode(response.body));
    }
  }
   Future<List<Map<String, dynamic>>> getOrdersForSeller() async {
    final String phoneNumber = await getPhoneNumber();
    final response = await http.get(Uri.parse('$_baseUrl/sellers/orders/$phoneNumber'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load orders');
    }
  }

  static Future<void> markOrderAsDelivered(int orderId) async {
    final response = await http.put(Uri.parse('$_baseUrl/sellers/orders/$orderId/delivered'));
    if (response.statusCode != 200) {
      throw Exception('Failed to mark order as delivered');
    }
  }

  static Future<List<Map<String, dynamic>>> getOrderItems(int orderId) async {
    final response = await http.get(Uri.parse('$_baseUrl/sellers/orders/items/$orderId'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load order items');
    }
  }

  static Future<List<Map<String, dynamic>>> getBuyerOrders(String buyerPhone) async {
    final response = await http.get(Uri.parse('$_baseUrl/buyers/orders/$buyerPhone'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load buyer orders');
    }
  }
  static Future<bool> updateOrderDeliveryType(int orderId, String deliveryType) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/sellers/orders/delivery-type/$orderId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'delivery_type': deliveryType}),
    );
    if (response.statusCode == 200) {
      print("updated Successfully");
      return true;
    } else {
      throw Exception('Failed to load buyer orders');
    }
  }
}

