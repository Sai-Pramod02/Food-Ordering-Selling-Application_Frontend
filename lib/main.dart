

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:food_buddies/pages/buyer_registration_page.dart';
import 'package:food_buddies/pages/login_otp_page.dart';
import 'package:food_buddies/pages/renew_membership_page.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:food_buddies/models/cart_model.dart';
import 'package:food_buddies/pages/seller_registration_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_buddies/pages/buyer_nav_bar.dart';
import 'package:food_buddies/pages/seller_nav_bar.dart';
import 'package:food_buddies/pages/config.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize OneSignal
  await OneSignal.shared.setAppId("e970f590-077b-44bf-9fad-a5f9571be7f5");

  // Request notification permission
  await OneSignal.shared.promptUserForPushNotificationPermission(fallbackToSettings: true);


  bool storage = true;
  bool videos = true;
  bool photos = true;

// Only check for storage < Android 13
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  if (androidInfo.version.sdkInt >= 33) {
    videos = await Permission.videos.status.isGranted;
    photos = await Permission.photos.status.isGranted;
  } else {
    storage = await Permission.storage.status.isGranted;
  }
  print(photos);
  print(videos);
  print(storage);
  if (storage && videos && photos) {
    // Good to go!
    await Permission.photos.request();
    await Permission.storage.request();
    print('Good to go');
  } else {
    // crap.
    await Permission.photos.request();
    await Permission.storage.request();
    print("Fuck it");
  }


  runApp(
    ChangeNotifierProvider(
      create: (context) => Cart(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => Cart(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: FutureBuilder<String>(
          future: checkUserType(),
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else {
              if (snapshot.hasError)
                return Text('Error: ${snapshot.error}');
              else if (snapshot.data == 'buyer')
                return BuyerHomePage();
              else if (snapshot.data == 'seller')
                return SellerHomePage();
              else
                return loginOTPPage();
            }
          },
        ),
      ),
    );
  }

  Future<String> checkUserType() async {
    String userPhone = await getPhoneNumber();
    String? playerId = await getPlayerId();

    var url = Uri.http('34.16.177.102:4000', Config.checkUserTypeAPI);
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"phone": userPhone, "playerId": playerId}),
    );
    print(response.body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['userType'];
    } else {
      throw Exception('Failed to check user type');
    }
  }

  Future<String?> getPlayerId() async {
    var status = await OneSignal.shared.getDeviceState();
    print(status?.userId);
    return status?.userId;
  }

  Future<String> getPhoneNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String phoneNumber = prefs.getString('phoneNumber') ?? '';
    print(phoneNumber);
    return phoneNumber;
  }
}