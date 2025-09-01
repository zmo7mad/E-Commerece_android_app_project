import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_commerece/routes/app_routes.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _textController;
  late AnimationController _fadeController;
  
  late Animation<double> _iconScaleAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // Icon scale animation (bounce effect)
    _iconScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    ));
    
    // Text slide animation (slide from right)
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // Start from right (off-screen)
      end: Offset.zero,   // End at center
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));
    
    // Fade animation for exit
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _startAnimations();
  }

  @override
  void dispose() {
    _iconController.dispose();
    _textController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _startAnimations() async {
    // Start icon animation
    _iconController.forward();
    
    // Wait for icon animation to complete, then start text animation
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      _textController.forward();
    }
    
    // Wait for text animation to complete, then check user status
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      await _checkUserStatus();
    }
  }

  Future<void> _checkUserStatus() async {
    // Start fade out animation
    _fadeController.forward();
    
    // Wait for animation to complete
    await Future.delayed(const Duration(milliseconds: 500));
    
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: Listenable.merge([_iconController, _textController, _fadeController]),
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon with scale animation
                  ScaleTransition(
                    scale: _iconScaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1a237e), // Navy blue
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1a237e).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shopping_cart,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Text with slide animation
                  SlideTransition(
                    position: _textSlideAnimation,
                    child: const Text(
                      'ShopEase',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        color: Color(0xFF1a237e), // Navy blue
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 