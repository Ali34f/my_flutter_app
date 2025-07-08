class GuestOrderInfo {
  final String orderId;
  final String phoneNumber;
  final DateTime orderDate;
  final double total;

  GuestOrderInfo({
    required this.orderId,
    required this.phoneNumber,
    required this.orderDate,
    required this.total,
  });

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'phoneNumber': phoneNumber,
      'orderDate': orderDate.toIso8601String(),
      'total': total,
    };
  }

  factory GuestOrderInfo.fromJson(Map<String, dynamic> json) {
    return GuestOrderInfo(
      orderId: json['orderId'],
      phoneNumber: json['phoneNumber'],
      orderDate: DateTime.parse(json['orderDate']),
      total: json['total'],
    );
  }
}

class GuestOrderStorage {
  static GuestOrderInfo? _cachedOrder;

  /// Store guest order info in memory (for security - no persistent storage)
  static void storeGuestOrder({
    required String orderId,
    required String phoneNumber,
    required double total,
  }) {
    _cachedOrder = GuestOrderInfo(
      orderId: orderId,
      phoneNumber: phoneNumber,
      orderDate: DateTime.now(),
      total: total,
    );
  }

  /// Get stored guest order info
  static GuestOrderInfo? getStoredGuestOrder() {
    // Check if order is within last 24 hours for security
    if (_cachedOrder != null) {
      final hoursSinceOrder = DateTime.now()
          .difference(_cachedOrder!.orderDate)
          .inHours;
      if (hoursSinceOrder > 24) {
        // Clear old order info for security
        _cachedOrder = null;
        return null;
      }
      return _cachedOrder;
    }
    return null;
  }

  /// Clear stored order info
  static void clearStoredOrder() {
    _cachedOrder = null;
  }

  /// Check if guest has a recent order
  static bool hasRecentOrder() {
    return getStoredGuestOrder() != null;
  }

  /// Get order age in hours
  static int? getOrderAgeInHours() {
    final order = getStoredGuestOrder();
    if (order != null) {
      return DateTime.now().difference(order.orderDate).inHours;
    }
    return null;
  }
}
