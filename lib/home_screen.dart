import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reservation.dart';
import 'info.dart';
import 'cart_manager.dart';
import 'checkout.dart';
import 'menu_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final CartManager _cartManager = CartManager();

  // Bottom navigation state
  int _selectedBottomIndex = 0;

  // Animation controllers for smooth transitions
  late AnimationController _bottomNavController;
  late AnimationController _drawerController;

  // Menu data
  List<String> categories = [];
  bool _isLoading = true;

  final List<IconData> categoryIcons = [
    Icons.restaurant,
    Icons.local_fire_department,
    Icons.set_meal,
    Icons.soup_kitchen,
    Icons.eco,
    Icons.star,
    Icons.restaurant_menu,
    Icons.rice_bowl,
    Icons.lunch_dining,
    Icons.room_service,
    Icons.inventory,
    Icons.local_grocery_store,
    Icons.local_drink,
    Icons.dinner_dining,
  ];

  @override
  void initState() {
    super.initState();
    _loadMenuData();

    _bottomNavController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _drawerController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Add cart manager listener to update UI when cart changes
    _cartManager.addListener(_updateCartUI);
  }

  Future<void> _loadMenuData() async {
    try {
      await MenuService.loadMenuData();
      setState(() {
        categories = MenuService.getCategories();
        _isLoading = false;
        _tabController = TabController(length: categories.length, vsync: this);
        _tabController.addListener(() {
          setState(() {});
        });
      });
    } catch (e) {
      print('Error loading menu data: $e');
      setState(() {
        _isLoading = false;
        categories = [];
      });
    }
  }

  @override
  void dispose() {
    if (!_isLoading && categories.isNotEmpty) {
      _tabController.dispose();
    }
    _bottomNavController.dispose();
    _drawerController.dispose();
    _cartManager.removeListener(_updateCartUI);
    super.dispose();
  }

  void _updateCartUI() {
    setState(() {});
  }

  /// Check if current user is a guest (anonymous or not logged in)
  bool _isGuestUser() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    return currentUser == null || currentUser.isAnonymous;
  }

  /// Gets the display name for the current user
  String _getUserDisplayName() {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return 'Guest';
    }

    if (currentUser.isAnonymous) {
      return 'Guest';
    }

    String displayName = currentUser.displayName ?? '';

    if (displayName.isNotEmpty) {
      return displayName.split(' ').first;
    }

    String email = currentUser.email ?? '';
    if (email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'User';
  }

  /// Gets the welcome message for the current user
  String _getWelcomeMessage() {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return 'Welcome! 🍽️';
    }

    if (currentUser.isAnonymous) {
      return 'Welcome! Browse our menu 🍽️';
    }

    return 'Welcome back! 🇧🇩';
  }

  /// Handle user logout with proper Firebase sign out
  Future<void> _handleLogout() async {
    Navigator.pop(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006A4E)),
        ),
      ),
    );

    try {
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Method to add item to cart
  void _addToCart(
    String name,
    String category,
    double price,
    String spiceLevel,
    String selectedVariant,
  ) {
    final String id =
        '${category}_${name}_${selectedVariant}_${DateTime.now().millisecondsSinceEpoch}';

    _cartManager.addItem(
      id: id,
      name: '$name ($selectedVariant)',
      category: category,
      price: price,
      spiceLevel: spiceLevel,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$name ($selectedVariant) added to cart! 🛒',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CheckoutScreen(),
                  ),
                );
              },
              child: const Text(
                'VIEW CART',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF006A4E),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Get item variants and prices
  Map<String, double> _getItemVariants(String name, String category) {
    final items = MenuService.getItemsByCategory(category);
    final variants = <String, double>{};

    for (final item in items) {
      if (item.name.toLowerCase().trim() == name.toLowerCase().trim()) {
        final variant = item.sizeOrType.isNotEmpty
            ? item.sizeOrType
            : 'Regular';
        variants[variant] = item.price;
      }
    }

    return variants.isNotEmpty ? variants : {'Regular': 0.0};
  }

  // Show detailed item information with variant selection
  void _showItemDetails(
    BuildContext context,
    String name,
    String description,
    String spiceLevel,
    String category,
    bool isVeg,
  ) {
    final variants = _getItemVariants(name, category);
    String selectedVariant = variants.keys.first;
    double selectedPrice = variants.values.first;
    int quantity = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, controller) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        width: 50,
                        height: 5,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      Expanded(
                        child: SingleChildScrollView(
                          controller: controller,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Item image placeholder with veg indicator
                              Stack(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(
                                            0xFFDC143C,
                                          ).withOpacity(0.1),
                                          const Color(
                                            0xFFDC143C,
                                          ).withOpacity(0.05),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(
                                          0xFFDC143C,
                                        ).withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          categoryIcons[categories.indexOf(
                                                category,
                                              ) %
                                              categoryIcons.length],
                                          color: const Color(0xFFDC143C),
                                          size: 60,
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Image coming soon',
                                          style: TextStyle(
                                            color: Color(0xFF7F8C8D),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Veg/Non-veg indicator
                                  Positioned(
                                    top: 16,
                                    right: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isVeg
                                            ? Colors.green
                                            : Colors.red,
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                (isVeg
                                                        ? Colors.green
                                                        : Colors.red)
                                                    .withOpacity(0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isVeg
                                                ? Icons.eco
                                                : Icons.restaurant,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isVeg ? 'VEG' : 'NON-VEG',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Item name and details
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF2C3E50),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF006A4E,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFF006A4E),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            category,
                                            style: const TextStyle(
                                              color: Color(0xFF006A4E),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Spice level indicator (only show if not empty)
                                  if (spiceLevel.isNotEmpty &&
                                      spiceLevel.toLowerCase() != 'none')
                                    Column(
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: _getSpiceLevelColors(
                                                spiceLevel,
                                              ),
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: _getSpiceLevelColors(
                                                  spiceLevel,
                                                )[0].withOpacity(0.3),
                                                blurRadius: 6,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.local_fire_department,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _cleanSpiceLevel(
                                            spiceLevel,
                                          ).toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: _getSpiceLevelColors(
                                              spiceLevel,
                                            )[0],
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Description
                              if (description.isNotEmpty) ...[
                                const Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  description,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF7F8C8D),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Size/Type Selection
                              if (variants.length > 1) ...[
                                const Text(
                                  'Size/Type Options',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: variants.entries.map((entry) {
                                    final isSelected =
                                        selectedVariant == entry.key;
                                    return GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          selectedVariant = entry.key;
                                          selectedPrice = entry.value;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFFDC143C)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFDC143C),
                                            width: 2,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              entry.key,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isSelected
                                                    ? Colors.white
                                                    : const Color(0xFFDC143C),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '£${entry.value.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: isSelected
                                                    ? Colors.white
                                                    : const Color(0xFFDC143C),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Price and Quantity section
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Price',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF7F8C8D),
                                          ),
                                        ),
                                        Text(
                                          '£${selectedPrice.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFFDC143C),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Quantity selector
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: quantity > 1
                                              ? () {
                                                  setModalState(() {
                                                    quantity--;
                                                  });
                                                }
                                              : null,
                                          icon: const Icon(
                                            Icons.remove,
                                            size: 18,
                                          ),
                                          color: quantity > 1
                                              ? const Color(0xFF7F8C8D)
                                              : Colors.grey[400],
                                        ),
                                        Container(
                                          constraints: const BoxConstraints(
                                            minWidth: 40,
                                          ),
                                          child: Text(
                                            '$quantity',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            setModalState(() {
                                              quantity++;
                                            });
                                          },
                                          icon: const Icon(Icons.add, size: 18),
                                          color: const Color(0xFFDC143C),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Add to Cart button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    // Add multiple items if quantity > 1
                                    for (int i = 0; i < quantity; i++) {
                                      _addToCart(
                                        name,
                                        category,
                                        selectedPrice,
                                        spiceLevel,
                                        selectedVariant,
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDC143C),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 3,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.shopping_cart_outlined,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'Add ${quantity > 1 ? '$quantity items' : 'to Cart'} - £${(selectedPrice * quantity).toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
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
                );
              },
            );
          },
        );
      },
    );
  }

  // Helper method to clean spice level text
  String _cleanSpiceLevel(String spiceLevel) {
    if (spiceLevel.isEmpty) return '';
    return spiceLevel
        .trim()
        .toLowerCase()
        .replaceAll('medum', 'medium')
        .replaceAll('hoy', 'hot');
  }

  // Helper method to get spice level colors
  List<Color> _getSpiceLevelColors(String spiceLevel) {
    final cleaned = _cleanSpiceLevel(spiceLevel);
    switch (cleaned) {
      case 'mild':
        return [const Color(0xFF27AE60), const Color(0xFF2ECC71)];
      case 'medium':
        return [const Color(0xFFF39C12), const Color(0xFFE67E22)];
      case 'hot':
        return [const Color(0xFFE74C3C), const Color(0xFFC0392B)];
      case 'extremely hot':
        return [const Color(0xFF8E44AD), const Color(0xFF9B59B6)];
      default:
        return [const Color(0xFF27AE60), const Color(0xFF2ECC71)];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDC143C)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Loading menu...',
                style: TextStyle(fontSize: 16, color: Color(0xFF7F8C8D)),
              ),
            ],
          ),
        ),
      );
    }

    if (categories.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No menu data available',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your menu data file',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: _buildEnhancedDrawer(),
      body: Column(
        children: [
          _buildEnhancedHeader(),
          _buildEnhancedCategoryTabs(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: categories
                  .map((category) => _buildMenuItems(category))
                  .toList(),
            ),
          ),
          _buildEnhancedBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildMenuItems(String category) {
    final allItems = MenuService.getItemsByCategory(category);

    // Group items by name to combine variants
    final Map<String, List<dynamic>> groupedItems = {};
    for (final item in allItems) {
      final key = item.name.toLowerCase().trim();
      if (!groupedItems.containsKey(key)) {
        groupedItems[key] = [];
      }
      groupedItems[key]!.add(item);
    }

    if (groupedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No items available in $category',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFFF8F9FA),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: groupedItems.length,
        itemBuilder: (context, index) {
          final itemGroup = groupedItems.values.elementAt(index);
          final firstItem = itemGroup.first;

          // Get the price range for display
          final prices = itemGroup.map((item) => item.price).toList();
          prices.sort();
          final priceDisplay = prices.length > 1
              ? 'From £${prices.first.toStringAsFixed(2)}'
              : '£${prices.first.toStringAsFixed(2)}';

          return _buildEnhancedMenuItem(
            firstItem.name,
            firstItem.description ?? '',
            priceDisplay,
            firstItem.spiceLevel ?? '',
            firstItem.category,
            firstItem.isVeg ?? false,
          );
        },
      ),
    );
  }

  Widget _buildEnhancedMenuItem(
    String name,
    String description,
    String priceDisplay,
    String spiceLevel,
    String category,
    bool isVeg,
  ) {
    final cleanedSpiceLevel = _cleanSpiceLevel(spiceLevel);

    // Check if this is Side Dishes or Drinks category - use special layout
    final bool isSpecialCategory =
        category.toLowerCase().contains('side') ||
        category.toLowerCase().contains('drink') ||
        category.toLowerCase().contains('sundries') ||
        category.toLowerCase().contains('setmeal');

    return GestureDetector(
      onTap: () {
        _showItemDetails(
          context,
          name,
          description,
          spiceLevel,
          category,
          isVeg,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              _showItemDetails(
                context,
                name,
                description,
                spiceLevel,
                category,
                isVeg,
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Conditional layout based on category
                  if (isSpecialCategory)
                    // Special layout for Side Dishes & Drinks - Price under image
                    Column(
                      children: [
                        Stack(
                          children: [
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
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: const Color(
                                    0xFFDC143C,
                                  ).withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                categoryIcons[categories.indexOf(category) %
                                    categoryIcons.length],
                                color: const Color(0xFFDC143C),
                                size: 40,
                              ),
                            ),
                            // Veg/Non-veg indicator
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: isVeg ? Colors.green : Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  isVeg ? Icons.eco : Icons.restaurant,
                                  color: Colors.white,
                                  size: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Price under the image for special categories
                        Text(
                          priceDisplay,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFDC143C),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  else
                    // Original layout for all other categories
                    Stack(
                      children: [
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
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: const Color(0xFFDC143C).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            categoryIcons[categories.indexOf(category) %
                                categoryIcons.length],
                            color: const Color(0xFFDC143C),
                            size: 40,
                          ),
                        ),
                        // Veg/Non-veg indicator
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: isVeg ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              isVeg ? Icons.eco : Icons.restaurant,
                              color: Colors.white,
                              size: 10,
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(width: 16),

                  // Enhanced Food Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2C3E50),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Enhanced Spice Level Indicator (only show if not empty)
                            if (spiceLevel.isNotEmpty &&
                                cleanedSpiceLevel.isNotEmpty &&
                                cleanedSpiceLevel != 'none')
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _getSpiceLevelColors(spiceLevel),
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getSpiceLevelColors(
                                        spiceLevel,
                                      )[0].withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.local_fire_department,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        if (description.isNotEmpty)
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF7F8C8D),
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                        const SizedBox(height: 12),

                        // Price and action row - Different for special categories
                        Row(
                          children: [
                            // Only show price here for non-special categories
                            if (!isSpecialCategory) ...[
                              Text(
                                priceDisplay,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFDC143C),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],

                            // Spice level badge
                            if (spiceLevel.isNotEmpty &&
                                cleanedSpiceLevel.isNotEmpty &&
                                cleanedSpiceLevel != 'none')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getSpiceLevelColors(
                                    spiceLevel,
                                  )[0].withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getSpiceLevelColors(spiceLevel)[0],
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  cleanedSpiceLevel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _getSpiceLevelColors(spiceLevel)[0],
                                  ),
                                ),
                              ),

                            const Spacer(),

                            // View Details Button
                            ElevatedButton(
                              onPressed: () {
                                _showItemDetails(
                                  context,
                                  name,
                                  description,
                                  spiceLevel,
                                  category,
                                  isVeg,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC143C),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                elevation: 4,
                                minimumSize: const Size(60, 32),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.info_outline, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'View',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF006A4E), // Bangladesh green
            Color(0xFF008A5C), // Slightly lighter green
            Color(0xFFDC143C), // Bangladesh red
          ],
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
              // Enhanced Hamburger Menu Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                    _drawerController.forward();
                  },
                  icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                ),
              ),

              const SizedBox(width: 12),

              // Enhanced Logo with Animation
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF4D03F), Color(0xFFF7DC6F)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF4D03F).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'T',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFDC143C),
                      fontFamily: 'Georgia',
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Enhanced Restaurant Info
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tandoori Nights',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Authentic Indian Cuisine',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFF8F9FA),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Enhanced Shopping Cart Button with Badge
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CheckoutScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    // Cart badge
                    if (_cartManager.itemCount > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFFDC143C),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '${_cartManager.itemCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedCategoryTabs() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.transparent,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFFDC143C),
              labelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tabAlignment: TabAlignment.start,
              labelPadding: const EdgeInsets.symmetric(horizontal: 3),
              tabs: List.generate(categories.length, (index) {
                final isSelected = _tabController.index == index;
                return Tab(
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 65,
                      maxWidth: 120,
                      minHeight: 32,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFFDC143C), Color(0xFFE74C3C)],
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFDC143C),
                        width: 1.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFFDC143C).withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          categoryIcons[index % categoryIcons.length],
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            categories[index].trim(),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: LinearProgressIndicator(
              value: (_tabController.index + 1) / categories.length,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFDC143C),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildEnhancedBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildEnhancedNavItem(Icons.home, 'Menu', 0),
              _buildEnhancedNavItem(Icons.calendar_today, 'Reserve', 1),
              _buildEnhancedNavItem(Icons.phone, 'Contact', 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedBottomIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedBottomIndex = index;
          });

          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ReservationScreen(),
              ),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const InfoScreen()),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF006A4E), Color(0xFF008A5C)],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF006A4E).withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF7F8C8D),
                size: isSelected ? 20 : 18,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF7F8C8D),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedDrawer() {
    final bool isGuest = _isGuestUser();

    return Drawer(
      backgroundColor: const Color(0xFF8B1538),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(
              top: 50,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF8B1538), Color(0xFFA01D48)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF4D03F), Color(0xFFF7DC6F)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isGuest ? Icons.person_outline : Icons.person,
                    color: const Color(0xFF8B1538),
                    size: 30,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getUserDisplayName(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _getWelcomeMessage(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFE8E8E8),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (isGuest) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4D03F).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFF4D03F),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'Limited Access',
                            style: TextStyle(
                              color: Color(0xFFF4D03F),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.1),
                ],
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildEnhancedDrawerItem(
                  Icons.home,
                  'Home',
                  () => Navigator.pop(context),
                ),
                _buildEnhancedDrawerItem(
                  Icons.restaurant_menu,
                  'Full Menu',
                  () => Navigator.pop(context),
                ),
                _buildEnhancedDrawerItem(
                  Icons.shopping_cart,
                  'My Cart (${_cartManager.itemCount})',
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CheckoutScreen(),
                      ),
                    );
                  },
                ),
                _buildEnhancedDrawerItem(
                  Icons.calendar_today,
                  'Book a Table',
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReservationScreen(),
                      ),
                    );
                  },
                ),
                if (!isGuest)
                  _buildEnhancedDrawerItem(Icons.history, 'Order History', () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Order history coming soon! 📋',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: const Color(0xFF006A4E),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }),
                _buildEnhancedDrawerItem(Icons.phone, 'Contact Us', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const InfoScreen()),
                  );
                }),
                if (isGuest)
                  _buildEnhancedDrawerItem(
                    Icons.person_add,
                    'Sign Up for More Features',
                    () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Sign up to access order history, favorites, and more! 🎉',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: const Color(0xFF006A4E),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          action: SnackBarAction(
                            label: 'SIGN UP',
                            textColor: const Color(0xFFF4D03F),
                            onPressed: () {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/',
                                (route) => false,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),

          Container(
            margin: const EdgeInsets.all(20),
            child: OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: Icon(
                isGuest ? Icons.exit_to_app : Icons.logout,
                color: const Color(0xFFF4D03F),
                size: 20,
              ),
              label: Text(
                isGuest ? 'Exit' : 'Logout',
                style: const TextStyle(
                  color: Color(0xFFF4D03F),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFF4D03F), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
                backgroundColor: Colors.transparent,
              ),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildEnhancedDrawerItem(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        hoverColor: Colors.white.withOpacity(0.05),
        splashColor: Colors.white.withOpacity(0.1),
      ),
    );
  }
}
