import 'package:flutter/material.dart';
import 'register.dart'; // Import the register screen
import 'login.dart'; // Import the login screen

void main() {
  runApp(const TandooriNightsApp());
}

class TandooriNightsApp extends StatelessWidget {
  const TandooriNightsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tandoori Nights',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: null, // Use system default font
      ),
      home: const WelcomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF006A4E), // Bangladesh flag green
              Color(0xFF004D3A), // Darker green
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Logo Circle with T
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F4F4), // Light background for logo
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'T',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFDC143C), // Red color for logo
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Restaurant Name
                const Text(
                  'Tandoori\nNights',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 16),

                // Subtitle
                const Text(
                  'Authentic Indian Cuisine',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFFF4F4F4), // Light color for subtitle
                    fontWeight: FontWeight.w300,
                  ),
                ),

                const SizedBox(height: 40),

                // Decorative lines (stacked vertically)
                Column(
                  children: [
                    Container(
                      width: 80,
                      height: 3,
                      color: const Color(
                        0xFFDC143C,
                      ), // Red decorative line (longer)
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 50,
                      height: 3,
                      color: const Color(
                        0xFFDC143C,
                      ), // Red decorative line (shorter)
                    ),
                  ],
                ),

                const SizedBox(height: 60),

                // Welcome Section
                const Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 24),

                // Welcome Description
                const Text(
                  'Join our family to experience the rich\nflavors and aromatic spices of\ntraditional Indian cuisine.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFF4F4F4), // Light color for description
                    height: 1.5,
                    fontWeight: FontWeight.w300,
                  ),
                ),

                const Spacer(flex: 2),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to login screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC143C), // Red button
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Create Account Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigate to register screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC143C), // Red text
                      side: const BorderSide(
                        color: Color(0xFFDC143C), // Red border
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Create an Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
