import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:e_commerece/routes/app_routes.dart';
import 'package:e_commerece/shared/green_black_animated_bg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:e_commerece/providers/cart_provider.dart';
import 'package:e_commerece/providers/favorites_provider.dart';
 
 
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
final _auth = FirebaseAuth.instance;

// Google Sign-In v6.2.0 configuration
final GoogleSignIn googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
);

@override
void initState() {
  super.initState();
  // Avoid null X-Firebase-Locale header warning
  _auth.setLanguageCode('en');
}

Future<void> _login() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    await _auth.signInWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    // Reload cart and favorites from Firebase
    ref.read(cartNotifierProvider.notifier).reloadFromFirebase();
    ref.read(cartQuantitiesProvider.notifier).reloadFromFirebase();
    ref.read(favoritesProvider.notifier).reloadFromFirebase();

    if (mounted) AppRoutes.navigateToHome(context);
  } on FirebaseAuthException catch (_) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email or password is incorrect')),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

Future<void> _signInWithGoogle() async {
  if (_isLoading) return;
  
  // Check if user is already signed in
  if (_auth.currentUser != null) {
    if (mounted) AppRoutes.navigateToHome(context);
    return;
  }

  setState(() => _isLoading = true);

  try {
    UserCredential userCredential;

    if (kIsWeb) {
      // Web implementation
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      
      userCredential = await _auth.signInWithPopup(googleProvider);
    } else {
      // Mobile implementation - clean and simple for v6.2.0
      
      // Clear any previous sign-in to avoid state issues
      await googleSignIn.signOut();
      
      // Start the sign-in process
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      
      if (account == null) {
        // User canceled the sign-in
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await account.authentication;

      // Create Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      userCredential = await _auth.signInWithCredential(credential);
    }

    // Handle successful sign-in
    final user = userCredential.user;
    if (user != null) {
      await _storeUserInFirestore(user);
      
      // Reload cart and favorites from Firebase
      ref.read(cartNotifierProvider.notifier).reloadFromFirebase();
      ref.read(cartQuantitiesProvider.notifier).reloadFromFirebase();
      ref.read(favoritesProvider.notifier).reloadFromFirebase();
      
      if (mounted) {
        AppRoutes.navigateToHome(context);
      }
    }

  } catch (e, st) {
    debugPrint('Google sign-in error: $e\n$st');
    
    // Clear any partial sign-in state on error
    try {
      await googleSignIn.signOut();
    } catch (_) {}
    
    if (mounted) {
      String errorMessage = 'Google sign-in failed';
      
      // Handle specific error types
      if (e.toString().contains('network_error') || e.toString().contains('NetworkError')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      } else if (e.toString().contains('sign_in_canceled')) {
        errorMessage = 'Sign-in was canceled.';
      } else if (e.toString().contains('sign_in_failed')) {
        errorMessage = 'Sign-in failed. Please try again.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

Future<void> _storeUserInFirestore(User user) async {
  try {
    final usersCollection = FirebaseFirestore.instance.collection('Users');
    final userDoc = await usersCollection.doc(user.uid).get();
    
    if (!userDoc.exists) {
      // Create new user document
      await usersCollection.doc(user.uid).set({
        'uid': user.uid,
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'address': '',
        'photoURL': user.photoURL ?? '',
        'provider': 'google',
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('New user created in Firestore: ${user.uid}');
    } else {
      // Update existing user's last login
      await usersCollection.doc(user.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'name': user.displayName ?? userDoc.data()?['name'] ?? '',
        'email': user.email ?? userDoc.data()?['email'] ?? '',
        'photoURL': user.photoURL ?? userDoc.data()?['photoURL'] ?? '',
      });
      debugPrint('User login updated: ${user.uid}');
    }
  } catch (e) {
    debugPrint('Firestore error: $e');
    // Don't throw - user is still authenticated
  }
}

@override
void dispose() {
  emailController.dispose();
  passwordController.dispose();
  
  // Clean disconnect for v6.2.0
  googleSignIn.disconnect().catchError((error) {
    debugPrint('Google Sign-In disconnect error: $error');
    return null;
  });
  
  super.dispose();
}  void _goToRegister() {
    AppRoutes.navigateToRegister(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: GreenBlackAnimatedBg(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.shopping_cart, size: 80, color: Colors.white),
                  const SizedBox(height: 20),

                  Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Sign in to continue',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Email Field
                  TextFormField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      label: 'Password',
                      icon: Icons.lock_outline,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 chars';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Or divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('OR', style: TextStyle(color: Colors.white70)),
                      ),
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Google Sign-In Button
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.4)),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.login),
                    label: const Text(
                      'Continue with Google',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Register Button
                  TextButton(
                    onPressed: _goToRegister,
                    child: const Text(
                      "Don't have an account? Register",
                      style: TextStyle(color: Colors.white70),
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

  InputDecoration _inputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1), // transparent field
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: Colors.white, width: 2),
      ),
    );
  }
}
