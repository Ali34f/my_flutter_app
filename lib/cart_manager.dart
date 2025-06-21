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

  double get deliveryFee => _items.isEmpty ? 0 : 3.99;

  double get tax => subtotal * 0.08; // 8% tax

  double get total => subtotal + deliveryFee + tax;

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
}
