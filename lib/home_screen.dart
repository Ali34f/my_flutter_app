import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reservation.dart';
import 'info.dart';
import 'cart_manager.dart';
import 'order_history.dart';
import 'checkout.dart';
import 'menu_service.dart';
import 'order_tracking_screen.dart';

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
    _selectedBottomIndex = 0;
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

  // Method to add setmeal to cart
  void _addSetMealToCart(
    String setmealName,
    String curryName,
    String sideName,
    String drinkName,
    double totalPrice,
  ) {
    final String id = 'setmeal_${DateTime.now().millisecondsSinceEpoch}';
    final String combinedName =
        '$setmealName (${curryName} + ${sideName} + ${drinkName})';

    _cartManager.addItem(
      id: id,
      name: combinedName,
      category: 'SetMeal',
      price: totalPrice,
      spiceLevel: '',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'SetMeal added to cart! 🛒',
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

  // Method to add complete curry dish to cart
  void _addCurryDishToCart(
    String curryType,
    String protein,
    String side,
    double totalPrice,
    String spiceLevel,
  ) {
    final String id = 'curry_${DateTime.now().millisecondsSinceEpoch}';
    final String combinedName = '$protein $curryType with $side';

    _cartManager.addItem(
      id: id,
      name: combinedName,
      category: 'Curries',
      price: totalPrice,
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
                '$combinedName added to cart! 🛒',
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

  // Check if this is a SetMeal item
  bool _isSetMeal(String category, String name) {
    return category.toLowerCase().contains('setmeal') ||
        name.toLowerCase().contains('setmeal');
  }

  // Check if this is a curry item that needs protein and side selection
  bool _isCurryItem(String category, String name) {
    // If it's not a curry-related category, return false
    if (!category.toLowerCase().contains('curries') &&
        !category.toLowerCase().contains('curry') &&
        !category.toLowerCase().contains('house specials') &&
        !category.toLowerCase().contains('vegetarian') &&
        !category.toLowerCase().contains('balti')) {
      return false;
    }

    // Smart detection: if an item doesn't have variants with different proteins,
    // it's probably a standalone dish that shouldn't use curry interface
    if (category.toLowerCase().contains('house specials')) {
      final categoryItems = MenuService.getItemsByCategory(category);
      final curryType = _extractCurryType(name);

      // Count how many different proteins exist for this curry type
      final proteinCount = categoryItems.where((item) {
        final itemCurryType = _extractCurryType(item.name);
        return itemCurryType.toLowerCase() == curryType.toLowerCase();
      }).length;

      // If only 1 variant exists, it's probably a standalone dish
      if (proteinCount <= 1) {
        return false;
      }
    }

    return true;
  }

  // Extract curry type from item name (e.g., "Chicken Korma" -> "Korma")
  String _extractCurryType(String itemName) {
    final commonProteins = [
      'chicken',
      'lamb',
      'beef',
      'prawn',
      'king prawn',
      'fish',
      'vegetable',
      'paneer',
    ];
    String curryType = itemName.toLowerCase();

    for (final protein in commonProteins) {
      if (curryType.startsWith(protein)) {
        curryType = curryType.replaceFirst(protein, '').trim();
        break;
      }
    }

    return curryType.isNotEmpty ? curryType : itemName;
  }

  // Get available proteins for a curry type
  List<Map<String, dynamic>> _getAvailableProteins(
    String curryType,
    String category,
  ) {
    if (category.toLowerCase().contains('curries')) {
      return [
        {'name': 'Chicken', 'price': 11.50, 'spiceLevel': 'mild'},
        {'name': 'Lamb', 'price': 12.50, 'spiceLevel': 'mild'},
      ];
    }

    if (category.toLowerCase().contains('seafood')) {
      return [
        {'name': 'Prawn', 'price': 12.50, 'spiceLevel': 'mild'},
        {'name': 'King Prawn', 'price': 18.95, 'spiceLevel': 'mild'},
      ];
    }
    final items = MenuService.getItemsByCategory(category);
    final proteins = <Map<String, dynamic>>[];

    // Special handling for seafood - show all seafood options for any seafood curry
    if (category.toLowerCase().contains('seafood')) {
      final Set<String> addedProteins = {}; // Prevent duplicates

      for (final item in items) {
        if (item.name.toLowerCase().contains('curry') ||
            item.name.toLowerCase().contains('masala') ||
            item.name.toLowerCase().contains('korma') ||
            item.name.toLowerCase().contains('madras')) {
          final extractedType = _extractCurryType(item.name);
          final protein = item.name
              .toLowerCase()
              .replaceAll(extractedType.toLowerCase(), '')
              .trim();

          if (protein.isNotEmpty && !addedProteins.contains(protein)) {
            addedProteins.add(protein);
            proteins.add({
              'name': _capitalizeFirst(protein),
              'price': item.price,
              'spiceLevel': item.spiceLevel,
            });
          }
        }
      }

      // If no curry-like items found, create a default protein from the clicked item
      if (proteins.isEmpty) {
        final extractedType = _extractCurryType(curryType);
        final protein = curryType
            .toLowerCase()
            .replaceAll(extractedType.toLowerCase(), '')
            .trim();
        if (protein.isNotEmpty) {
          // Find the price from the original item
          final originalItem = items.firstWhere(
            (item) => item.name.toLowerCase().contains(curryType.toLowerCase()),
            orElse: () => items.first,
          );
          proteins.add({
            'name': _capitalizeFirst(protein),
            'price': originalItem.price,
            'spiceLevel': originalItem.spiceLevel,
          });
        }
      }
    } else {
      // Original logic for other categories
      for (final item in items) {
        final extractedType = _extractCurryType(item.name);
        if (extractedType.toLowerCase().contains(curryType.toLowerCase())) {
          final protein = item.name
              .toLowerCase()
              .replaceAll(extractedType.toLowerCase(), '')
              .trim();
          if (protein.isNotEmpty) {
            proteins.add({
              'name': _capitalizeFirst(protein),
              'price': item.price,
              'spiceLevel': item.spiceLevel,
            });
          }
        }
      }
    }

    return proteins;
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Check if this is a seafood curry that needs curry selection interface
  bool _isSeafoodCurry(String category, String name) {
    return category.toLowerCase().contains('seafood') &&
        (name.toLowerCase().contains('curry') ||
            name.toLowerCase().contains('masala') ||
            name.toLowerCase().contains('korma') ||
            name.toLowerCase().contains('madras'));
  }

  // Show SetMeal selection interface
  void _showSetMealSelection(
    BuildContext context,
    String setmealName,
    String description,
    String category,
    double basePrice,
  ) {
    // Get available options
    final curries = MenuService.getItemsByCategory('Curries');
    // Fixed options for sides - only Plain Naan and Pilau Rice
    final sideOptions = [
      {'name': 'Plain Naan', 'price': 0.0},
      {'name': 'Pilau Rice', 'price': 0.0},
    ];
    final drinks = MenuService.getAllItems()
        .where(
          (item) =>
              item.sizeOrType.contains('330ml') ||
              item.name.toLowerCase().contains('330ml'),
        )
        .toList();

    // Selection state
    String? selectedCurry;
    String? selectedSide;
    String? selectedDrink;
    final double fixedTotalPrice =
        16.00; // Fixed price regardless of selections

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool canAddToCart =
                selectedCurry != null &&
                selectedSide != null &&
                selectedDrink != null;

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
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
                              // SetMeal Header
                              Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFDC143C),
                                          Color(0xFFE74C3C),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: const Icon(
                                      Icons.set_meal,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          setmealName,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF2C3E50),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Choose your perfect combination',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF7F8C8D),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              if (description.isNotEmpty) ...[
                                Text(
                                  description,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF7F8C8D),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Step 1: Choose Curry
                              _buildSetMealListSection(
                                'Choose Your Curry',
                                Icons.restaurant,
                                curries
                                    .map(
                                      (item) => {
                                        'name': item.name,
                                        'price': 0.0,
                                      },
                                    )
                                    .toList(),
                                selectedCurry,
                                (String name) {
                                  setModalState(() {
                                    selectedCurry = name;
                                  });
                                },
                              ),

                              const SizedBox(height: 20),

                              // Step 2: Choose Side (Only Plain Naan or Pilau Rice)
                              _buildSetMealListSection(
                                'Choose Rice or Naan',
                                Icons.rice_bowl,
                                sideOptions,
                                selectedSide,
                                (String name) {
                                  setModalState(() {
                                    selectedSide = name;
                                  });
                                },
                              ),

                              const SizedBox(height: 20),

                              // Step 3: Choose Drink
                              _buildSetMealListSection(
                                'Choose Your Drink',
                                Icons.local_drink,
                                drinks
                                    .map(
                                      (item) => {
                                        'name': item.name,
                                        'price': 0.0,
                                      },
                                    )
                                    .toList(),
                                selectedDrink,
                                (String name) {
                                  setModalState(() {
                                    selectedDrink = name;
                                  });
                                },
                              ),

                              const SizedBox(height: 32),

                              // Summary and Total
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFDC143C,
                                    ).withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Your SetMeal Summary',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    if (selectedCurry != null)
                                      _buildSummaryItem(
                                        'Curry:',
                                        selectedCurry!,
                                        0.0,
                                      ),
                                    if (selectedSide != null)
                                      _buildSummaryItem(
                                        'Side:',
                                        selectedSide!,
                                        0.0,
                                      ),
                                    if (selectedDrink != null)
                                      _buildSummaryItem(
                                        'Drink:',
                                        selectedDrink!,
                                        0.0,
                                      ),
                                    const Divider(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Total Price:',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF2C3E50),
                                          ),
                                        ),
                                        Text(
                                          '£${fixedTotalPrice.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFFDC143C),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Add to Cart button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: canAddToCart
                                      ? () {
                                          Navigator.pop(context);
                                          _addSetMealToCart(
                                            setmealName,
                                            selectedCurry!,
                                            selectedSide!,
                                            selectedDrink!,
                                            fixedTotalPrice,
                                          );
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: canAddToCart
                                        ? const Color(0xFFDC143C)
                                        : Colors.grey[400],
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: canAddToCart ? 3 : 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.shopping_cart_outlined,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        canAddToCart
                                            ? 'Add SetMeal to Cart - £${fixedTotalPrice.toStringAsFixed(2)}'
                                            : 'Please make all selections',
                                        style: const TextStyle(
                                          fontSize: 16,
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
                );
              },
            );
          },
        );
      },
    );
  }

  // Show curry selection interface (protein + side)
  void _showCurrySelection(
    BuildContext context,
    String curryType,
    String description,
    String category,
  ) {
    final availableProteins = _getAvailableProteins(curryType, category);

    // Fixed side options
    final sideOptions = [
      {'name': 'Plain Rice', 'price': 0.0},
      {'name': 'Pilau Rice', 'price': 0.0},
      {'name': 'Plain Naan', 'price': 0.0},
      {'name': 'Chips', 'price': 0.0},
      {'name': 'Cheese Naan', 'price': 2.10},
      {'name': 'Chilli Naan', 'price': 2.10},
      {'name': 'Coconut Rice', 'price': 2.10},
      {'name': 'Keema Naan', 'price': 2.10},
      {'name': 'Keema Rice', 'price': 2.10},
      {'name': 'Peshwari Naan', 'price': 2.10},
      {'name': 'Vegetable Naan', 'price': 2.10},
      {'name': 'Vegetable Rice', 'price': 2.10},
    ];

    // Selection state
    String? selectedProtein;
    String? selectedSide;
    double selectedProteinPrice = 0.0;
    String selectedSpiceLevel = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool canAddToCart = selectedProtein != null && selectedSide != null;
            double sidePrice = selectedSide != null
                ? sideOptions.firstWhere(
                        (s) => s['name'] == selectedSide,
                      )['price']
                      as double
                : 0.0;
            double totalPrice = selectedProteinPrice + sidePrice;

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
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
                              // Curry Header
                              Row(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: const Color(
                                          0xFFDC143C,
                                        ).withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: _buildCurryPopupImage(curryType),
                                    ),
                                  ),

                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _capitalizeFirst(curryType),
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF2C3E50),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Choose your curry and side',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF7F8C8D),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              if (description.isNotEmpty) ...[
                                Text(
                                  description,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF7F8C8D),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Choose Curry
                              _buildCurrySelectionSection(
                                'Choose Your Curry',
                                Icons.restaurant,
                                availableProteins,
                                selectedProtein,
                                (String name) {
                                  setModalState(() {
                                    selectedProtein = name;
                                    final protein = availableProteins
                                        .firstWhere((p) => p['name'] == name);
                                    selectedProteinPrice =
                                        protein['price'] as double;
                                    selectedSpiceLevel =
                                        protein['spiceLevel'] as String;
                                  });
                                },
                                showPrice: true,
                              ),

                              const SizedBox(height: 20),

                              // Step 2: Choose Side
                              _buildCurrySelectionSection(
                                'Choose Side',
                                Icons.rice_bowl,
                                sideOptions,
                                selectedSide,
                                (String name) {
                                  setModalState(() {
                                    selectedSide = name;
                                  });
                                },
                                showPrice: true,
                              ),

                              const SizedBox(height: 32),

                              // Summary and Total
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFDC143C,
                                    ).withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Your Order Summary',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    if (selectedProtein != null)
                                      _buildSummaryItem(
                                        'Protein:',
                                        '$selectedProtein $curryType',
                                        selectedProteinPrice,
                                      ),
                                    if (selectedSide != null)
                                      _buildSummaryItem(
                                        'Side:',
                                        selectedSide!,
                                        sidePrice,
                                      ),
                                    const Divider(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Total Price:',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF2C3E50),
                                          ),
                                        ),
                                        Text(
                                          '£${totalPrice.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFFDC143C),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Add to Cart button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: canAddToCart
                                      ? () {
                                          Navigator.pop(context);
                                          _addCurryDishToCart(
                                            curryType,
                                            selectedProtein!,
                                            selectedSide!,
                                            totalPrice,
                                            selectedSpiceLevel,
                                          );
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: canAddToCart
                                        ? const Color(0xFFDC143C)
                                        : Colors.grey[400],
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: canAddToCart ? 3 : 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.shopping_cart_outlined,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        canAddToCart
                                            ? 'Add to Cart - £${totalPrice.toStringAsFixed(2)}'
                                            : 'Please make all selections',
                                        style: const TextStyle(
                                          fontSize: 16,
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
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCurryPopupImage(String curryType) {
    print('🔍 CURRY POPUP IMAGE: curryType="$curryType"');

    final items = MenuService.getItemsByCategory('Curries');
    String? imageUrl;

    // Find the image for this curry type
    for (final item in items) {
      print('🔍 Popup checking: "${item.name}" vs "$curryType"');
      if (item.name.toLowerCase().trim() == curryType.toLowerCase().trim()) {
        imageUrl = item.imageUrl;
        print('🔍 POPUP IMAGE FOUND! Using: $imageUrl');
        break;
      }
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.asset(
        imageUrl, // This will be dynamic like 'assets/images/korma_.jpg'
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('🔍 POPUP IMAGE FAILED: $error');
          return Container(
            width: 100,
            height: 100,
            color: Colors.grey[200],
            child: const Icon(
              Icons.restaurant,
              size: 40,
              color: Color(0xFFDC143C),
            ),
          );
        },
      );
    }

    print('🔍 NO IMAGE FOUND for curryType: $curryType');
    return Container(
      width: 100,
      height: 100,
      color: Colors.grey[200],
      child: const Icon(Icons.restaurant, size: 40, color: Color(0xFFDC143C)),
    );
  }

  Widget _buildCurrySelectionSection(
    String title,
    IconData icon,
    List<Map<String, dynamic>> items,
    String? selectedItem,
    Function(String) onItemSelected, {
    bool showPrice = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFFDC143C), size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
              ),
            ),
            if (selectedItem == null)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC143C),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '1 Required',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'No items available for this selection',
              style: TextStyle(color: Color(0xFF7F8C8D)),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final itemName = item['name'] as String;
                final itemPrice = item['price'] as double;
                final isSelected = selectedItem == itemName;
                final isLastItem = index == items.length - 1;

                return GestureDetector(
                  onTap: () => onItemSelected(itemName),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFDC143C).withOpacity(0.05)
                          : Colors.white,
                      border: !isLastItem
                          ? Border(
                              bottom: BorderSide(
                                color: Colors.grey[200]!,
                                width: 1,
                              ),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFDC143C)
                                  : Colors.grey[400]!,
                              width: 2,
                            ),
                            color: isSelected
                                ? const Color(0xFFDC143C)
                                : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            itemName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFFDC143C)
                                  : const Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                        if (showPrice && itemPrice > 0)
                          Text(
                            '+£${itemPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? const Color(0xFFDC143C)
                                  : const Color(0xFF7F8C8D),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSetMealListSection(
    String title,
    IconData icon,
    List<Map<String, dynamic>> items,
    String? selectedItem,
    Function(String) onItemSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFFDC143C), size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
              ),
            ),
            if (selectedItem == null)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC143C),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '1 Required',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'No items available for this selection',
              style: TextStyle(color: Color(0xFF7F8C8D)),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final itemName = item['name'] as String;
                final isSelected = selectedItem == itemName;
                final isLastItem = index == items.length - 1;

                return GestureDetector(
                  onTap: () => onItemSelected(itemName),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFDC143C).withOpacity(0.05)
                          : Colors.white,
                      border: !isLastItem
                          ? Border(
                              bottom: BorderSide(
                                color: Colors.grey[200]!,
                                width: 1,
                              ),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFDC143C)
                                  : Colors.grey[400]!,
                              width: 2,
                            ),
                            color: isSelected
                                ? const Color(0xFFDC143C)
                                : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            itemName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFFDC143C)
                                  : const Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String item, double price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '$label $item',
              style: const TextStyle(fontSize: 14, color: Color(0xFF2C3E50)),
            ),
          ),
          if (price > 0)
            Text(
              '+£${price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7F8C8D),
              ),
            )
          else
            const Icon(Icons.check_circle, color: Color(0xFF27AE60), size: 16),
        ],
      ),
    );
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
    // Check if this is a SetMeal - if so, show special interface
    if (_isSetMeal(category, name)) {
      final variants = _getItemVariants(name, category);
      final basePrice = variants.isNotEmpty ? variants.values.first : 0.0;
      _showSetMealSelection(context, name, description, category, basePrice);
      return;
    }

    // Check if this is a curry item - if so, show curry selection interface
    if (_isCurryItem(category, name) || _isSeafoodCurry(category, name)) {
      final curryType = _extractCurryType(name);
      _showCurrySelection(context, curryType, description, category);
      return;
    }

    // Original item details code continues here...
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
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(
                                          0xFFDC143C,
                                        ).withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(19),
                                      child: _buildDetailedItemImage(
                                        name,
                                        category,
                                      ),
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
        .replaceAll('medium', 'mid')
        .replaceAll('hoy', 'hot');
  }

  // Helper method to get spice level colors
  List<Color> _getSpiceLevelColors(String spiceLevel) {
    final cleaned = _cleanSpiceLevel(spiceLevel);
    switch (cleaned) {
      case 'mild':
        return [const Color(0xFF27AE60), const Color(0xFF2ECC71)];
      case 'mid':
        return [const Color(0xFFF39C12), const Color(0xFFE67E22)];
      case 'hot':
        return [const Color(0xFFE74C3C), const Color(0xFFC0392B)];
      case 'extremely hot':
        return [const Color(0xFF8E44AD), const Color(0xFF9B59B6)];
      default:
        return [const Color(0xFF27AE60), const Color(0xFF2ECC71)];
    }
  }

  Widget _buildMenuItemImage(String name, String category) {
    final items = MenuService.getItemsByCategory(category);
    String? imageUrl;

    // For curries, get the exact image URL from Excel
    if (category.toLowerCase().contains('curries')) {
      for (final item in items) {
        if (item.name.toLowerCase().trim() == name.toLowerCase().trim()) {
          imageUrl = item.imageUrl;
          break;
        }
      }
    } else {
      // For other categories, exact name match
      for (final item in items) {
        if (item.name.toLowerCase().trim() == name.toLowerCase().trim()) {
          imageUrl = item.imageUrl;
          break;
        }
      }
    }

    // If we have an image URL, display it
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.asset(
        imageUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackIcon(category);
        },
      );
    }

    // Fallback to icon if no image
    return _buildFallbackIcon(category);
  }

  Widget _buildFallbackIcon(String category) {
    return Container(
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
      ),
      child: Icon(
        categoryIcons[categories.indexOf(category) % categoryIcons.length],
        color: const Color(0xFFDC143C),
        size: 40,
      ),
    );
  }

  Widget _buildDetailedItemImage(String name, String category) {
    final items = MenuService.getItemsByCategory(category);
    String? imageUrl;

    // For curries, use the exact image path from Excel
    if (category.toLowerCase().contains('curries')) {
      // Find the exact item in Excel to get the correct image path
      for (final item in items) {
        if (item.name.toLowerCase().trim() == name.toLowerCase().trim()) {
          imageUrl = item.imageUrl;
          break;
        }
      }
    } else {
      // For all other categories, exact name match
      for (final item in items) {
        if (item.name.toLowerCase().trim() == name.toLowerCase().trim()) {
          imageUrl = item.imageUrl;
          break;
        }
      }
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.asset(
        imageUrl,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImageFallback();
        },
      );
    }

    return _buildImageFallback();
  }

  Widget _buildImageFallback() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFDC143C).withOpacity(0.1),
            const Color(0xFFDC143C).withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant, color: const Color(0xFFDC143C), size: 60),
          const SizedBox(height: 12),
          const Text(
            'Image coming soon',
            style: TextStyle(color: Color(0xFF7F8C8D), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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

  Widget _buildCategoryNotice(String category) {
    String? notice;
    Color backgroundColor;
    Color textColor;
    Color borderColor;
    IconData icon;

    switch (category.toLowerCase()) {
      case 'curries':
      case 'house specials':
      case 'seafood':
      case 'vegetarian':
      case 'balti dishes':
        notice =
            'Served with free plain rice, pilau rice, naan or chips.\nAny other rice or naan £2.10 extra';
        backgroundColor = const Color(0xFFE8F5E8); // Light green background
        textColor = const Color(0xFF2E7D32); // Dark green text
        borderColor = const Color(0xFF4CAF50); // Medium green border
        icon = Icons.rice_bowl;
        break;

      case 'starters':
        notice = 'All starters served with mint sauce and salad';
        backgroundColor = const Color(0xFFFEEBEE); // Light red background
        textColor = const Color(0xFFC62828); // Dark red text
        borderColor = const Color(0xFFE57373); // Medium red border
        icon = Icons.restaurant;
        break;

      case 'side dishes':
        notice =
            'All vegetable dishes available as main course extra £3.50.\nAlso served with free plain rice, pilau rice, naan or chips.\nAny changes £2.10 extra';
        backgroundColor = const Color(0xFFFFF8E1); // Light orange background
        textColor = const Color(0xFFE65100); // Dark orange text
        borderColor = const Color(0xFFFFB74D); // Medium orange border
        icon = Icons.eco;
        break;

      case 'tandoori':
        notice =
            'All tandoori dishes served with plain naan, mint sauce and salad.\nAny changes of naan £2.10';
        backgroundColor = const Color(0xFFF3E5F5); // Light purple background
        textColor = const Color(0xFF6A1B9A); // Dark purple text
        borderColor = const Color(0xFF9C27B0); // Medium purple border
        icon = Icons.local_fire_department;
        break;

      default:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: borderColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: textColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              notice,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
          Icon(Icons.info_outline, color: textColor.withOpacity(0.6), size: 16),
        ],
      ),
    );
  }

  Widget _buildMenuItems(String category) {
    final allItems = MenuService.getItemsByCategory(category);

    // Group items by name to combine variants
    final Map<String, List<dynamic>> groupedItems = {};
    for (final item in allItems) {
      String key;

      // For curry categories, group by curry type instead of full name
      // Exception: Seafood shows individual items but still has curry selection
      if (_isCurryItem(category, item.name) &&
          !category.toLowerCase().contains('seafood')) {
        key = _extractCurryType(item.name).toLowerCase().trim();
      } else if (category.toLowerCase().contains('house specials')) {
        // Smart grouping: group items that have the same curry base
        final curryType = _extractCurryType(item.name);
        final baseName = curryType.toLowerCase().trim();

        // Check if multiple items share the same curry base
        final categoryItems = MenuService.getItemsByCategory(category);
        final similarItems = categoryItems.where((otherItem) {
          final otherCurryType = _extractCurryType(otherItem.name);
          return otherCurryType.toLowerCase().trim() == baseName;
        }).length;

        // If multiple items share the same base, group them
        if (similarItems > 1) {
          key = baseName;
        } else {
          key = item.name.toLowerCase().trim();
        }
      } else {
        key = item.name.toLowerCase().trim();
      }

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
        itemCount: groupedItems.length + 1, // +1 for the notice
        itemBuilder: (context, index) {
          // First item is the category notice
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildCategoryNotice(category),
            );
          }

          // Adjust index for actual menu items
          final actualIndex = index - 1;
          final itemGroup = groupedItems.values.elementAt(actualIndex);
          final firstItem = itemGroup.first;

          // Get the price range for display
          final prices = itemGroup.map((item) => item.price).toList();
          prices.sort();
          final priceDisplay = prices.length > 1
              ? 'From £${prices.first.toStringAsFixed(2)}'
              : '£${prices.first.toStringAsFixed(2)}';

          // For curry items, use the curry type as the display name
          // For curry items, use the curry type as the display name
          // Exception: Seafood shows full item names
          String displayName;
          if (_isCurryItem(category, firstItem.name) &&
              !category.toLowerCase().contains('seafood')) {
            displayName = _capitalizeFirst(_extractCurryType(firstItem.name));
          } else if (category.toLowerCase().contains('house specials')) {
            // Check if this is a grouped item
            final curryType = _extractCurryType(firstItem.name);
            final baseName = curryType.toLowerCase().trim();

            final categoryItems = MenuService.getItemsByCategory(category);
            final similarItems = categoryItems.where((otherItem) {
              final otherCurryType = _extractCurryType(otherItem.name);
              return otherCurryType.toLowerCase().trim() == baseName;
            }).length;

            if (similarItems > 1) {
              displayName = _capitalizeFirst(curryType);
            } else {
              displayName = firstItem.name;
            }
          } else {
            displayName = firstItem.name;
          }

          return _buildEnhancedMenuItem(
            displayName,
            firstItem.description ?? '',
            priceDisplay,
            firstItem.spiceLevel ?? '',
            firstItem.category,
            firstItem.isVeg ?? false,
          );
        },
      ),
    );
    // Defensive: in case something goes wrong, always return a widget
    // (This line should never be reached, but is required for non-nullable return)
    // return const SizedBox.shrink();
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
                  // Consistent image layout for ALL categories
                  Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: const Color(0xFFDC143C).withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _buildMenuItemImage(name, category),
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

                  // Enhanced Food Info - CONSISTENT layout for ALL categories
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

                        // Price and action row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Show price in the same position for ALL categories
                            Text(
                              priceDisplay,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFDC143C),
                              ),
                            ),
                            const SizedBox(width: 4),

                            // Spice level badge
                            if (spiceLevel.isNotEmpty &&
                                cleanedSpiceLevel.isNotEmpty &&
                                cleanedSpiceLevel != 'none')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getSpiceLevelColors(
                                    spiceLevel,
                                  )[0].withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getSpiceLevelColors(spiceLevel)[0],
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  cleanedSpiceLevel,
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    color: _getSpiceLevelColors(spiceLevel)[0],
                                  ),
                                ),
                              ),

                            const Spacer(),

                            // View Details Button - Special text for SetMeal
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
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                elevation: 4,
                                minimumSize: const Size(50, 28),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isSetMeal(category, name)
                                        ? Icons.set_meal
                                        : (_isCurryItem(category, name) ||
                                              _isSeafoodCurry(category, name))
                                        ? Icons.restaurant
                                        : Icons.info_outline,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    _isSetMeal(category, name)
                                        ? 'Build'
                                        : (_isCurryItem(category, name) ||
                                              _isSeafoodCurry(category, name))
                                        ? 'Choose'
                                        : 'View',
                                    style: const TextStyle(
                                      fontSize: 10,
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
                      'Authentic Bangladeshi Cuisine',
                      style: TextStyle(
                        fontSize: 11.5,
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
    final bool isSelected = _selectedBottomIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          // Temporarily set the selected index
          setState(() {
            _selectedBottomIndex = index;
          });

          if (index == 1) {
            // Navigate to reservation screen
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ReservationScreen(),
              ),
            );
            // Always reset to menu (index 0) after returning
            if (mounted) {
              setState(() {
                _selectedBottomIndex = 0;
              });
            }
          } else if (index == 2) {
            // Navigate to contact screen
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const InfoScreen()),
            );
            // Always reset to menu (index 0) after returning
            if (mounted) {
              setState(() {
                _selectedBottomIndex = 0;
              });
            }
          }
          // If index == 0 (Menu), do nothing as we're already on the menu screen
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
              padding: const EdgeInsets.symmetric(vertical: 16),
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
                  Icons.track_changes,
                  'Track Order',
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrderTrackingScreen(),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrderHistoryScreen(),
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
                size: 22,
              ),
              label: Text(
                isGuest ? 'Exit' : 'Logout',
                style: const TextStyle(
                  color: Color(0xFFF4D03F),
                  fontSize: 16,
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
                  vertical: 16,
                  horizontal: 24,
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        hoverColor: Colors.white.withOpacity(0.05),
        splashColor: Colors.white.withOpacity(0.1),
      ),
    );
  }
}
