import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

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
  final String? userId; // null for guest orders
  final String? userEmail; // null for guest orders
  final bool isGuest; // to identify guest orders

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
    this.userId,
    this.userEmail,
    this.isGuest = false,
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

  // Generate secure hash for guest order verification
  static String _generateGuestOrderHash(String orderId, String phoneNumber) {
    final input = '$orderId:$phoneNumber:tandoori_nights_secret';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16); // First 16 characters
  }

  // 🔥 FIXED: Create order with guest support - No more FieldValue.serverTimestamp() issues
  static Future<String> createOrder({
    required List<OrderItem> items,
    required double total,
    required String paymentMethod,
    required String deliveryAddress,
    required String orderType,
    String? specialInstructions,
    String? phoneNumber,
    String? guestName, // For guest orders
    String? guestEmail, // For guest orders
  }) async {
    try {
      final user = _currentUser;
      final isGuestOrder = user == null;

      // Validate required fields
      if (items.isEmpty) {
        throw Exception('Order must contain at least one item.');
      }

      if (total <= 0) {
        throw Exception('Order total must be greater than zero.');
      }

      // For delivery orders, phone number is always required
      if (orderType.toLowerCase() == 'delivery' &&
          (phoneNumber == null || phoneNumber.trim().isEmpty)) {
        throw Exception('Phone number is required for delivery orders.');
      }

      // For guest orders, phone number is required
      if (isGuestOrder && (phoneNumber == null || phoneNumber.trim().isEmpty)) {
        throw Exception('Phone number is required to place an order.');
      }

      // Generate order ID with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final orderId = 'ORD-$timestamp';

      // Generate guest verification hash if needed
      String? guestVerificationHash;
      if (isGuestOrder && phoneNumber != null) {
        guestVerificationHash = _generateGuestOrderHash(orderId, phoneNumber);
      }

      // 🔥 FIXED: Use regular Timestamp instead of FieldValue.serverTimestamp()
      final now = DateTime.now();
      final nowTimestamp = Timestamp.fromDate(now);

      final orderData = {
        'id': orderId,
        'userId': user?.uid, // null for guest orders
        'userEmail': user?.email ?? guestEmail,
        'isGuest': isGuestOrder,
        'guestName': isGuestOrder ? guestName : null,
        'guestVerificationHash': guestVerificationHash,
        'items': items.map((item) => item.toMap()).toList(),
        'total': total,
        'status': 'pending',
        'paymentMethod': paymentMethod,
        'deliveryAddress': deliveryAddress,
        'orderType': orderType,
        'specialInstructions': specialInstructions,
        'phoneNumber': phoneNumber,
        'createdAt': nowTimestamp, // ✅ Safe: Regular Timestamp
        'updatedAt': nowTimestamp, // ✅ Safe: Regular Timestamp
        'orderNumber': _generateOrderNumber(),
        'estimatedDeliveryTime': Timestamp.fromDate(
          _calculateEstimatedDeliveryTime(orderType),
        ),
        // ✅ FIXED: Use regular Timestamp in trackingHistory
        'trackingHistory': [
          {
            'status': 'pending',
            'timestamp': nowTimestamp, // ✅ Safe: Regular Timestamp
            'message': 'Order received and awaiting confirmation',
          },
        ],
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

  // 🔥 NEW: Track order for guest users
  static Future<Order?> trackGuestOrder(
    String orderId,
    String phoneNumber,
  ) async {
    try {
      final doc = await _firestore
          .collection(_ordersCollection)
          .doc(orderId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;

      // Verify this is a guest order
      if (data['isGuest'] != true) {
        throw Exception('This order requires user authentication');
      }

      // Verify phone number for guest orders
      if (data['phoneNumber'] != phoneNumber) {
        throw Exception('Phone number does not match order records');
      }

      // Additional verification using hash
      final storedHash = data['guestVerificationHash'];
      final expectedHash = _generateGuestOrderHash(orderId, phoneNumber);

      if (storedHash != expectedHash) {
        throw Exception('Invalid order verification');
      }

      return _convertToOrder(data, doc.id);
    } on FirebaseException catch (e) {
      throw Exception('Firebase error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to track order: $e');
    }
  }

  // 🔥 NEW: Get order stream for tracking (works for both guest and authenticated)
  static Stream<Order?> getOrderTrackingStream(
    String orderId, {
    String? phoneNumber,
  }) {
    return _firestore
        .collection(_ordersCollection)
        .doc(orderId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            return null;
          }

          final data = snapshot.data()!;

          // If it's a guest order, verify phone number
          if (data['isGuest'] == true && phoneNumber != null) {
            if (data['phoneNumber'] != phoneNumber) {
              return null; // Phone number doesn't match
            }

            // Verify hash
            final storedHash = data['guestVerificationHash'];
            final expectedHash = _generateGuestOrderHash(orderId, phoneNumber);

            if (storedHash != expectedHash) {
              return null; // Invalid verification
            }
          }
          // If it's a user order, verify user ownership
          else if (data['isGuest'] != true) {
            final user = _currentUser;
            if (user == null || data['userId'] != user.uid) {
              return null; // Not authorized
            }
          }

          return _convertToOrder(data, snapshot.id);
        });
  }

  // Generate a human-readable order number
  static String _generateOrderNumber() {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    return 'TN$dateStr$timeStr';
  }

  // Calculate estimated delivery time
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

    return _firestore
        .collection(_ordersCollection)
        .where('userId', isEqualTo: user.uid)
        .where(
          'isGuest',
          isEqualTo: false,
        ) // Only user orders, not guest orders
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

      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('userId', isEqualTo: user.uid)
          .where('isGuest', isEqualTo: false)
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

  // 🔥 FIXED: Update order status with tracking history - Safe version
  static Future<void> updateOrderStatus(
    String orderId,
    String status, {
    String? message,
  }) async {
    try {
      // Validate status
      final validStatuses = [
        'pending',
        'confirmed',
        'preparing',
        'ready',
        'out_for_delivery',
        'delivered',
        'collected',
        'cancelled',
      ];

      if (!validStatuses.contains(status.toLowerCase())) {
        throw Exception('Invalid order status: $status');
      }

      // Get current tracking history
      final doc = await _firestore
          .collection(_ordersCollection)
          .doc(orderId)
          .get();
      if (!doc.exists) {
        throw Exception('Order not found');
      }

      final data = doc.data()!;
      final List<dynamic> currentHistory = data['trackingHistory'] ?? [];

      // 🔥 FIXED: Use regular Timestamp instead of FieldValue.serverTimestamp()
      final now = Timestamp.fromDate(DateTime.now());

      // Add new tracking entry
      currentHistory.add({
        'status': status.toLowerCase(),
        'timestamp': now, // ✅ Safe: Regular Timestamp
        'message': message ?? _getDefaultStatusMessage(status),
      });

      // Update with additional metadata
      final updateData = {
        'status': status.toLowerCase(),
        'updatedAt': now, // ✅ Safe: Regular Timestamp
        'trackingHistory': currentHistory,
      };

      // Add completion time for completed/delivered orders
      if (['delivered', 'collected'].contains(status.toLowerCase())) {
        updateData['completedAt'] = now; // ✅ Safe: Regular Timestamp
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

  static String _getDefaultStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Order received and awaiting confirmation';
      case 'confirmed':
        return 'Order confirmed and being prepared';
      case 'preparing':
        return 'Your delicious meal is being prepared';
      case 'ready':
        return 'Order is ready for pickup/delivery';
      case 'out_for_delivery':
        return 'Order is on its way to you';
      case 'delivered':
        return 'Order delivered successfully';
      case 'collected':
        return 'Order collected successfully';
      case 'cancelled':
        return 'Order has been cancelled';
      default:
        return 'Order status updated';
    }
  }

  // Get order by ID with authorization check
  static Future<Order?> getOrderById(
    String orderId, {
    String? phoneNumber,
  }) async {
    try {
      final doc = await _firestore
          .collection(_ordersCollection)
          .doc(orderId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;

      // Handle guest orders
      if (data['isGuest'] == true) {
        if (phoneNumber == null) {
          throw Exception('Phone number required for guest orders');
        }

        if (data['phoneNumber'] != phoneNumber) {
          throw Exception('Phone number does not match order records');
        }

        // Verify hash
        final storedHash = data['guestVerificationHash'];
        final expectedHash = _generateGuestOrderHash(orderId, phoneNumber);

        if (storedHash != expectedHash) {
          throw Exception('Invalid order verification');
        }
      }
      // Handle authenticated user orders
      else {
        final user = _currentUser;
        if (user == null) {
          throw Exception('User not authenticated');
        }

        if (data['userId'] != user.uid) {
          throw Exception('Unauthorized access to order');
        }
      }

      return _convertToOrder(data, doc.id);
    } on FirebaseException catch (e) {
      throw Exception('Firebase error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  // Convert Firestore data to Order object
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
        status: data['status'] ?? 'pending',
        paymentMethod: data['paymentMethod'] ?? 'Unknown',
        specialInstructions: data['specialInstructions'],
        deliveryAddress: data['deliveryAddress'] ?? 'No address provided',
        orderType: data['orderType'] ?? 'delivery',
        phoneNumber: data['phoneNumber'],
        userId: data['userId'],
        userEmail: data['userEmail'],
        isGuest: data['isGuest'] ?? false,
      );
    } catch (e) {
      return null; // Return null for invalid orders
    }
  }

  // Other existing methods remain the same...
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
      if (data['userId'] != user.uid || data['isGuest'] == true) {
        throw Exception('Unauthorized: Cannot delete this order');
      }

      // Check if order can be deleted (only allow deletion of pending/cancelled orders)
      final status = data['status'] ?? '';
      if (!['pending', 'cancelled'].contains(status)) {
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
          .where('isGuest', isEqualTo: false)
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

  // Get orders by status for current user
  static Future<List<Order>> getOrdersByStatus(String status) async {
    try {
      final user = _currentUser;
      if (user == null) {
        return [];
      }

      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('userId', isEqualTo: user.uid)
          .where('isGuest', isEqualTo: false)
          .where('status', isEqualTo: status.toLowerCase())
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

  // Get recent orders (last 30 days) for current user
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
          .where('isGuest', isEqualTo: false)
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

  // Get order statistics for current user
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
          .where('isGuest', isEqualTo: false)
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
}
