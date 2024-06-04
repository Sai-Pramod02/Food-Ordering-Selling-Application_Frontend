import 'package:flutter/material.dart';
import ' api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RenewMembershipPage extends StatelessWidget {
  Future<void> _renewMembership(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String phone = prefs.getString('phoneNumber') ?? '';
   // await APIService.renewMembership(phone);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Membership renewed successfully')));

    Navigator.of(context).pop(); // Navigate back to the profile page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Renew Membership')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _renewMembership(context),
          child: Text('Renew Membership'),
        ),
      ),
    );
  }
}
