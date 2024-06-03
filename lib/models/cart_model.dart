import 'package:flutter/material.dart';

class CartItem {
  final int itemId;
  final String name;
  final double price;
  int quantity;
  String seller_phone;

  CartItem({
    required this.itemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.seller_phone,
  });
}

class Cart extends ChangeNotifier {
  List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => _cartItems;

  void addToCart(CartItem item) {
    _cartItems.add(item);
    notifyListeners();
  }

  void removeFromCart(int itemId) {
    _cartItems.removeWhere((item) => item.itemId == itemId);
    notifyListeners();
  }

  void updateQuantity(int itemId, int quantity) {
    final itemIndex = _cartItems.indexWhere((item) => item.itemId == itemId);
    if (itemIndex != -1) {
      _cartItems[itemIndex].quantity = quantity;
      print('Updated item $itemId to $quantity');
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

  int getQuantity(int itemId) {
    final item = _cartItems.firstWhere((item) => item.itemId == itemId, orElse: () => CartItem(itemId: itemId, name: '', price: 0, quantity: 0, seller_phone: ''));
    return item.quantity;
  }
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
  String? getSellerPhone() {
    if (_cartItems.isEmpty) return null;
    return _cartItems.first.seller_phone;
  }
}
