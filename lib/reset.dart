import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login.dart';

class ResetScreen extends StatefulWidget {
  const ResetScreen({super.key});

  @override
  State<ResetScreen> createState() => _ResetScreenState();
}

class _ResetScreenState extends State<ResetScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  late AnimationController _circleController;
  late AnimationController _contentController;
  late Animation<double> _circleAnimation;
  late Animation<double> _contentAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isEmailSent = false;
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
    super.dispose();
  }

  void _sendResetEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Add haptic feedback
      HapticFeedback.lightImpact();

      // Simulate email sending process
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;
        _isEmailSent = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Password reset email sent! Check your inbox.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: const Color(0xFFDC143C),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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

              // Main Content - Centered like Bangladesh Flag
              Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Perfect Bangladesh Flag Red Circle with Reset Content
                      ScaleTransition(
                        scale: _circleAnimation,
                        child: Container(
                          width: 350,
                          height: 350,
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
                              padding: const EdgeInsets.all(38),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (!_isEmailSent) ...[
                                      // Reset Password Title
                                      SlideTransition(
                                        position: _slideAnimation,
                                        child: FadeTransition(
                                          opacity: _contentAnimation,
                                          child: Column(
                                            children: [
                                              const Text(
                                                'Reset\nPassword',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  height: 1.1,
                                                  letterSpacing: -0.5,
                                                  fontFamily: 'Georgia',
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              const Text(
                                                'Enter your email to reset password',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Color(0xFFF4F4F4),
                                                  fontWeight: FontWeight.w300,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      // Email Field
                                      SlideTransition(
                                        position: _slideAnimation,
                                        child: FadeTransition(
                                          opacity: _contentAnimation,
                                          child: SizedBox(
                                            width: 190,
                                            child: _buildCompactTextField(
                                              controller: _emailController,
                                              hintText: 'Enter your email',
                                              icon: Icons.email_outlined,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              validator: _validateEmail,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 10),

                                      // Description Text
                                      SlideTransition(
                                        position: _slideAnimation,
                                        child: FadeTransition(
                                          opacity: _contentAnimation,
                                          child: const Text(
                                            'We\'ll send you a secure link to\nreset your password safely',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Color(0xFFF4F4F4),
                                              fontWeight: FontWeight.w300,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 10),

                                      // Send Reset Email Button
                                      SlideTransition(
                                        position: _slideAnimation,
                                        child: FadeTransition(
                                          opacity: _contentAnimation,
                                          child: SizedBox(
                                            width: 190,
                                            child: _AnimatedResetButton(
                                              onPressed: _sendResetEmail,
                                              isLoading: _isLoading,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      // Back to Login Link
                                      SlideTransition(
                                        position: _slideAnimation,
                                        child: FadeTransition(
                                          opacity: _contentAnimation,
                                          child: Column(
                                            children: [
                                              const Text(
                                                "Remember your password?",
                                                style: TextStyle(
                                                  color: Color(0xFFF4F4F4),
                                                  fontSize: 9,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              _AnimatedLink(
                                                text: 'Sign in here',
                                                fontSize: 9,
                                                onTap: () {
                                                  Navigator.pushReplacement(
                                                    context,
                                                    _createRoute(
                                                      const LoginScreen(),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      // Success State - Email Sent
                                      SlideTransition(
                                        position: _slideAnimation,
                                        child: FadeTransition(
                                          opacity: _contentAnimation,
                                          child: Column(
                                            children: [
                                              // Success Icon
                                              Container(
                                                width: 50,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.2),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.email_outlined,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              ),

                                              const SizedBox(height: 12),

                                              const Text(
                                                'Email Sent\nSuccessfully!',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  height: 1.1,
                                                  letterSpacing: -0.5,
                                                  fontFamily: 'Georgia',
                                                ),
                                              ),

                                              const SizedBox(height: 4),

                                              Text(
                                                'Reset link sent to\n${_emailController.text}',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Color(0xFFF4F4F4),
                                                  fontWeight: FontWeight.w300,
                                                  height: 1.4,
                                                ),
                                              ),

                                              const SizedBox(height: 10),

                                              const Text(
                                                'Check your inbox and spam folder\nfor the reset instructions',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color: Color(0xFFF4F4F4),
                                                  fontWeight: FontWeight.w300,
                                                  height: 1.4,
                                                ),
                                              ),

                                              const SizedBox(height: 12),

                                              // Resend Email Button
                                              SizedBox(
                                                width: 160,
                                                child: _AnimatedOutlineButton(
                                                  text: 'Send Again',
                                                  onPressed: () {
                                                    setState(() {
                                                      _isEmailSent = false;
                                                    });
                                                  },
                                                ),
                                              ),

                                              const SizedBox(height: 8),

                                              // Back to Login
                                              _AnimatedLink(
                                                text: 'Back to Sign In',
                                                fontSize: 9,
                                                onTap: () {
                                                  Navigator.pushReplacement(
                                                    context,
                                                    _createRoute(
                                                      const LoginScreen(),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
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
    String? Function(String?)? validator,
  }) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.98),
        borderRadius: BorderRadius.circular(16),
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
        textInputAction: TextInputAction.done,
        validator: validator,
        style: const TextStyle(
          color: Color(0xFF333333),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 10,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 10, right: 6),
            child: Icon(icon, color: const Color(0xFFDC143C), size: 14),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 30,
            minHeight: 32,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
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

// Custom Animated Reset Button
class _AnimatedResetButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const _AnimatedResetButton({
    required this.onPressed,
    required this.isLoading,
  });

  @override
  State<_AnimatedResetButton> createState() => _AnimatedResetButtonState();
}

class _AnimatedResetButtonState extends State<_AnimatedResetButton>
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
                height: 32,
                decoration: BoxDecoration(
                  color: widget.isLoading
                      ? Colors.white.withOpacity(0.9)
                      : _isPressed
                      ? const Color(0xFFF5F5F5)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: _isPressed ? 2 : 4,
                      offset: Offset(0, _isPressed ? 1 : 2),
                    ),
                  ],
                ),
                child: Center(
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFDC143C),
                            ),
                          ),
                        )
                      : const Text(
                          'Send Reset Email',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFDC143C),
                            letterSpacing: 0.2,
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

// Custom Animated Outline Button
class _AnimatedOutlineButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const _AnimatedOutlineButton({required this.text, required this.onPressed});

  @override
  State<_AnimatedOutlineButton> createState() => _AnimatedOutlineButtonState();
}

class _AnimatedOutlineButtonState extends State<_AnimatedOutlineButton>
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
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: double.infinity,
                height: 30,
                decoration: BoxDecoration(
                  color: _isPressed
                      ? Colors.white.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    widget.text,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
    this.fontSize = 9,
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
