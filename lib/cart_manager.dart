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

  // Order type: 'delivery' or 'collection'
  String _orderType =
      'collection'; // Default to collection (no delivery charge)

  // Payment method: 'cash' or 'card'
  String _paymentMethod = 'cash'; // Default to cash (no card charge)

  // Minimum order constants
  static const double minimumOrderValue = 15.0;

  List<CartItem> get items => List.unmodifiable(_items);
  String get orderType => _orderType;
  String get paymentMethod => _paymentMethod;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold(0, (sum, item) => sum + item.totalPrice);

  // Service charge: 75p for all orders
  double get serviceCharge => _items.isEmpty ? 0 : 0.75;

  // Delivery fee: £2.99 only if delivery is selected
  double get deliveryFee =>
      (_items.isEmpty || _orderType == 'collection') ? 0 : 2.99;

  // Card processing fee: 50p only if card payment is selected
  double get cardCharge =>
      (_items.isEmpty || _paymentMethod == 'cash') ? 0 : 0.50;

  // Total calculation
  double get total => subtotal + serviceCharge + deliveryFee + cardCharge;

  // Free delivery threshold (for future use)
  double get freeDeliveryThreshold => 25.0;

  // Check if order meets minimum
  bool get meetsMinimumOrder => subtotal >= minimumOrderValue;

  // Get remaining amount needed
  double get remainingForMinimum => minimumOrderValue - subtotal;

  // Get formatted minimum order message
  String get minimumOrderMessage {
    if (meetsMinimumOrder) {
      return 'Minimum order met ✓';
    } else {
      return 'Add ${formatCurrency(remainingForMinimum)} more to reach £${minimumOrderValue.toStringAsFixed(0)} minimum';
    }
  }

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

  void setOrderType(String type) {
    _orderType = type;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _orderType = 'collection';
    _paymentMethod = 'cash';
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
