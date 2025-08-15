import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_commerece/models/product.dart';
import 'package:e_commerece/providers/checkout_provider.dart';
import 'package:e_commerece/providers/cart_provider.dart';
import 'package:e_commerece/routes/app_routes.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final List<Product> cartProducts;
  final int total;

  const CheckoutScreen({
    super.key,
    required this.cartProducts,
    required this.total,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill with current user data if available
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      // Try to get user data from Firestore
      _loadUserData(user.uid);
    }
    

  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _nameController.text = data['name'] ?? '';
        _addressController.text = data['address'] ?? '';
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _completeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    // Start checkout processing
    ref.read(checkoutNotifierProvider.notifier).startProcessing();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to complete your order')),
        );
        return;
      }

      // Create order data
      final orderData = {
        'userId': user.uid,
        'userEmail': user.email,
        'customerName': _nameController.text.trim(),
        'customerPhone': _phoneController.text.trim(),
        'customerAddress': _addressController.text.trim(),
        'products': widget.cartProducts.map((p) => {
          'id': p.id,
          'title': p.title,
          'price': p.price,
          'image': p.image,
        }).toList(),
        'total': widget.total,
        'orderDate': FieldValue.serverTimestamp(),
        'status': 'pending',
        'orderId': 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      };

      // Save order to Firestore
      await FirebaseFirestore.instance
          .collection('Orders')
          .add(orderData);

      // Update user's purchase history with the new product IDs
      await _updateUserPurchaseHistory(user.uid, widget.cartProducts);

      if (mounted) {
        // Complete checkout successfully
        ref.read(checkoutNotifierProvider.notifier).completeCheckout();
        
        // Clear the cart immediately after successful checkout
        ref.read(cartNotifierProvider.notifier).clearCart();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to home
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        // Mark checkout as failed
        ref.read(checkoutNotifierProvider.notifier).failCheckout(e.toString());
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        // Reset processing state
        ref.read(checkoutNotifierProvider.notifier).reset();
      }
    }
  }

  Future<void> _updateUserPurchaseHistory(String userId, List<Product> products) async {
    try {
      final userDocRef = FirebaseFirestore.instance.collection('Users').doc(userId);
      
      // Get current user data
      final userDoc = await userDocRef.get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        List<String> currentPurchaseHistory = List<String>.from(userData['purchaseHistory'] ?? []);
        
        // Add new product IDs to purchase history (avoid duplicates)
        for (Product product in products) {
          if (!currentPurchaseHistory.contains(product.id)) {
            currentPurchaseHistory.add(product.id);
          }
        }
        
        // Update user document with new purchase history
        await userDocRef.update({
          'purchaseHistory': currentPurchaseHistory,
          'lastPurchaseDate': FieldValue.serverTimestamp(),
          'totalPurchases': currentPurchaseHistory.length,
        });
        
        print('User purchase history updated successfully');
      } else {
        await userDocRef.set({
          'purchaseHistory': products.map((p) => p.id).toList(),
          'lastPurchaseDate': FieldValue.serverTimestamp(),
          'totalPurchases': products.length,
        }, SetOptions(merge: true));
        
        print('User document created with purchase history');
      }
    } catch (e) {
      print('Error updating user purchase history: $e');

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text('Checkout'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Summary',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...widget.cartProducts.map((product) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                product.image,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '\$${product.price}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${widget.total}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Customer Information
              Text(
                'Customer Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
                  prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  prefixIcon: Icon(Icons.email, color: Theme.of(context).colorScheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone Field
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter your phone number',
                  prefixIcon: Icon(Icons.phone, color: Theme.of(context).colorScheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address Field
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Delivery Address',
                  hintText: 'Enter your delivery address',
                  prefixIcon: Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Complete Order Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: ref.watch(checkoutNotifierProvider).isProcessing ? null : _completeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: ref.watch(checkoutNotifierProvider).isProcessing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Complete Order',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
