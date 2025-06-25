import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reservation.dart';
import 'info.dart';
import 'cart_manager.dart';
import 'checkout.dart';

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

  // categories
  final List<String> categories = [
    'Starters',
    'Tandoori',
    'Seafood',
    'Curries',
    'Vegetarian',
    'House Specials',
    'Balti Dishes',
    'Biryani',
    'English Dishes',
    'Side Dishes',
    'Sundries',
    'Condiments',
    'Drinks',
    'Setmeal',
  ];

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
    _tabController = TabController(length: categories.length, vsync: this);

    _bottomNavController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _drawerController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Add listener to tab controller for smooth animations
    _tabController.addListener(() {
      setState(() {});
    });

    // Add cart manager listener to update UI when cart changes
    _cartManager.addListener(_updateCartUI);
  }

  @override
  void dispose() {
    _tabController.dispose();
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

    // Check if user is anonymous (guest)
    if (currentUser.isAnonymous) {
      return 'Guest';
    }

    // Get display name or fall back to email username
    String displayName = currentUser.displayName ?? '';

    if (displayName.isNotEmpty) {
      // Return first name only
      return displayName.split(' ').first;
    }

    // Fall back to email username if no display name
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

    // Show loading
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
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();

        // Navigate to welcome screen
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();

        // Show error
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
  ) {
    // Generate a unique ID for the item
    final String id =
        '${category}_${name}_${DateTime.now().millisecondsSinceEpoch}';

    _cartManager.addItem(
      id: id,
      name: name,
      category: category,
      price: price,
      spiceLevel: spiceLevel,
    );

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$name added to cart! 🛒',
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

  // Show detailed item information in a modal bottom sheet
  void _showItemDetails(
    BuildContext context,
    String name,
    String description,
    String price,
    String spiceLevel,
    String category,
  ) {
    final double priceValue = double.tryParse(price.replaceAll('£', '')) ?? 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
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
                          // Item image placeholder
                          Container(
                            width: double.infinity,
                            height: 250,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFDC143C).withOpacity(0.1),
                                  const Color(0xFFDC143C).withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFDC143C).withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  categoryIcons[categories.indexOf(category)],
                                  color: const Color(0xFFDC143C),
                                  size: 80,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Image coming soon',
                                  style: TextStyle(
                                    color: Color(0xFF7F8C8D),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Item name and category
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF006A4E,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: const Color(0xFF006A4E),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        category,
                                        style: const TextStyle(
                                          color: Color(0xFF006A4E),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Spice level indicator
                              Column(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: spiceLevel == 'mild'
                                            ? [
                                                const Color(0xFF27AE60),
                                                const Color(0xFF2ECC71),
                                              ]
                                            : spiceLevel == 'medium'
                                            ? [
                                                const Color(0xFFF39C12),
                                                const Color(0xFFE67E22),
                                              ]
                                            : [
                                                const Color(0xFFE74C3C),
                                                const Color(0xFFC0392B),
                                              ],
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              (spiceLevel == 'mild'
                                                      ? const Color(0xFF27AE60)
                                                      : spiceLevel == 'medium'
                                                      ? const Color(0xFFF39C12)
                                                      : const Color(0xFFE74C3C))
                                                  .withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.local_fire_department,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    spiceLevel.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: spiceLevel == 'mild'
                                          ? const Color(0xFF27AE60)
                                          : spiceLevel == 'medium'
                                          ? const Color(0xFFF39C12)
                                          : const Color(0xFFE74C3C),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Description
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF7F8C8D),
                              height: 1.6,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Additional details (placeholder for future menu data)
                          const Text(
                            'Ingredients',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Full ingredient list will be available once menu data is added.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF7F8C8D),
                              fontStyle: FontStyle.italic,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Allergen information placeholder
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3CD),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFFD700),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Color(0xFF856404),
                                  size: 24,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Allergen information will be displayed here',
                                    style: TextStyle(
                                      color: Color(0xFF856404),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Price and Add to Cart section
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Price',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF7F8C8D),
                                      ),
                                    ),
                                    Text(
                                      price,
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFDC143C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Quantity selector (placeholder for now)
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {},
                                      icon: const Icon(Icons.remove),
                                      color: const Color(0xFF7F8C8D),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        '1',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {},
                                      icon: const Icon(Icons.add),
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
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _addToCart(
                                  name,
                                  category,
                                  priceValue,
                                  spiceLevel,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC143C),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shopping_cart_outlined, size: 24),
                                  SizedBox(width: 12),
                                  Text(
                                    'Add to Cart',
                                    style: TextStyle(
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),

      // Enhanced Hamburger Menu Drawer
      drawer: _buildEnhancedDrawer(),

      body: Column(
        children: [
          // Enhanced Header Section
          _buildEnhancedHeader(),

          // Enhanced Category Tabs - Fixed overflow
          _buildEnhancedCategoryTabs(),

          // Menu Items Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: categories
                  .map((category) => _buildMenuItems(category))
                  .toList(),
            ),
          ),

          // Enhanced Bottom Navigation - Fixed overflow
          _buildEnhancedBottomNavigation(),
        ],
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 55,
                height: 55,
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
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFDC143C),
                      fontFamily: 'Georgia',
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Enhanced Restaurant Info
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tandoori Nights',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Authentic Indian Cuisine',
                      style: TextStyle(
                        fontSize: 14,
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
                        size: 26,
                      ),
                    ),
                    // Cart badge
                    if (_cartManager.itemCount > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFDC143C),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            '${_cartManager.itemCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
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
          // Fixed scrollable category tabs with proper constraints
          SizedBox(
            height: 55, // Slightly increased for better touch targets
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.transparent,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFFDC143C),
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tabAlignment: TabAlignment.start,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              tabs: List.generate(categories.length, (index) {
                final isSelected = _tabController.index == index;
                return Tab(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    constraints: const BoxConstraints(
                      minWidth: 70,
                      maxWidth: 140, // Increased to fit longer category names
                      minHeight: 35,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFFDC143C), Color(0xFFE74C3C)],
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFDC143C),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFFDC143C).withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(categoryIcons[index], size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            categories[index],
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
          const SizedBox(height: 12),
          // Progress indicator
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

  Widget _buildMenuItems(String category) {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 5, // Sample items per category
        itemBuilder: (context, index) {
          return _buildEnhancedMenuItem(
            'Sample ${category} Item ${index + 1}',
            'Delicious ${category.toLowerCase()} prepared with authentic spices and traditional cooking methods that bring the true taste of India.',
            '£${(12.99 + index * 2).toStringAsFixed(2)}',
            index % 3 == 0
                ? 'mild'
                : index % 3 == 1
                ? 'medium'
                : 'hot',
            category,
          );
        },
      ),
    );
  }

  Widget _buildEnhancedMenuItem(
    String name,
    String description,
    String price,
    String spiceLevel,
    String category,
  ) {
    final double priceValue = double.tryParse(price.replaceAll('£', '')) ?? 0.0;

    return GestureDetector(
      onTap: () {
        _showItemDetails(
          context,
          name,
          description,
          price,
          spiceLevel,
          category,
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
                price,
                spiceLevel,
                category,
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced Food Image Placeholder
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
                    child: const Icon(
                      Icons.restaurant,
                      color: Color(0xFFDC143C),
                      size: 40,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Enhanced Food Info - Using Expanded to prevent overflow
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
                            // Enhanced Spice Level Indicator
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: spiceLevel == 'mild'
                                      ? [
                                          const Color(0xFF27AE60),
                                          const Color(0xFF2ECC71),
                                        ]
                                      : spiceLevel == 'medium'
                                      ? [
                                          const Color(0xFFF39C12),
                                          const Color(0xFFE67E22),
                                        ]
                                      : [
                                          const Color(0xFFE74C3C),
                                          const Color(0xFFC0392B),
                                        ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (spiceLevel == 'mild'
                                                ? const Color(0xFF27AE60)
                                                : spiceLevel == 'medium'
                                                ? const Color(0xFFF39C12)
                                                : const Color(0xFFE74C3C))
                                            .withOpacity(0.3),
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

                        // Price and action row - Fixed layout
                        Row(
                          children: [
                            Text(
                              price,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFDC143C),
                              ),
                            ),

                            const SizedBox(width: 8),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (spiceLevel == 'mild'
                                            ? const Color(0xFF27AE60)
                                            : spiceLevel == 'medium'
                                            ? const Color(0xFFF39C12)
                                            : const Color(0xFFE74C3C))
                                        .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: spiceLevel == 'mild'
                                      ? const Color(0xFF27AE60)
                                      : spiceLevel == 'medium'
                                      ? const Color(0xFFF39C12)
                                      : const Color(0xFFE74C3C),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                spiceLevel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: spiceLevel == 'mild'
                                      ? const Color(0xFF27AE60)
                                      : spiceLevel == 'medium'
                                      ? const Color(0xFFF39C12)
                                      : const Color(0xFFE74C3C),
                                ),
                              ),
                            ),

                            const Spacer(),

                            // Fixed Add Button with proper child parameter
                            ElevatedButton(
                              onPressed: () {
                                _addToCart(
                                  name,
                                  category,
                                  priceValue,
                                  spiceLevel,
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
                                  Icon(Icons.add, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'Add',
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
          constraints: const BoxConstraints(minHeight: 60, maxHeight: 80),
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

          // Handle navigation
          if (index == 1) {
            // Navigate to Reservation Screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ReservationScreen(),
              ),
            );
          } else if (index == 2) {
            // Navigate to Contact Information Screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const InfoScreen()),
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF006A4E), Color(0xFF008A5C)],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF006A4E).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : const Color(0xFF7F8C8D),
                  size: isSelected ? 22 : 20,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF7F8C8D),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
      backgroundColor: const Color(0xFF8B1538), // Darker, more muted red
      child: Column(
        children: [
          // User-friendly Profile Header - DYNAMIC VERSION
          Container(
            padding: const EdgeInsets.only(
              top: 60,
              left: 24,
              right: 24,
              bottom: 24,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF8B1538), // Darker red
                  Color(0xFFA01D48), // Slightly lighter
                ],
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
                // Softer User Avatar
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF4D03F), Color(0xFFF7DC6F)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isGuest ? Icons.person_outline : Icons.person,
                    color: const Color(0xFF8B1538),
                    size: 36,
                  ),
                ),

                const SizedBox(width: 18),

                // User Info - DYNAMIC VERSION
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getUserDisplayName(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getWelcomeMessage(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFFE8E8E8),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (isGuest) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4D03F).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFF4D03F),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'Limited Access',
                            style: TextStyle(
                              color: Color(0xFFF4D03F),
                              fontSize: 12,
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
            margin: const EdgeInsets.symmetric(horizontal: 24),
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

          // User-friendly Menu Items
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
                  Icons.calendar_today,
                  'Book a Table',
                  () {
                    Navigator.pop(context);
                    // Navigate to Reservation Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReservationScreen(),
                      ),
                    );
                  },
                ),
                // Only show Order History for logged-in users
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
                  // Navigate to Contact Information Screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const InfoScreen()),
                  );
                }),
                // Guest users see a prompt to sign up instead of order history
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

          // Enhanced Logout Button with Firebase Auth
          Container(
            margin: const EdgeInsets.all(24),
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
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                backgroundColor: Colors.transparent,
              ),
            ),
          ),

          const SizedBox(height: 16),
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
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        hoverColor: Colors.white.withOpacity(0.05),
        splashColor: Colors.white.withOpacity(0.1),
      ),
    );
  }
}
