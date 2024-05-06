import 'package:flutter/material.dart';
import 'package:food_buddies/components/seller_card.dart';
import 'package:food_buddies/components/seller_items.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:food_buddies/models/cart_model.dart';

import 'cart_page.dart'; // Import Cart model

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> sellers = [
      {
        'name': 'Seller 1',
        'photoUrl': 'https://i.imgur.com/bOCEVJg.png',
        'rating': 4.2,
        'seller_phone' : '7993823191',
        'allItems': [
          {'sellerId': '1','name': 'Item 1', 'price': 100, 'description': 'Description of Item 1', 'quantity': 10, "imageUrl" :'https://i.imgur.com/bOCEVJg.png'},
          {'sellerId': '1','name': 'Item 2', 'price': 150, 'description': 'Description of Item 2', 'quantity': 5, "imageUrl" :'https://i.imgur.com/bOCEVJg.png'},
          {'sellerId': '1','name': 'Item 3', 'price': 110, 'description': 'Description of Item 3', 'quantity': 8, "imageUrl" :'https://i.imgur.com/bOCEVJg.png'},
        ],
      },
      {
        'name': 'Seller 2',
        'photoUrl': 'https://i.imgur.com/bOCEVJg.png',
        'rating': 4.5,
        'seller_phone' : '9963701830',
        'allItems': [
          {'sellerId': '2','name': 'Item 3', 'price': 120, 'description': 'Description of Item 3', 'quantity': 8, "imageUrl" :'https://i.imgur.com/bOCEVJg.png'},
          {'sellerId': '2','name': 'Item 4', 'price': 200, 'description': 'Description of Item 4', 'quantity': 15, "imageUrl" :'https://i.imgur.com/bOCEVJg.png'},
          {'sellerId': '2','name': 'Item 5', 'price': 80, 'description': 'Description of Item 5', 'quantity': 12, "imageUrl" :'https://i.imgur.com/bOCEVJg.png'},
        ],
      },
    ];

    // Get the Cart instance
    final cart = Provider.of<Cart>(context);

    if (sellers.isEmpty) {
      // Display a message or image indicating no sellers available
      return Scaffold(
        appBar: AppBar(
          title: Text('Home'),
        ),
        body: Center(
          child: Text(
            'No sellers available',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16.0,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: ListView.builder(
        itemCount: sellers.length,
        itemBuilder: (context, index) {
          final seller = sellers[index];
          return SellerCard(
            sellerName: seller['name'],
            sellerPhotoUrl: seller['photoUrl'],
            allItems: seller['allItems'],
            sellerRating: seller['rating'],
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SellerItemsList(items: seller['allItems']),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CartPage(),
            ),
          );
        },
        child: const Icon(Icons.shopping_cart),
      ),
    );
  }
}