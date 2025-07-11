import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_manager.dart';
import 'order_service.dart';
import 'postcode_service.dart';
import 'order_tracking_screen.dart';
import 'guest_order_storage.dart';
// TODO: Replace with the actual import if NotificationService exists elsewhere
class NotificationService {
  static void startListeningForOrderUpdates(String orderId) {
    // Stub implementation: add your notification logic here
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartManager _cartManager = CartManager();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();

  // Controllers
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  // Guest user controllers
  final TextEditingController _guestNameController = TextEditingController();
  final TextEditingController _guestEmailController = TextEditingController();

  // Loading states
  bool _isPlacingOrder = false;
  bool _isLoadingAddress = false;

  // User state helpers
  bool get _isLoggedIn => FirebaseAuth.instance.currentUser != null;
  User? get _currentUser => FirebaseAuth.instance.currentUser;

  // Minimum order amount
  static const double minimumOrderAmount = 15.0;

  @override
  void initState() {
    super.initState();
    _cartManager.addListener(_updateUI);

    // Pre-fill user email if logged in
    if (_isLoggedIn && _currentUser?.email != null) {
      _guestEmailController.text = _currentUser!.email!;
    }
  }

  @override
  void dispose() {
    _cartManager.removeListener(_updateUI);
    _addressController.dispose();
    _instructionsController.dispose();
    _phoneController.dispose();
    _postcodeController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _guestNameController.dispose();
    _guestEmailController.dispose();
    super.dispose();
  }

  void _updateUI() {
    if (mounted) {
      setState(() {});
    }
  }

  // Check if minimum order requirement is met
  bool get _isMinimumOrderMet => _cartManager.subtotal >= minimumOrderAmount;
  double get _amountNeeded => minimumOrderAmount - _cartManager.subtotal;

  // Postcode lookup method using real API
  Future<void> _lookupPostcode() async {
    final postcode = _postcodeController.text.trim();
    if (postcode.isEmpty) {
      _showErrorSnackBar('Please enter a postcode');
      return;
    }

    // Validate postcode format
    if (!PostcodeService.isValidUKPostcode(postcode)) {
      _showErrorSnackBar('Please enter a valid UK postcode (e.g., BS1 2AA)');
      return;
    }

    setState(() {
      _isLoadingAddress = true;
    });

    try {
      final addressData = await PostcodeService.lookupPostcode(postcode);

      // Update city field with API data
      _cityController.text = addressData['city'] ?? '';

      // Format postcode properly
      _postcodeController.text = PostcodeService.formatPostcode(postcode);

      // Update full address if street is filled
      _updateFullAddress();

      _showSuccessSnackBar('Postcode verified successfully!');
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      setState(() {
        _isLoadingAddress = false;
      });
    }
  }

  // Update full address when any field changes
  void _updateFullAddress() {
    if (_streetController.text.isNotEmpty &&
        _cityController.text.isNotEmpty &&
        _postcodeController.text.isNotEmpty) {
      _addressController.text =
          '${_streetController.text.trim()}, ${_cityController.text.trim()}, ${_postcodeController.text.trim()}, United Kingdom';
    }
  }

  // Helper methods for snackbars
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFE74C3C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF006A4E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Phone number validation
  bool _isValidUKPhoneNumber(String phone) {
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    return RegExp(r'^(\+44|0)[1-9]\d{8,9}$').hasMatch(cleanPhone);
  }

  // Email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2C3E50)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Your Order',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Georgia',
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isLoggedIn
                  ? const Color(0xFF27AE60)
                  : const Color(0xFFF39C12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isLoggedIn ? Icons.person : Icons.person_outline,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _isLoggedIn ? 'User' : 'Guest',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _cartManager.items.isEmpty
            ? _buildEmptyCart()
            : _buildCartContent(),
      ),
    );
  }

  Widget _buildCartContent() {
    return Column(
      children: [
        // Cart Items List
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Minimum Order Notice (if not met)
                if (!_isMinimumOrderMet)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFFD60A),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF856404),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Minimum Order Required',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF856404),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add ${_cartManager.formatCurrency(_amountNeeded)} more to reach the £15 minimum order',
                                style: const TextStyle(
                                  color: Color(0xFF856404),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Guest User Notice (if not logged in)
                if (!_isLoggedIn)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF2196F3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFF1976D2),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Ordering as Guest',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1976D2),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/login');
                              },
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  color: Color(0xFF1976D2),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You can still place orders as a guest. We\'ll send updates via phone/email.',
                          style: TextStyle(
                            color: Color(0xFF1976D2),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Cart Items
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _cartManager.items.length,
                  itemBuilder: (context, index) {
                    return _buildCartItem(_cartManager.items[index]);
                  },
                ),

                const SizedBox(height: 24),

                // Order Summary Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Summary',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Subtotal with minimum order indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Subtotal',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (!_isMinimumOrderMet)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD60A),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Min £15',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF856404),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            _cartManager.formatCurrency(_cartManager.subtotal),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _isMinimumOrderMet
                                  ? const Color(0xFF2C3E50)
                                  : const Color(0xFFE74C3C),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Service Charge
                      _buildSummaryRow(
                        'Service Charge',
                        _cartManager.formatCurrency(_cartManager.serviceCharge),
                      ),
                      const SizedBox(height: 12),

                      // Delivery Fee (only show if delivery selected)
                      if (_cartManager.orderType == 'delivery') ...[
                        _buildSummaryRow(
                          'Delivery Fee',
                          _cartManager.formatCurrency(_cartManager.deliveryFee),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Card Charge (only show if card payment selected)
                      if (_cartManager.paymentMethod == 'card') ...[
                        _buildSummaryRow(
                          'Card Processing Fee',
                          _cartManager.formatCurrency(_cartManager.cardCharge),
                        ),
                        const SizedBox(height: 12),
                      ],

                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          Text(
                            _cartManager.formatCurrency(_cartManager.total),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100), // Space for floating button
              ],
            ),
          ),
        ),

        // Bottom Checkout Button - Fixed at bottom
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isMinimumOrderMet ? _proceedToCheckout : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isMinimumOrderMet
                    ? const Color(0xFFDC143C)
                    : Colors.grey[400],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: _isMinimumOrderMet ? 4 : 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isMinimumOrderMet ? Icons.payment : Icons.block,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isMinimumOrderMet
                        ? 'Proceed to Checkout • ${_cartManager.formatCurrency(_cartManager.total)}'
                        : 'Minimum £15 Required',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFDC143C).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 60,
              color: Color(0xFFDC143C),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Add some delicious items to get started!',
            style: TextStyle(fontSize: 16, color: Color(0xFF7F8C8D)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006A4E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Browse Menu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFDC143C).withOpacity(0.1),
                  const Color(0xFFDC143C).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFDC143C).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.restaurant,
              color: Color(0xFFDC143C),
              size: 40,
            ),
          ),

          const SizedBox(width: 16),

          // Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2C3E50),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Delete Button
                    IconButton(
                      onPressed: () => _removeItem(item),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Color(0xFFE74C3C),
                        size: 20,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006A4E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF006A4E),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        item.category,
                        style: const TextStyle(
                          color: Color(0xFF006A4E),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (item.spiceLevel.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
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
                            color: _getSpiceLevelColor(item.spiceLevel),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Text(
                      _cartManager.formatCurrency(item.price),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFDC143C),
                      ),
                    ),

                    const Spacer(),

                    // Quantity Controls
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _decreaseQuantity(item),
                            icon: const Icon(Icons.remove, size: 18),
                            color: const Color(0xFF7F8C8D),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 40),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _increaseQuantity(item),
                            icon: const Icon(Icons.add, size: 18),
                            color: const Color(0xFFDC143C),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Item total
                Text(
                  'Total: ${_cartManager.formatCurrency(item.totalPrice)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
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
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFF7F8C8D);
    }
  }

  void _increaseQuantity(CartItem item) {
    _cartManager.updateQuantity(item.id, item.quantity + 1);
  }

  void _decreaseQuantity(CartItem item) {
    if (item.quantity > 1) {
      _cartManager.updateQuantity(item.id, item.quantity - 1);
    } else {
      _removeItem(item);
    }
  }

  void _removeItem(CartItem item) {
    _cartManager.removeItem(item.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} removed from cart'),
        backgroundColor: const Color(0xFF006A4E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () {
            _cartManager.addItem(
              id: item.id,
              name: item.name,
              category: item.category,
              price: item.price,
              spiceLevel: item.spiceLevel,
            );
            // Set the quantity back to what it was
            _cartManager.updateQuantity(item.id, item.quantity);
          },
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String amount, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isGreen ? const Color(0xFF4CAF50) : const Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }

  void _proceedToCheckout() {
    // Check minimum order first
    if (!_isMinimumOrderMet) {
      _showErrorSnackBar('Minimum order of £15 required');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            children: [
              // Handle bar with Bangladesh flag colors
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF006A4E), Color(0xFFDC143C)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Bangladesh flag inspired design
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF006A4E),
                              Color(0xFF008A5C),
                              Color(0xFFDC143C),
                            ],
                            stops: [0.0, 0.6, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.restaurant,
                              color: Colors.white,
                              size: 30,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Complete Your Order',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isLoggedIn
                                        ? 'Authenticated User 🇧🇩'
                                        : 'Guest Order 🇧🇩',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Guest Information Section (only for guests)
                      if (!_isLoggedIn) ...[
                        _buildCheckoutSection(
                          'Your Information',
                          Icons.person,
                          Column(
                            children: [
                              // Guest Name Field
                              TextFormField(
                                controller: _guestNameController,
                                decoration: InputDecoration(
                                  labelText: 'Full Name *',
                                  hintText: 'e.g., John Smith',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF006A4E),
                                      width: 2,
                                    ),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.person,
                                    color: Color(0xFF006A4E),
                                  ),
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Guest Email Field
                              TextFormField(
                                controller: _guestEmailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email Address *',
                                  hintText: 'e.g., john@example.com',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF006A4E),
                                      width: 2,
                                    ),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.email,
                                    color: Color(0xFF006A4E),
                                  ),
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Order Type Selection
                      _buildCheckoutSection(
                        'Order Type',
                        Icons.delivery_dining,
                        Column(
                          children: [
                            _buildOrderTypeOption(
                              'Collection',
                              'Pick up from restaurant',
                              Icons.store,
                              'collection',
                              setModalState,
                            ),
                            const SizedBox(height: 12),
                            _buildOrderTypeOption(
                              'Delivery',
                              'Delivered to your door (+£2.99)',
                              Icons.delivery_dining,
                              'delivery',
                              setModalState,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Payment Method Selection
                      _buildCheckoutSection(
                        'Payment Method',
                        Icons.payment,
                        Column(
                          children: [
                            _buildPaymentOption(
                              'Cash',
                              'Pay with cash',
                              Icons.money,
                              'cash',
                              setModalState,
                            ),
                            const SizedBox(height: 12),
                            _buildPaymentOption(
                              'Card Payment',
                              'Pay by card (+50p processing fee)',
                              Icons.credit_card,
                              'card',
                              setModalState,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Contact Information Section - Show phone for delivery OR for guests
                      if (_cartManager.orderType == 'delivery' ||
                          !_isLoggedIn) ...[
                        _buildCheckoutSection(
                          _cartManager.orderType == 'delivery'
                              ? 'Contact Information'
                              : 'Phone Number',
                          Icons.phone,
                          Column(
                            children: [
                              // Phone Number Field
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: 'Phone Number *',
                                  hintText: 'e.g., +44 7123 456789',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF006A4E),
                                      width: 2,
                                    ),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.phone,
                                    color: Color(0xFF006A4E),
                                  ),
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Delivery Address Section (only for delivery)
                      if (_cartManager.orderType == 'delivery') ...[
                        _buildCheckoutSection(
                          'Delivery Address',
                          Icons.location_on,
                          Column(
                            children: [
                              // Postcode Lookup
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: _postcodeController,
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      decoration: InputDecoration(
                                        labelText: 'Postcode *',
                                        hintText: 'e.g., BS1 2AA',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF006A4E),
                                            width: 2,
                                          ),
                                        ),
                                        contentPadding: const EdgeInsets.all(
                                          16,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        if (value.isNotEmpty) {
                                          _updateFullAddress();
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _isLoadingAddress
                                          ? null
                                          : _lookupPostcode,
                                      icon: _isLoadingAddress
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.search, size: 20),
                                      label: Text(
                                        _isLoadingAddress
                                            ? 'Finding...'
                                            : 'Find',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF006A4E,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Street Address
                              TextFormField(
                                controller: _streetController,
                                decoration: InputDecoration(
                                  labelText: 'Street Address *',
                                  hintText: 'e.g., 123 High Street',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF006A4E),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                                onChanged: (value) {
                                  _updateFullAddress();
                                },
                              ),
                              const SizedBox(height: 16),

                              // City
                              TextFormField(
                                controller: _cityController,
                                decoration: InputDecoration(
                                  labelText: 'City *',
                                  hintText: 'e.g., Bristol',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF006A4E),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                                onChanged: (value) {
                                  _updateFullAddress();
                                },
                              ),
                              const SizedBox(height: 12),

                              // Address Preview
                              if (_addressController.text.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF006A4E,
                                    ).withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF006A4E,
                                      ).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Delivery to:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF006A4E),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _addressController.text,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF2C3E50),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Special Instructions
                      _buildCheckoutSection(
                        'Special Instructions',
                        Icons.note_add,
                        Column(
                          children: [
                            TextFormField(
                              controller: _instructionsController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText:
                                    'Any special requests? (e.g., extra spicy, no onions...)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF006A4E),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Updated Order Summary
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF006A4E).withOpacity(0.05),
                              const Color(0xFFDC143C).withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF006A4E).withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Order Summary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildSummaryRow(
                              'Subtotal',
                              _cartManager.formatCurrency(
                                _cartManager.subtotal,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildSummaryRow(
                              'Service Charge',
                              _cartManager.formatCurrency(
                                _cartManager.serviceCharge,
                              ),
                            ),
                            if (_cartManager.orderType == 'delivery') ...[
                              const SizedBox(height: 8),
                              _buildSummaryRow(
                                'Delivery Fee',
                                _cartManager.formatCurrency(
                                  _cartManager.deliveryFee,
                                ),
                              ),
                            ],
                            if (_cartManager.paymentMethod == 'card') ...[
                              const SizedBox(height: 8),
                              _buildSummaryRow(
                                'Card Processing Fee',
                                _cartManager.formatCurrency(
                                  _cartManager.cardCharge,
                                ),
                              ),
                            ],
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total:',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                Text(
                                  _cartManager.formatCurrency(
                                    _cartManager.total,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFDC143C),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Place Order Button with loading state
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isPlacingOrder ? null : _placeOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006A4E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          child: _isPlacingOrder
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle, size: 24),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Place Order • ${_cartManager.formatCurrency(_cartManager.total)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckoutSection(String title, IconData icon, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF006A4E), Color(0xFFDC143C)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildOrderTypeOption(
    String title,
    String subtitle,
    IconData icon,
    String orderType,
    StateSetter setModalState,
  ) {
    final bool isSelected = _cartManager.orderType == orderType;

    return GestureDetector(
      onTap: () {
        _cartManager.setOrderType(orderType);
        setModalState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF006A4E).withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF006A4E) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFF006A4E) : Colors.grey,
            ),
            const SizedBox(width: 12),
            Icon(icon, color: const Color(0xFFDC143C), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF006A4E)
                          : const Color(0xFF2C3E50),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    String title,
    String subtitle,
    IconData icon,
    String paymentMethod,
    StateSetter setModalState,
  ) {
    final bool isSelected = _cartManager.paymentMethod == paymentMethod;

    return GestureDetector(
      onTap: () {
        _cartManager.setPaymentMethod(paymentMethod);
        setModalState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF006A4E).withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF006A4E) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFF006A4E) : Colors.grey,
            ),
            const SizedBox(width: 12),
            Icon(icon, color: const Color(0xFFDC143C), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF006A4E)
                          : const Color(0xFF2C3E50),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced order placement method with guest support
  void _placeOrder() async {
    // Double-check minimum order requirement
    if (!_isMinimumOrderMet) {
      _showErrorSnackBar('Minimum order of £15 required to place an order');
      return;
    }

    // Validate guest information if not logged in
    if (!_isLoggedIn) {
      if (_guestNameController.text.trim().isEmpty) {
        _showErrorSnackBar('Please enter your full name');
        return;
      }

      if (_guestEmailController.text.trim().isEmpty) {
        _showErrorSnackBar('Please enter your email address');
        return;
      }

      if (!_isValidEmail(_guestEmailController.text.trim())) {
        _showErrorSnackBar('Please enter a valid email address');
        return;
      }

      if (_phoneController.text.trim().isEmpty) {
        _showErrorSnackBar('Please enter your phone number');
        return;
      }

      if (!_isValidUKPhoneNumber(_phoneController.text.trim())) {
        _showErrorSnackBar('Please enter a valid UK phone number');
        return;
      }
    }

    // Enhanced validation for delivery orders
    if (_cartManager.orderType == 'delivery') {
      // For logged in users, still need phone for delivery
      if (_isLoggedIn && _phoneController.text.trim().isEmpty) {
        _showErrorSnackBar('Please enter your phone number for delivery');
        return;
      }

      if (_phoneController.text.trim().isNotEmpty &&
          !_isValidUKPhoneNumber(_phoneController.text.trim())) {
        _showErrorSnackBar('Please enter a valid UK phone number');
        return;
      }

      // Validate postcode
      if (_postcodeController.text.trim().isEmpty) {
        _showErrorSnackBar('Please enter your postcode');
        return;
      }

      if (!PostcodeService.isValidUKPostcode(_postcodeController.text.trim())) {
        _showErrorSnackBar('Please enter a valid UK postcode');
        return;
      }

      // Validate street address
      if (_streetController.text.trim().isEmpty) {
        _showErrorSnackBar('Please enter your street address');
        return;
      }

      // Validate city
      if (_cityController.text.trim().isEmpty) {
        _showErrorSnackBar('Please enter your city');
        return;
      }

      // Update full address
      _addressController.text =
          '${_streetController.text.trim()}, ${_cityController.text.trim()}, ${PostcodeService.formatPostcode(_postcodeController.text.trim())}, United Kingdom';
    }

    setState(() {
      _isPlacingOrder = true;
    });

    Navigator.pop(context); // Close bottom sheet

    try {
      // Convert cart items to OrderItem format
      final List<OrderItem> orderItems = _cartManager.items.map((cartItem) {
        return OrderItem(
          id: cartItem.id,
          name: cartItem.name,
          quantity: cartItem.quantity,
          price: cartItem.price,
          category: cartItem.category,
          spiceLevel: cartItem.spiceLevel,
        );
      }).toList();

      // Prepare delivery address
      String deliveryAddress;
      if (_cartManager.orderType == 'delivery') {
        deliveryAddress = _addressController.text.trim();
      } else if (_cartManager.orderType == 'collection') {
        deliveryAddress = 'Pickup - Tandoori Nights Restaurant';
      } else {
        deliveryAddress = 'Dine In - Tandoori Nights Restaurant';
      }

      // Create the order with guest support
      final orderId = await OrderService.createOrder(
        items: orderItems,
        total: _cartManager.total,
        paymentMethod: _cartManager.paymentMethod == 'cash'
            ? 'Cash'
            : 'Credit Card',
        deliveryAddress: deliveryAddress,
        orderType: _cartManager.orderType,
        specialInstructions: _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        // Guest information
        guestName: !_isLoggedIn ? _guestNameController.text.trim() : null,
        guestEmail: !_isLoggedIn ? _guestEmailController.text.trim() : null,
      );

      if (!_isLoggedIn && _phoneController.text.trim().isNotEmpty) {
        GuestOrderStorage.storeGuestOrder(
          orderId: orderId,
          phoneNumber: _phoneController.text.trim(),
          total: _cartManager.total,
        );
      }

      setState(() {
        _isPlacingOrder = false;
      });

      // Show success dialog with tracking option
      _showSuccessDialog(orderId);
    } catch (e) {
      setState(() {
        _isPlacingOrder = false;
      });

      // Show error dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: ${e.toString()}'),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _showSuccessDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon with Bangladesh colors
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF006A4E), Color(0xFF008A5C)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF006A4E).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Order Placed! 🇧🇩',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Order ID: $orderId',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF006A4E),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _cartManager.orderType == 'delivery'
                    ? 'Your order will be delivered to:\n${_addressController.text}'
                    : 'Your order is ready for collection',
                style: const TextStyle(fontSize: 16, color: Color(0xFF7F8C8D)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF006A4E).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Payment:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _cartManager.paymentMethod == 'cash'
                              ? 'Cash'
                              : 'Card',
                          style: const TextStyle(
                            color: Color(0xFF006A4E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _cartManager.formatCurrency(_cartManager.total),
                          style: const TextStyle(
                            color: Color(0xFFDC143C),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons with tracking option
              Column(
                children: [
                  // Track Order button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        NotificationService.startListeningForOrderUpdates(orderId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderTrackingScreen(
                              orderId: orderId,
                              orderPhone: _phoneController.text.trim().isEmpty
                                  ? null
                                  : _phoneController.text.trim(),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.track_changes, size: 20),
                      label: const Text('Track Your Order'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006A4E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (_isLoggedIn) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop(); // Close dialog
                              Navigator.pushNamed(context, '/order-history');
                            },
                            icon: const Icon(Icons.history, size: 20),
                            label: const Text('View Orders'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF006A4E),
                              side: const BorderSide(
                                color: Color(0xFF006A4E),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            _cartManager.clearCart();
                            Navigator.of(context).pop();
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/home',
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC143C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Back to Menu',
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
            ],
          ),
        ),
      ),
    );
  }
}
