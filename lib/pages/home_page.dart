import 'package:flutter/material.dart';
import 'package:food_buddies/components/seller_card.dart';
import 'package:food_buddies/components/seller_items.dart';
import 'package:food_buddies/pages/seller_reviews_page.dart';
import 'package:provider/provider.dart';
import 'package:food_buddies/models/cart_model.dart';
import 'package:food_buddies/pages/ api_service.dart';
import 'package:food_buddies/models/seller_item_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cart_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<SellerItemModel> sellers = [];
  late String community;

  @override
  void initState() {
    super.initState();
    fetchSellersWithItems();
  }

  Future<void> fetchSellersWithItems() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      community = prefs.getString('community') ?? '';
      print("Your community is : "+community);
      List<SellerItemModel> fetchedSellers = await APIService.getSellersWithItems(community);
      setState(() {
        sellers = fetchedSellers;
      });
    } catch (e) {
      // Handle error
      print('Error fetching sellers with items: $e');
    }
  }

  static Future<String> getPhoneNumber() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('phoneNumber') ?? '';
  }

  @override
  Widget build(BuildContext context) {
    // Get the Cart instance
    final cart = Provider.of<Cart>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        automaticallyImplyLeading: false,
      ),
      body: sellers.isEmpty
          ? Center(
        child: Text("There are no active sellers in your community"),
      )
          : ListView.builder(
        itemCount: sellers.length,
        itemBuilder: (context, index) {
          final seller = sellers[index];
          return SellerCard(
            sellerName: seller.name,
            sellerPhotoUrl: seller.photoUrl,
            allItems: seller.allItems,
            sellerRating: double.parse(seller.rating),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SellerItemsList(items: seller.allItems),
                ),
              );
            },
            onRatingPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SellerReviewsPage(sellerPhone: seller.sellerPhone), // Pass the phone number
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
