import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'register.dart';
import 'login.dart';
import 'home_screen.dart';
import 'checkout.dart';
import 'order_history.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const TandooriNightsApp());
}

class TandooriNightsApp extends StatelessWidget {
  const TandooriNightsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tandoori Nights',
      theme: ThemeData(primarySwatch: Colors.green, fontFamily: null),
      home: FutureBuilder(
        future: _initializeApp(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(child: Text('Error: ${snapshot.error}')),
              );
            }
            return const WelcomeScreen();
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
      // 🔥 CRITICAL: Add named routes for proper navigation
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/checkout': (context) => const CheckoutScreen(),
        '/order-history': (context) => const OrderHistoryScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }

  Future<void> _initializeApp() async {
    // Just a small delay to ensure everything is ready
    await Future.delayed(const Duration(milliseconds: 100));
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _circleController;
  late AnimationController _contentController;
  late Animation<double> _circleAnimation;
  late Animation<double> _contentAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _circleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _circleAnimation = CurvedAnimation(
      parent: _circleController,
      curve: Curves.elasticOut,
    );

    _contentAnimation = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeInOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _contentController,
            curve: Curves.easeOutBack,
          ),
        );

    _circleController.forward();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _circleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF006A4E),
        child: SafeArea(
          child: Center(
            child: ScaleTransition(
              scale: _circleAnimation,
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC143C),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(35.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _contentAnimation,
                          child: const Text(
                            'Tandoori\nNights',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.1,
                              letterSpacing: -0.5,
                              fontFamily: 'Georgia',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _contentAnimation,
                          child: const Text(
                            'Authentic Bangladeshi Cuisine',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFF4F4F4),
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _contentAnimation,
                          child: _AnimatedButton(
                            text: 'Continue as Guest',
                            isPrimary: true,
                            onPressed: () {
                              // 🔥 FIXED: Use named route instead of direct navigation
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/home',
                                (route) => false,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _contentAnimation,
                          child: _AnimatedButton(
                            text: 'Login',
                            isPrimary: false,
                            onPressed: () {
                              // 🔥 FIXED: Use named route instead of direct navigation
                              Navigator.pushNamed(context, '/login');
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _contentAnimation,
                          child: _AnimatedButton(
                            text: 'Create Account',
                            isPrimary: false,
                            onPressed: () {
                              // 🔥 FIXED: Use named route instead of direct navigation
                              Navigator.pushNamed(context, '/register');
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🗑️ REMOVED: Custom route builder - using named routes instead
  // Route _createRoute(Widget destination) { ... }
}

class _AnimatedButton extends StatefulWidget {
  final String text;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _AnimatedButton({
    required this.text,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );

    _elevationAnimation = Tween<double>(begin: 4.0, end: 8.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHoverStart() {
    setState(() {
      _isHovered = true;
    });
    _hoverController.forward();
  }

  void _onHoverEnd() {
    setState(() {
      _isHovered = false;
    });
    _hoverController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHoverStart(),
      onExit: (_) => _onHoverEnd(),
      child: GestureDetector(
        onTapDown: (_) => _onHoverStart(),
        onTapUp: (_) => _onHoverEnd(),
        onTapCancel: () => _onHoverEnd(),
        child: AnimatedBuilder(
          animation: _hoverController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: SizedBox(
                width: 200,
                height: 40,
                child: widget.isPrimary
                    ? ElevatedButton(
                        onPressed: widget.onPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isHovered
                              ? const Color(0xFFF5F5F5)
                              : Colors.white,
                          foregroundColor: const Color(0xFFDC143C),
                          elevation: _elevationAnimation.value,
                          shadowColor: Colors.black.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          widget.text,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _isHovered
                                ? const Color(0xFFDC143C).withOpacity(0.8)
                                : const Color(0xFFDC143C),
                          ),
                        ),
                      )
                    : OutlinedButton(
                        onPressed: widget.onPressed,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _isHovered
                              ? Colors.white.withOpacity(0.1)
                              : Colors.transparent,
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: _isHovered
                                ? const Color(0xFFF4D03F)
                                : Colors.white,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          widget.text,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _isHovered
                                ? const Color(0xFFF4D03F)
                                : Colors.white,
                          ),
                        ),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}
