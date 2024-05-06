import 'package:flutter/material.dart';
import 'package:food_buddies/components/quantity_selector.dart';
import 'package:provider/provider.dart';
import 'package:food_buddies/models/cart_model.dart';
import 'package:food_buddies/pages/payment_page.dart';

class CartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<Cart>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
      ),
      body: cart.cartItems.isEmpty
          ? Center(
        child: Text(
          'Cart is empty',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 16.0,
          ),
        ),
      )
          : ListView.builder(
        itemCount: cart.cartItems.length,
        itemBuilder: (context, index) {
          final item = cart.cartItems[index];
          return ListTile(
            title: Text(item.name),
            subtitle: Text('₹${item.price}'),
            trailing: SizedBox(
              width: 100.0, // Adjust the width as needed
              child: QuantitySelector(
                initialQuantity: item.quantity,
                onChanged: (quantity) {
                  if (quantity == 0) {
                    cart.removeFromCart(item.name);
                  } else {
                    cart.updateQuantity(item.name, quantity);
                  }
                },
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Total: ₹${cart.calculateTotalPrice()}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
              SizedBox(width: 20.0),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PaymentPage()),
                  );
                },
                child: Text('Place Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
