import 'package:flutter/material.dart';

class CartItem {
  final String name;
  final double price;
  int quantity;

  CartItem({
    required this.name,
    required this.price,
    required this.quantity,
  });
}


class Cart extends ChangeNotifier {
  List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => _cartItems;



  void addToCart(CartItem item) {
    _cartItems.add(item);
    notifyListeners();
  }

  void removeFromCart(String itemName) {
    _cartItems.removeWhere((item) => item.name == itemName);
    notifyListeners();
  }

  void updateQuantity(String itemName, int quantity) {
    final itemIndex = _cartItems.indexWhere((item) => item.name == itemName);
    if (itemIndex != -1) {
      _cartItems[itemIndex].quantity = quantity;
      print('Updated item $itemName to $quantity');
    }
    notifyListeners();
  }

  double calculateTotalPrice() {
    double totalPrice = 0;
    for (var item in _cartItems) {
      totalPrice += item.price * item.quantity;
    }
    return totalPrice;
  }

  int getQuantity(String itemName) {
    final item = _cartItems.firstWhere((item) => item.name == itemName, orElse: () => CartItem(name: itemName, price: 0, quantity: 0));
    return item.quantity;
  }
}
