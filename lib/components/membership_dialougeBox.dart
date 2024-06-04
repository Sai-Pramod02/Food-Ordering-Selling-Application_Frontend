import 'package:flutter/material.dart';
import '../pages/renew_membership_page.dart';
import '../pages/seller_nav_bar.dart';

class MembershipDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Membership Expired'),
      content: Text('Your membership has expired. Please renew your membership to continue.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RenewMembershipPage()),
            );
          },
          child: Text('Renew'),
        ),
      ],
    );
  }
}
