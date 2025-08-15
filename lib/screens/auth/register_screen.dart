import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerece/models/app_user.dart';
import 'package:e_commerece/routes/app_routes.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Create user in Firebase Auth
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = credential.user!.uid;

      // Store extra info in Firestore (without password)
      await _firestore.collection('Users').doc(uid).set({
        'uid': uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'purchaseHistory': [], // Initialize empty purchase history
        'totalPurchases': 0,  // Initialize total purchases count
        'lastPurchaseDate': null, // No purchases yet
      });


      // Optional: local model (if needed in app state)
      final user = AppUser(
        uid: uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User registered successfully!')),
        );
        AppRoutes.navigateToLogin(context);
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Registration failed';
      if (e.code == 'email-already-in-use') {
        msg = 'This email is already in use.';
      } else if (e.code == 'weak-password') {
        msg = 'Password is too weak.';
      } else if (e.code == 'invalid-email') {
        msg = 'Invalid email address.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
      hintText: hint,
      prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text('Register'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration(
                  label: 'Name',
                  icon: Icons.person_outline,
                  hint: 'Enter your name',
                ),
                validator: (v) => v!.isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration(
                  label: 'Email',
                  icon: Icons.email_outlined,
                  hint: 'Enter your email',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v!.isEmpty) return 'Enter your email';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: _inputDecoration(
                  label: 'Password',
                  icon: Icons.lock_outline,
                  hint: 'Enter your password',
                ),
                obscureText: true,
                validator: (v) => v!.length < 6 ? 'Password must be 6+ chars' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: _inputDecoration(
                  label: 'Address',
                  icon: Icons.home_outlined,
                  hint: 'Enter your address',
                ),
                validator: (v) => v!.isEmpty ? 'Enter your address' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isLoading ? null : _registerUser,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Register'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
