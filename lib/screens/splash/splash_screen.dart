import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_commerece/routes/app_routes.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Initialize fade animation
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _checkUserStatus();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _checkUserStatus() async {
    // Add a small delay to show the splash screen
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      // Start fade out animation
      _fadeController.forward();
      
      // Wait for animation to complete
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (mounted) {
        // Check if user is already signed in
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // User is signed in, go to home
          AppRoutes.navigateToHome(context);
        } else {
          // User is not signed in, go to login
          AppRoutes.navigateToLogin(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _fadeController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Stack(
              fit: StackFit.expand,
              children: [
                  // Main gradient background matching auth screens
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.fromARGB(255, 24, 31, 57), // Pure black
                          Color.fromARGB(255, 43, 48, 88), // Very dark green
                          Color.fromARGB(255, 153, 164, 193), // Your brand green
                          Color.fromARGB(255, 58, 73, 131), // Dark green tint
                        ],
                        stops: [0.0, 0.3, 0.7, 1.0],
                      ),
                    ),
                  ),

                  // Cool randomly placed white elements
                  ...List.generate(15, (index) => _buildRandomWhiteElement(index)),

                  // Main content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App icon with white background
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.shopping_cart,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // App name
                        const Text(
                          'ShopEase',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                            color: Color.fromARGB(255, 238, 238, 238),
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 4,
                                color: Color.fromARGB(177, 102, 102, 102),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),

                        // Subtitle
                        Text(
                          'Your Shopping Destination',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Poppins',
                            color: Color.fromARGB(255, 238, 238, 238),
                            letterSpacing: 0.8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 60),

                        // Loading indicator
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            color: Color.fromARGB(255, 238, 238, 238),
                            strokeWidth: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRandomWhiteElement(int index) {
    final random = Random(index); // Use index as seed for consistent positioning
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Generate random position
    final left = random.nextDouble() * screenWidth;
    final top = random.nextDouble() * screenHeight;
    
    // Random size and opacity
    final size = 20 + random.nextDouble() * 60; // Size between 20-80
    final opacity = 0.05 + random.nextDouble() * 0.15; // Opacity between 0.05-0.2
    
    // Random shape type
    final shapeType = random.nextInt(4);
    
    return Positioned(
      left: left,
      top: top,
      child: _buildWhiteShape(shapeType, size, opacity),
    );
  }

  Widget _buildWhiteShape(int shapeType, double size, double opacity) {
    switch (shapeType) {
      case 0: // Circle
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(opacity),
          ),
        );
      case 1: // Square
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      case 2: // Diamond
        return Transform.rotate(
          angle: 0.785398, // 45 degrees in radians
          child: Container(
            width: size * 0.7,
            height: size * 0.7,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      default: // Triangle
        return CustomPaint(
          size: Size(size, size),
          painter: TrianglePainter(Colors.white.withOpacity(opacity)),
        );
    }
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
} 