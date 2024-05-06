import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:food_buddies/pages/login_otp_page.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:food_buddies/models/cart_model.dart'; // Import Cart model

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
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: loginOTPPage(),
      ),
    );
  }
}
