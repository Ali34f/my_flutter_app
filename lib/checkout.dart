import 'package:flutter/material.dart';
import 'cart_manager.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartManager _cartManager = CartManager();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cartManager.addListener(_updateUI);
    // Set default address
    _addressController.text =
        '123 High Street, Bristol BS1 2AA, United Kingdom';
  }

  @override
  void dispose() {
    _cartManager.removeListener(_updateUI);
    _addressController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _updateUI() {
    if (mounted) {
      setState(() {});
    }
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

                      // Subtotal
                      _buildSummaryRow(
                        'Subtotal',
                        _cartManager.formatCurrency(_cartManager.subtotal),
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
              onPressed: _proceedToCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC143C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Proceed to Checkout • ${_cartManager.formatCurrency(_cartManager.total)}',
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
                        child: const Row(
                          children: [
                            Icon(
                              Icons.restaurant,
                              color: Colors.white,
                              size: 30,
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Complete Your Order',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Authentic Bangladeshi Cuisine 🇧🇩',
                                    style: TextStyle(
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

                      // Address Section (only show if delivery)
                      if (_cartManager.orderType == 'delivery') ...[
                        _buildCheckoutSection(
                          'Delivery Address',
                          Icons.location_on,
                          Column(
                            children: [
                              TextFormField(
                                controller: _addressController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText: 'Enter your full address...',
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

                      // Place Order Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _placeOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006A4E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          child: Row(
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

  void _placeOrder() {
    // Validate delivery address if delivery is selected
    if (_cartManager.orderType == 'delivery' &&
        _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a delivery address'),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    Navigator.pop(context); // Close bottom sheet

    // Show success dialog with Bangladesh theme
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
                          'Order Type:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _cartManager.orderType == 'delivery'
                              ? 'Delivery'
                              : 'Collection',
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _cartManager.clearCart();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006A4E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back to Menu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
