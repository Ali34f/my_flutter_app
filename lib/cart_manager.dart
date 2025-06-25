import 'package:flutter/material.dart';

// Cart Item Model
class CartItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final String spiceLevel;
  final String imageUrl;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.spiceLevel,
    this.imageUrl = '',
    this.quantity = 1,
  });

  double get totalPrice => price * quantity;
}

// Cart Manager Singleton
class CartManager extends ChangeNotifier {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0, (sum, item) => sum + item.totalPrice);

  // Updated delivery fee threshold for UK market (£25 for free delivery)
  double get deliveryFee => _items.isEmpty ? 0 : (subtotal >= 25 ? 0 : 2.99);

  // UK VAT rate is 20%
  double get tax => subtotal * 0.20;

  double get total => subtotal + deliveryFee + tax;

  // Free delivery threshold for UK market
  double get freeDeliveryThreshold => 25.0;

  void addItem({
    required String id,
    required String name,
    required String category,
    required double price,
    required String spiceLevel,
    String imageUrl = '',
  }) {
    final existingIndex = _items.indexWhere((item) => item.id == id);

    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(
        CartItem(
          id: id,
          name: name,
          category: category,
          price: price,
          spiceLevel: spiceLevel,
          imageUrl: imageUrl,
        ),
      );
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void updateQuantity(String id, int quantity) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      if (quantity <= 0) {
        removeItem(id);
      } else {
        _items[index].quantity = quantity;
        notifyListeners();
      }
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // Helper method to format currency consistently
  String formatCurrency(double amount) {
    return '£${amount.toStringAsFixed(2)}';
  }

  // Helper method to get remaining amount for free delivery
  double get remainingForFreeDelivery {
    return subtotal >= freeDeliveryThreshold
        ? 0
        : freeDeliveryThreshold - subtotal;
  }
}
