import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'order_service.dart';
import 'order_history.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String? orderId; // If coming from checkout
  final String? orderPhone; // For guest lookup

  const OrderTrackingScreen({super.key, this.orderId, this.orderPhone});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final TextEditingController _orderIdController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? currentOrderId;
  String? currentPhone;
  bool isLoggedIn = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    isLoggedIn = OrderService.isUserAuthenticated;

    // Set initial values if provided
    if (widget.orderId != null) {
      currentOrderId = widget.orderId;
      _orderIdController.text = widget.orderId!;
    }
    if (widget.orderPhone != null) {
      currentPhone = widget.orderPhone;
      _phoneController.text = widget.orderPhone!;
    }
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: currentOrderId != null
                ? _buildOrderTracking()
                : _buildOrderLookup(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF006A4E), Color(0xFF008A5C), Color(0xFFDC143C)],
          stops: [0.0, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Track Your Order',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      isLoggedIn
                          ? 'Your delicious food journey'
                          : 'Enter details to track',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              if (currentOrderId != null)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => _resetTracking(),
                    icon: const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 26,
                    ),
                    tooltip: 'Track Different Order',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderLookup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Welcome Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF4D03F), Color(0xFFF7DC6F)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF4D03F).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.track_changes,
                    color: Color(0xFFDC143C),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Track Your Order',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2C3E50),
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Enter your order details below to see\nreal-time updates on your delicious meal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF7F8C8D),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Lookup Form
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Lookup',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 20),

                // Order ID Field
                const Text(
                  'Order ID *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _orderIdController,
                  decoration: InputDecoration(
                    hintText: 'e.g., ORD-1234567890',
                    prefixIcon: const Icon(
                      Icons.receipt_long,
                      color: Color(0xFFDC143C),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFDC143C),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),

                const SizedBox(height: 20),

                // Phone Number Field (only show for guests or if not logged in)
                if (!isLoggedIn) ...[
                  const Text(
                    'Phone Number *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Phone number used for the order',
                      prefixIcon: const Icon(
                        Icons.phone,
                        color: Color(0xFFDC143C),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFDC143C),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Track Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _trackOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC143C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: const Color(0xFFDC143C).withOpacity(0.3),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search, size: 24),
                              SizedBox(width: 12),
                              Text(
                                'Track My Order',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Info Note
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFDC143C).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFDC143C),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isLoggedIn
                              ? 'Enter your Order ID to track your order'
                              : 'Use the Order ID and phone number from your order confirmation',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF7F8C8D),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // For Logged Users
          if (isLoggedIn) _buildLoggedUserOptions(),
        ],
      ),
    );
  }

  Widget _buildLoggedUserOptions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF27AE60).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF27AE60),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Logged In User',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF27AE60),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showUserOrders(),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF27AE60),
                side: const BorderSide(color: Color(0xFF27AE60)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'View My Recent Orders',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTracking() {
    return StreamBuilder<Order?>(
      stream: OrderService.getOrderTrackingStream(
        currentOrderId!,
        phoneNumber: currentPhone,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDC143C)),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading order details...',
                  style: TextStyle(fontSize: 16, color: Color(0xFF7F8C8D)),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return _buildOrderNotFound();
        }

        final order = snapshot.data!;
        return _buildOrderDetails(order);
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(60),
                border: Border.all(color: const Color(0xFFE74C3C), width: 2),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 60,
                color: Color(0xFFE74C3C),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Error Loading Order',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6C757D),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _resetTracking(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC143C),
                      side: const BorderSide(color: Color(0xFFDC143C)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _callRestaurant(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC143C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Call Us',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails(Order order) {
    final isDelivery = order.orderType.toLowerCase() == 'delivery';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Order Header
          _buildOrderHeader(order),
          const SizedBox(height: 16),

          // Progress Tracker
          _buildProgressTracker(order.status, isDelivery),
          const SizedBox(height: 16),

          // Estimated Time
          _buildEstimatedTime(order.status, isDelivery),
          const SizedBox(height: 16),

          // Order Details
          _buildOrderDetailsCard(order),
          const SizedBox(height: 16),

          // Contact & Actions
          _buildContactActions(order),
        ],
      ),
    );
  }

  Widget _buildOrderHeader(Order order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.id.substring(order.id.length - 6).toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: £${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFDC143C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy - HH:mm').format(order.date),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                ],
              ),
              _buildStatusBadge(order.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTracker(String status, bool isDelivery) {
    final steps = isDelivery
        ? [
            'pending',
            'confirmed',
            'preparing',
            'ready',
            'out_for_delivery',
            'delivered',
          ]
        : ['pending', 'confirmed', 'preparing', 'ready', 'collected'];

    final currentIndex = steps.indexWhere(
      (step) => step == status.toLowerCase(),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDelivery ? Icons.delivery_dining : Icons.store,
                color: const Color(0xFFDC143C),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                isDelivery ? 'Delivery Progress' : 'Collection Progress',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildFullProgressSteps(steps, currentIndex),
        ],
      ),
    );
  }

  Widget _buildFullProgressSteps(List<String> steps, int currentIndex) {
    final stepLabels = {
      'pending': 'Order Received',
      'confirmed': 'Order Confirmed',
      'preparing': 'Being Prepared',
      'ready': 'Ready',
      'out_for_delivery': 'Out for Delivery',
      'delivered': 'Delivered',
      'collected': 'Collected',
    };

    final stepIcons = {
      'pending': Icons.receipt_long,
      'confirmed': Icons.check_circle,
      'preparing': Icons.restaurant,
      'ready': Icons.done_all,
      'out_for_delivery': Icons.delivery_dining,
      'delivered': Icons.home,
      'collected': Icons.shopping_bag,
    };

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isActive = index <= currentIndex;
        final isCurrent = index == currentIndex;
        final isLast = index == steps.length - 1;

        return Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isActive
                        ? (isCurrent
                              ? const Color(0xFFDC143C)
                              : const Color(0xFF27AE60))
                        : const Color(0xFFE9ECEF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    stepIcons[step] ?? Icons.help,
                    color: isActive ? Colors.white : const Color(0xFF6C757D),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    stepLabels[step] ?? step,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? const Color(0xFF2C3E50)
                          : const Color(0xFF6C757D),
                    ),
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC143C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Current',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (!isLast)
              Container(
                margin: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
                width: 2,
                height: 30,
                color: isActive
                    ? const Color(0xFF27AE60)
                    : const Color(0xFFE9ECEF),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildEstimatedTime(String status, bool isDelivery) {
    String timeText;
    IconData icon;
    Color color;

    switch (status.toLowerCase()) {
      case 'pending':
      case 'confirmed':
        timeText = 'Estimated preparation: 25-35 minutes';
        icon = Icons.schedule;
        color = const Color(0xFFF39C12);
        break;
      case 'preparing':
        timeText = 'Almost ready! 10-15 minutes remaining';
        icon = Icons.timer;
        color = const Color(0xFFE67E22);
        break;
      case 'ready':
        timeText = isDelivery ? 'Ready for delivery!' : 'Ready for collection!';
        icon = Icons.notifications_active;
        color = const Color(0xFF27AE60);
        break;
      case 'out_for_delivery':
        timeText = 'Arriving in 10-15 minutes';
        icon = Icons.local_shipping;
        color = const Color(0xFF3498DB);
        break;
      case 'delivered':
      case 'collected':
        timeText = isDelivery
            ? 'Delivered! Enjoy your meal!'
            : 'Collected! Enjoy your meal!';
        icon = Icons.celebration;
        color = const Color(0xFF27AE60);
        break;
      case 'cancelled':
        timeText = 'Order has been cancelled';
        icon = Icons.cancel;
        color = const Color(0xFFE74C3C);
        break;
      default:
        timeText = 'Status update coming soon';
        icon = Icons.info;
        color = const Color(0xFF95A5A6);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              timeText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsCard(Order order) {
    final isDelivery = order.orderType.toLowerCase() == 'delivery';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),

          // Items
          ...order.items.map((item) => _buildOrderItem(item)).toList(),

          const Divider(height: 32),

          // Address/Collection info
          Row(
            children: [
              Icon(
                isDelivery ? Icons.location_on : Icons.store,
                color: const Color(0xFFDC143C),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isDelivery ? 'Delivery to: ' : 'Collection from: ',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Expanded(
                child: Text(
                  isDelivery
                      ? order.deliveryAddress
                      : 'Tandoori Nights Restaurant',
                  style: const TextStyle(color: Color(0xFF7F8C8D)),
                ),
              ),
            ],
          ),

          if (order.specialInstructions != null &&
              order.specialInstructions!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.note, color: Color(0xFFDC143C), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Special Instructions: ',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Expanded(
                  child: Text(
                    order.specialInstructions!,
                    style: const TextStyle(color: Color(0xFF7F8C8D)),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Payment Method
          Row(
            children: [
              const Icon(Icons.payment, color: Color(0xFFDC143C), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Payment: ',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                order.paymentMethod,
                style: const TextStyle(color: Color(0xFF7F8C8D)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                if (item.spiceLevel.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getSpiceLevelColor(
                        item.spiceLevel,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getSpiceLevelColor(item.spiceLevel),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      item.spiceLevel,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getSpiceLevelColor(item.spiceLevel),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'x${item.quantity}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF7F8C8D)),
              ),
              Text(
                '£${(item.price * item.quantity).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFDC143C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getSpiceLevelColor(String spiceLevel) {
    switch (spiceLevel.toLowerCase()) {
      case 'mild':
        return const Color(0xFF27AE60);
      case 'medium':
        return const Color(0xFFF39C12);
      case 'hot':
        return const Color(0xFFDC143C);
      default:
        return const Color(0xFF7F8C8D);
    }
  }

  Widget _buildContactActions(Order order) {
    final canCancel = [
      'pending',
      'confirmed',
    ].contains(order.status.toLowerCase());

    return Column(
      children: [
        // Contact Restaurant
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Need Help?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _callRestaurant(),
                      icon: const Icon(Icons.phone, size: 20),
                      label: const Text('Call Restaurant'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27AE60),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openWhatsApp(),
                      icon: const Icon(Icons.message, size: 20),
                      label: const Text('WhatsApp'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF25D366),
                        side: const BorderSide(color: Color(0xFF25D366)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (canCancel) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _showCancelDialog(order),
                    icon: const Icon(Icons.cancel_outlined, size: 20),
                    label: const Text('Cancel Order'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFE74C3C),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Refresh Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Refresh Status'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC143C),
              side: const BorderSide(color: Color(0xFFDC143C)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String displayText;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = const Color(0xFFFFF3CD);
        textColor = const Color(0xFF856404);
        displayText = 'Order Received';
        icon = Icons.receipt_long;
        break;
      case 'confirmed':
        backgroundColor = const Color(0xFFCCE5FF);
        textColor = const Color(0xFF004085);
        displayText = 'Confirmed';
        icon = Icons.check_circle;
        break;
      case 'preparing':
        backgroundColor = const Color(0xFFFFECB3);
        textColor = const Color(0xFFB8860B);
        displayText = 'Preparing';
        icon = Icons.restaurant;
        break;
      case 'ready':
        backgroundColor = const Color(0xFFD1ECF1);
        textColor = const Color(0xFF0C5460);
        displayText = 'Ready';
        icon = Icons.done_all;
        break;
      case 'out_for_delivery':
        backgroundColor = const Color(0xFFE2E3FF);
        textColor = const Color(0xFF383D75);
        displayText = 'Out for Delivery';
        icon = Icons.delivery_dining;
        break;
      case 'delivered':
        backgroundColor = const Color(0xFFD4EDDA);
        textColor = const Color(0xFF155724);
        displayText = 'Delivered';
        icon = Icons.check_circle;
        break;
      case 'collected':
        backgroundColor = const Color(0xFFD4EDDA);
        textColor = const Color(0xFF155724);
        displayText = 'Collected';
        icon = Icons.shopping_bag;
        break;
      case 'cancelled':
        backgroundColor = const Color(0xFFF8D7DA);
        textColor = const Color(0xFF721C24);
        displayText = 'Cancelled';
        icon = Icons.cancel;
        break;
      default:
        backgroundColor = const Color(0xFFE9ECEF);
        textColor = const Color(0xFF495057);
        displayText = 'Unknown';
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            displayText,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderNotFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(60),
                border: Border.all(color: const Color(0xFFE9ECEF), width: 2),
              ),
              child: const Icon(
                Icons.search_off,
                size: 60,
                color: Color(0xFF6C757D),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Order Not Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isLoggedIn
                  ? 'Please check your Order ID and try again.'
                  : 'Please check your Order ID and phone number.\nMake sure they match your order confirmation.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6C757D),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _resetTracking(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC143C),
                      side: const BorderSide(color: Color(0xFFDC143C)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _callRestaurant(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC143C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Call Us',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Action Methods
  void _trackOrder() async {
    final orderId = _orderIdController.text.trim();
    final phone = _phoneController.text.trim();

    if (orderId.isEmpty) {
      _showErrorDialog('Please enter your Order ID');
      return;
    }

    if (!isLoggedIn && phone.isEmpty) {
      _showErrorDialog('Please enter your phone number');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Validate the order exists before setting tracking
      Order? order;

      if (isLoggedIn) {
        order = await OrderService.getOrderById(orderId);
      } else {
        order = await OrderService.getOrderById(orderId, phoneNumber: phone);
      }

      if (order != null) {
        setState(() {
          currentOrderId = orderId.toUpperCase();
          currentPhone = phone;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        _showErrorDialog('Order not found. Please check your details.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog(e.toString());
    }
  }

  void _resetTracking() {
    setState(() {
      currentOrderId = null;
      currentPhone = null;
      _orderIdController.clear();
      _phoneController.clear();
    });
  }

  void _showUserOrders() {
    // Navigate to order history for logged users
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
    );
  }

  void _callRestaurant() async {
    const phoneNumber = '+441803123456';
    final uri = Uri.parse('tel:$phoneNumber');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showInfoDialog('Call Restaurant', 'Phone: $phoneNumber');
      }
    } catch (e) {
      _showErrorDialog('Could not make call. Please dial $phoneNumber');
    }
  }

  void _openWhatsApp() async {
    const whatsappNumber = '+441803123456';
    final message = 'Hi, I need help with my order: ${currentOrderId ?? ""}';
    final whatsappUrl =
        'https://wa.me/${whatsappNumber.replaceAll('+', '')}?text=${Uri.encodeComponent(message)}';
    final uri = Uri.parse(whatsappUrl);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showInfoDialog(
          'WhatsApp',
          'WhatsApp: $whatsappNumber\n\nMessage: $message',
        );
      }
    } catch (e) {
      _showErrorDialog('Could not open WhatsApp');
    }
  }

  void _showCancelDialog(Order order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Cancel Order',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3E50),
            ),
          ),
          content: const Text(
            'Are you sure you want to cancel this order? This action cannot be undone.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Keep Order',
                style: TextStyle(color: Color(0xFF6C757D)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelOrder(order);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel Order'),
            ),
          ],
        );
      },
    );
  }

  void _cancelOrder(Order order) async {
    try {
      await OrderService.updateOrderStatus(
        order.id,
        'cancelled',
        message: 'Customer requested cancellation',
      );

      _showSuccessDialog('Order cancelled successfully');
    } catch (e) {
      _showErrorDialog('Failed to cancel order: ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFE74C3C),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC143C),
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF27AE60),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(title),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC143C),
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
