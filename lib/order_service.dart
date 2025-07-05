import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Order Model Classes
class OrderItem {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final String category;
  final String spiceLevel;

  OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.category,
    required this.spiceLevel,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'price': price,
      'category': category,
      'spiceLevel': spiceLevel,
    };
  }

  // Create from Map (from Firestore)
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      quantity: (map['quantity'] ?? 1).toInt(),
      price: (map['price'] ?? 0.0).toDouble(),
      category: map['category'] ?? '',
      spiceLevel: map['spiceLevel'] ?? '',
    );
  }
}

class Order {
  final String id;
  final DateTime date;
  final List<OrderItem> items;
  final double total;
  final String status;
  final String paymentMethod;
  final String? specialInstructions;
  final String deliveryAddress;
  final String orderType; // 'delivery', 'collection', 'dine-in'
  final String? phoneNumber;

  Order({
    required this.id,
    required this.date,
    required this.items,
    required this.total,
    required this.status,
    required this.paymentMethod,
    this.specialInstructions,
    required this.deliveryAddress,
    required this.orderType,
    this.phoneNumber,
  });

  double get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
}

class OrderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection name
  static const String _ordersCollection = 'orders';

  // Get current user safely
  static User? get _currentUser => _auth.currentUser;

  // Check if user is authenticated
  static bool get isUserAuthenticated => _currentUser != null;

  // 🔥 UPDATED: Save order to Firestore with phone number support
  static Future<String> createOrder({
    required List<OrderItem> items,
    required double total,
    required String paymentMethod,
    required String deliveryAddress,
    required String orderType,
    String? specialInstructions,
    String? phoneNumber,
  }) async {
    try {
      final user = _currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please log in first.');
      }

      // Validate required fields
      if (items.isEmpty) {
        throw Exception('Order must contain at least one item.');
      }

      if (total <= 0) {
        throw Exception('Order total must be greater than zero.');
      }

      // Validate phone number for delivery orders
      if (orderType.toLowerCase() == 'delivery' &&
          (phoneNumber == null || phoneNumber.trim().isEmpty)) {
        throw Exception('Phone number is required for delivery orders.');
      }

      // Generate order ID with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final orderId = 'ORD-$timestamp';

      // 🔥 UPDATED: Create order data with phone number
      final orderData = {
        'id': orderId,
        'userId': user.uid,
        'userEmail': user.email ?? 'unknown@email.com',
        'items': items.map((item) => item.toMap()).toList(),
        'total': total,
        'status': 'In Progress',
        'paymentMethod': paymentMethod,
        'deliveryAddress': deliveryAddress,
        'orderType': orderType,
        'specialInstructions': specialInstructions,
        'phoneNumber': phoneNumber, // 🔥 NEW: Added phone number field
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        // 🔥 NEW: Additional metadata for better tracking
        'orderNumber': _generateOrderNumber(),
        'estimatedDeliveryTime': _calculateEstimatedDeliveryTime(orderType),
      };

      // Save to Firestore with custom document ID
      await _firestore
          .collection(_ordersCollection)
          .doc(orderId)
          .set(orderData);

      return orderId;
    } on FirebaseException catch (e) {
      throw Exception('Firebase error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // 🔥 NEW: Generate a human-readable order number
  static String _generateOrderNumber() {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    return 'TN$dateStr$timeStr';
  }

  // 🔥 NEW: Calculate estimated delivery time
  static DateTime _calculateEstimatedDeliveryTime(String orderType) {
    final now = DateTime.now();
    switch (orderType.toLowerCase()) {
      case 'delivery':
        return now.add(const Duration(minutes: 45)); // 45 minutes for delivery
      case 'collection':
        return now.add(
          const Duration(minutes: 25),
        ); // 25 minutes for collection
      case 'dine-in':
        return now.add(const Duration(minutes: 20)); // 20 minutes for dine-in
      default:
        return now.add(const Duration(minutes: 30)); // Default 30 minutes
    }
  }

  // Get orders for current user (Stream for real-time updates)
  static Stream<List<Order>> getUserOrdersStream() {
    final user = _currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    // Query without orderBy to avoid index requirement
    return _firestore
        .collection(_ordersCollection)
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          try {
            final orders = snapshot.docs
                .map((doc) => _convertToOrder(doc.data(), doc.id))
                .where((order) => order != null)
                .cast<Order>()
                .toList();

            // Sort in memory by date (newest first)
            orders.sort((a, b) => b.date.compareTo(a.date));

            return orders;
          } catch (e) {
            return <Order>[];
          }
        });
  }

  // Get orders for current user (one-time fetch)
  static Future<List<Order>> getUserOrders() async {
    try {
      final user = _currentUser;
      if (user == null) {
        return [];
      }

      // Query without orderBy to avoid index requirement
      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('userId', isEqualTo: user.uid)
          .get();

      final orders = snapshot.docs
          .map((doc) => _convertToOrder(doc.data(), doc.id))
          .where((order) => order != null)
          .cast<Order>()
          .toList();

      // Sort in memory by date (newest first)
      orders.sort((a, b) => b.date.compareTo(a.date));

      return orders;
    } on FirebaseException catch (_) {
      return [];
    } catch (e) {
      return [];
    }
  }

  // 🔥 ENHANCED: Update order status with better error handling
  static Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      // Validate status
      final validStatuses = [
        'In Progress',
        'Confirmed',
        'Preparing',
        'Ready',
        'Out for Delivery',
        'Delivered',
        'Completed',
        'Cancelled',
      ];

      if (!validStatuses.contains(status)) {
        throw Exception('Invalid order status: $status');
      }

      // Update with additional metadata
      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add completion time for completed/delivered orders
      if (status == 'Completed' || status == 'Delivered') {
        updateData['completedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection(_ordersCollection)
          .doc(orderId)
          .update(updateData);
    } on FirebaseException catch (e) {
      throw Exception('Firebase error updating order: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // 🔥 ENHANCED: Get order by ID with better error handling
  static Future<Order?> getOrderById(String orderId) async {
    try {
      final user = _currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore
          .collection(_ordersCollection)
          .doc(orderId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;

      // Verify the order belongs to the current user
      if (data['userId'] != user.uid) {
        throw Exception('Unauthorized access to order');
      }

      return _convertToOrder(data, doc.id);
    } on FirebaseException catch (e) {
      throw Exception('Firebase error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  // Delete order (if needed)
  static Future<void> deleteOrder(String orderId) async {
    try {
      final user = _currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // First verify the order belongs to the current user
      final doc = await _firestore
          .collection(_ordersCollection)
          .doc(orderId)
          .get();

      if (!doc.exists) {
        throw Exception('Order not found');
      }

      final data = doc.data()!;
      if (data['userId'] != user.uid) {
        throw Exception('Unauthorized: Cannot delete another user\'s order');
      }

      // Check if order can be deleted (only allow deletion of pending/cancelled orders)
      final status = data['status'] ?? '';
      if (!['In Progress', 'Cancelled'].contains(status)) {
        throw Exception('Cannot delete order with status: $status');
      }

      await _firestore.collection(_ordersCollection).doc(orderId).delete();
    } on FirebaseException catch (e) {
      throw Exception('Firebase error deleting order: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete order: $e');
    }
  }

  // Get order count for current user
  static Future<int> getUserOrderCount() async {
    try {
      final user = _currentUser;
      if (user == null) return 0;

      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('userId', isEqualTo: user.uid)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Check if user has any orders
  static Future<bool> userHasOrders() async {
    final count = await getUserOrderCount();
    return count > 0;
  }

  // Get orders by status
  static Future<List<Order>> getOrdersByStatus(String status) async {
    try {
      final user = _currentUser;
      if (user == null) {
        return [];
      }

      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: status)
          .get();

      final orders = snapshot.docs
          .map((doc) => _convertToOrder(doc.data(), doc.id))
          .where((order) => order != null)
          .cast<Order>()
          .toList();

      // Sort by date (newest first)
      orders.sort((a, b) => b.date.compareTo(a.date));

      return orders;
    } catch (e) {
      return [];
    }
  }

  // 🔥 NEW: Get recent orders (last 30 days)
  static Future<List<Order>> getRecentOrders({int days = 30}) async {
    try {
      final user = _currentUser;
      if (user == null) {
        return [];
      }

      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final cutoffTimestamp = Timestamp.fromDate(cutoffDate);

      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('userId', isEqualTo: user.uid)
          .where('createdAt', isGreaterThan: cutoffTimestamp)
          .get();

      final orders = snapshot.docs
          .map((doc) => _convertToOrder(doc.data(), doc.id))
          .where((order) => order != null)
          .cast<Order>()
          .toList();

      // Sort by date (newest first)
      orders.sort((a, b) => b.date.compareTo(a.date));

      return orders;
    } catch (e) {
      return [];
    }
  }

  // 🔥 NEW: Get order statistics
  static Future<Map<String, dynamic>> getOrderStatistics() async {
    try {
      final user = _currentUser;
      if (user == null) {
        return {
          'totalOrders': 0,
          'totalSpent': 0.0,
          'averageOrderValue': 0.0,
          'favoriteOrderType': 'delivery',
        };
      }

      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('userId', isEqualTo: user.uid)
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'totalOrders': 0,
          'totalSpent': 0.0,
          'averageOrderValue': 0.0,
          'favoriteOrderType': 'delivery',
        };
      }

      final orders = snapshot.docs;
      final totalOrders = orders.length;

      double totalSpent = 0.0;
      Map<String, int> orderTypeCounts = {};

      for (final doc in orders) {
        final data = doc.data();
        totalSpent += (data['total'] ?? 0.0).toDouble();

        final orderType = data['orderType'] ?? 'delivery';
        orderTypeCounts[orderType] = (orderTypeCounts[orderType] ?? 0) + 1;
      }

      final averageOrderValue = totalSpent / totalOrders;
      final favoriteOrderType = orderTypeCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      return {
        'totalOrders': totalOrders,
        'totalSpent': totalSpent,
        'averageOrderValue': averageOrderValue,
        'favoriteOrderType': favoriteOrderType,
      };
    } catch (e) {
      return {
        'totalOrders': 0,
        'totalSpent': 0.0,
        'averageOrderValue': 0.0,
        'favoriteOrderType': 'delivery',
      };
    }
  }

  // 🔥 UPDATED: Convert Firestore data to Order object with phone number support
  static Order? _convertToOrder(Map<String, dynamic> data, String docId) {
    try {
      // Handle timestamp conversion
      DateTime date;
      if (data['createdAt'] != null) {
        if (data['createdAt'] is Timestamp) {
          date = (data['createdAt'] as Timestamp).toDate();
        } else if (data['createdAt'] is int) {
          date = DateTime.fromMillisecondsSinceEpoch(data['createdAt']);
        } else {
          date = DateTime.now(); // Fallback
        }
      } else {
        date = DateTime.now(); // Fallback
      }

      // Convert items with error handling
      final List<OrderItem> orderItems = [];
      if (data['items'] is List) {
        final itemsList = data['items'] as List<dynamic>;
        for (final item in itemsList) {
          if (item is Map<String, dynamic>) {
            try {
              orderItems.add(OrderItem.fromMap(item));
            } catch (e) {
              // Skip invalid items instead of failing completely
              continue;
            }
          }
        }
      }

      return Order(
        id: data['id'] ?? docId,
        date: date,
        items: orderItems,
        total: (data['total'] ?? 0.0).toDouble(),
        status: data['status'] ?? 'Unknown',
        paymentMethod: data['paymentMethod'] ?? 'Unknown',
        specialInstructions: data['specialInstructions'],
        deliveryAddress: data['deliveryAddress'] ?? 'No address provided',
        orderType: data['orderType'] ?? 'delivery',
        phoneNumber: data['phoneNumber'], // 🔥 NEW: Added phone number field
      );
    } catch (e) {
      return null; // Return null for invalid orders
    }
  }
}
