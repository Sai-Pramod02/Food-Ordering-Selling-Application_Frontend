import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:food_buddies/pages/buyer_registration_page.dart';
import 'package:food_buddies/pages/login_otp_page.dart';
import 'package:food_buddies/pages/renew_membership_page.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:food_buddies/models/cart_model.dart'; // Import Cart model
import 'package:food_buddies/pages/seller_registration_page.dart'; // Import Cart model
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_buddies/pages/buyer_nav_bar.dart'; // Import Cart model
import 'package:food_buddies/pages/seller_nav_bar.dart'; // Import Cart model
import 'package:food_buddies/pages/config.dart'; // Import Cart model
import 'package:http/http.dart' as http;

import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => Cart(), // Provide Cart instance
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => Cart(), // Provide Cart instance
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: FutureBuilder<String>(
          future: checkUserType(), // function that returns Future<String>
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator(); // loading animation
            } else {
              if (snapshot.hasError)
                return Text('Error: ${snapshot.error}');
              else if (snapshot.data == 'buyer')
                return BuyerHomePage(); // if user is a buyer
              else if (snapshot.data == 'seller')
                return SellerHomePage(); // if user is a seller
              else
                return loginOTPPage(); // if user doesn't exist
            }
          },
        ),
      ),
    );
  }

  Future<String> checkUserType() async {
    String userPhone = await getPhoneNumber(); // Get phone number from shared preferences
    var url = Uri.http('34.16.177.102:4000', Config.checkUserTypeAPI);
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
  Future<void> removePhoneNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('phoneNumber');
  }
  Future<String> getPhoneNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String phoneNumber = prefs.getString('phoneNumber') ?? '';
    print(phoneNumber);
    return phoneNumber;
  }
}

