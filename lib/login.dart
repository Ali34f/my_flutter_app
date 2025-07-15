import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register.dart';
import 'reset.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late AnimationController _circleController;
  late AnimationController _contentController;
  late Animation<double> _circleAnimation;
  late Animation<double> _contentAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _circleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

    // Start animations
    _circleController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _circleController.dispose();
    _contentController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Add haptic feedback
      HapticFeedback.lightImpact();

      try {
        // Firebase Authentication Login
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        setState(() {
          _isLoading = false;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome back, ${userCredential.user?.email}!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Navigate to home screen after successful login
          Navigator.pushReplacement(context, _createRoute(const HomeScreen()));
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          _isLoading = false;
        });

        String errorMessage;
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No user found with this email address.';
            break;
          case 'wrong-password':
            errorMessage = 'Incorrect password. Please try again.';
            break;
          case 'invalid-email':
            errorMessage = 'Please enter a valid email address.';
            break;
          case 'user-disabled':
            errorMessage = 'This account has been disabled.';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many failed attempts. Please try again later.';
            break;
          default:
            errorMessage = 'Login failed. Please try again.';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('An unexpected error occurred. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate responsive sizes for iPhone 15 Pro Max
    final circleSize = screenWidth * 0.85; // 85% of screen width
    final maxCircleSize = screenHeight * 0.55; // Max 55% of screen height
    final finalCircleSize = circleSize > maxCircleSize
        ? maxCircleSize
        : circleSize;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Perfect Bangladesh Flag Green Background
        color: const Color(0xFF006A4E),
        child: SafeArea(
          child: Stack(
            children: [
              // Back Button
              Positioned(
                top: 20,
                left: 20,
                child: FadeTransition(
                  opacity: _contentAnimation,
                  child: _AnimatedBackButton(
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

              // Main Content - Responsive Layout
              Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Perfect Bangladesh Flag Red Circle with Login Content
                      ScaleTransition(
                        scale: _circleAnimation,
                        child: Container(
                          width: finalCircleSize,
                          height: finalCircleSize,
                          decoration: BoxDecoration(
                            // Perfect Bangladesh Flag Red Color
                            color: const Color(0xFFDC143C),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Container(
                              padding: EdgeInsets.all(
                                finalCircleSize * 0.1,
                              ), // 10% padding
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Welcome Title
                                    SlideTransition(
                                      position: _slideAnimation,
                                      child: FadeTransition(
                                        opacity: _contentAnimation,
                                        child: Column(
                                          children: [
                                            Text(
                                              'Welcome\nBack',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize:
                                                    finalCircleSize *
                                                    0.065, // Responsive font size
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                height: 1.1,
                                                letterSpacing: -0.5,
                                                fontFamily: 'Georgia',
                                              ),
                                            ),
                                            SizedBox(
                                              height: finalCircleSize * 0.008,
                                            ),
                                            Text(
                                              'Sign in to your account',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize:
                                                    finalCircleSize * 0.03,
                                                color: const Color(0xFFF4F4F4),
                                                fontWeight: FontWeight.w300,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: finalCircleSize * 0.035),

                                    // Email Field
                                    SlideTransition(
                                      position: _slideAnimation,
                                      child: FadeTransition(
                                        opacity: _contentAnimation,
                                        child: SizedBox(
                                          width:
                                              finalCircleSize *
                                              0.55, // Responsive width
                                          child: _buildCompactTextField(
                                            controller: _emailController,
                                            hintText: 'Enter your email',
                                            icon: Icons.email_outlined,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            validator: _validateEmail,
                                            fieldHeight: finalCircleSize * 0.09,
                                            fontSize: finalCircleSize * 0.03,
                                          ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: finalCircleSize * 0.025),

                                    // Password Field
                                    SlideTransition(
                                      position: _slideAnimation,
                                      child: FadeTransition(
                                        opacity: _contentAnimation,
                                        child: SizedBox(
                                          width: finalCircleSize * 0.55,
                                          child: _buildCompactTextField(
                                            controller: _passwordController,
                                            hintText: 'Enter your password',
                                            icon: Icons.lock_outline,
                                            isPassword: true,
                                            validator: _validatePassword,
                                            fieldHeight: finalCircleSize * 0.09,
                                            fontSize: finalCircleSize * 0.03,
                                          ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: finalCircleSize * 0.015),

                                    // Forgot Password
                                    SlideTransition(
                                      position: _slideAnimation,
                                      child: FadeTransition(
                                        opacity: _contentAnimation,
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                              right: finalCircleSize * 0.225,
                                            ),
                                            child: _AnimatedLink(
                                              text: 'Forgot Password?',
                                              fontSize: finalCircleSize * 0.025,
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  _createRoute(
                                                    const ResetScreen(),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: finalCircleSize * 0.025),

                                    // Login Button
                                    SlideTransition(
                                      position: _slideAnimation,
                                      child: FadeTransition(
                                        opacity: _contentAnimation,
                                        child: SizedBox(
                                          width: finalCircleSize * 0.55,
                                          child: _AnimatedLoginButton(
                                            onPressed: _handleLogin,
                                            isLoading: _isLoading,
                                            buttonHeight:
                                                finalCircleSize * 0.12,
                                            fontSize: finalCircleSize * 0.045,
                                          ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: finalCircleSize * 0.025),

                                    // Create Account Link
                                    SlideTransition(
                                      position: _slideAnimation,
                                      child: FadeTransition(
                                        opacity: _contentAnimation,
                                        child: Column(
                                          children: [
                                            Text(
                                              "Don't have an account?",
                                              style: TextStyle(
                                                color: const Color(0xFFF4F4F4),
                                                fontSize:
                                                    finalCircleSize * 0.03,
                                              ),
                                            ),
                                            SizedBox(
                                              height: finalCircleSize * 0.008,
                                            ),
                                            _AnimatedLink(
                                              text: 'Create one here',
                                              fontSize: finalCircleSize * 0.032,
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  _createRoute(
                                                    const RegisterScreen(),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
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

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
    String? Function(String?)? validator,
    required double fieldHeight,
    required double fontSize,
  }) {
    return Container(
      height: fieldHeight,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.98),
        borderRadius: BorderRadius.circular(fieldHeight / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword && !_isPasswordVisible,
        textInputAction: isPassword
            ? TextInputAction.done
            : TextInputAction.next,
        validator: validator,
        style: TextStyle(
          color: const Color(0xFF333333),
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: fontSize,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(
              left: fieldHeight * 0.3,
              right: fieldHeight * 0.2,
            ),
            child: Icon(
              icon,
              color: const Color(0xFFDC143C),
              size: fontSize * 1.4,
            ),
          ),
          prefixIconConstraints: BoxConstraints(
            minWidth: fieldHeight * 0.8,
            minHeight: fieldHeight,
          ),
          suffixIcon: isPassword
              ? Padding(
                  padding: EdgeInsets.only(right: fieldHeight * 0.2),
                  child: IconButton(
                    iconSize: fontSize * 1.4,
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFFDC143C),
                      size: fontSize * 1.4,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(fieldHeight / 2),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.symmetric(
            horizontal: fieldHeight * 0.3,
            vertical: fieldHeight * 0.2,
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }

  Route _createRoute(Widget destination) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => destination,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }
}

// Custom Animated Back Button
class _AnimatedBackButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _AnimatedBackButton({required this.onPressed});

  @override
  State<_AnimatedBackButton> createState() => _AnimatedBackButtonState();
}

class _AnimatedBackButtonState extends State<_AnimatedBackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 22,
              ),
            ),
          );
        },
      ),
    );
  }
}

// Custom Animated Login Button
class _AnimatedLoginButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final double buttonHeight;
  final double fontSize;

  const _AnimatedLoginButton({
    required this.onPressed,
    required this.isLoading,
    required this.buttonHeight,
    required this.fontSize,
  });

  @override
  State<_AnimatedLoginButton> createState() => _AnimatedLoginButtonState();
}

class _AnimatedLoginButtonState extends State<_AnimatedLoginButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _controller.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _controller.reverse();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _controller.reverse();
        },
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: double.infinity,
                height: widget.buttonHeight,
                decoration: BoxDecoration(
                  color: widget.isLoading
                      ? Colors.white.withOpacity(0.8)
                      : _isPressed
                      ? const Color(0xFFF8F8F8)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(widget.buttonHeight / 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: _isPressed ? 4 : 8,
                      offset: Offset(0, _isPressed ? 2 : 4),
                    ),
                  ],
                ),
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          width: widget.fontSize * 1.2,
                          height: widget.fontSize * 1.2,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFDC143C),
                            ),
                          ),
                        )
                      : Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: widget.fontSize,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFDC143C),
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

// Custom Animated Link
class _AnimatedLink extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final double fontSize;

  const _AnimatedLink({
    required this.text,
    required this.onTap,
    this.fontSize = 12,
  });

  @override
  State<_AnimatedLink> createState() => _AnimatedLinkState();
}

class _AnimatedLinkState extends State<_AnimatedLink>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Text(
              widget.text,
              style: TextStyle(
                color: const Color(0xFFF4D03F),
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFFF4D03F),
              ),
            ),
          );
        },
      ),
    );
  }
}
