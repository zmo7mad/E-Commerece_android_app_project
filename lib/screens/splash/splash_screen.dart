import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_commerece/routes/app_routes.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    // Add a small delay to show the splash screen
    await Future.delayed(const Duration(seconds: 2));
    
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
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your app logo or icon
            Icon(
              Icons.shopping_cart,
              size: 100,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(height: 20),
            // App name
            Text(
              'Mohammeds Store',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 40),
            // Loading indicator
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ],
        ),
      ),
    );
  }
} 