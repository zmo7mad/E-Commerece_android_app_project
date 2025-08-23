import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_commerece/models/product.dart';
import 'package:e_commerece/providers/checkout_provider.dart';
import 'package:e_commerece/providers/cart_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
 

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

      // Build quantities from provider so amounts carry over
      final quantities = ref.read(cartQuantitiesProvider);
      final Map<String, int> productQuantities = {
        for (final p in widget.cartProducts) p.id: (quantities[p.id] ?? 1),
      };

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
          'quantity': productQuantities[p.id] ?? 1,
        }).toList(),
        'total': widget.cartProducts.fold<int>(0, (sum, p) => sum + p.price * (productQuantities[p.id] ?? 1)),
        'orderDate': FieldValue.serverTimestamp(),
        'status': 'pending',
        'orderId': 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      };

      // Save order to Firestore
      final orderRef = await FirebaseFirestore.instance
          .collection('Orders')
          .add(orderData);

      // Increment product-level purchase counters (only for existing products)
      final batch = FirebaseFirestore.instance.batch();
      for (final entry in productQuantities.entries) {
        try {
          final docRef = FirebaseFirestore.instance.collection('Products').doc(entry.key);
          // Check if product exists before updating
          final docSnapshot = await docRef.get();
          if (docSnapshot.exists) {
            batch.update(docRef, {
              'timesBought': FieldValue.increment(entry.value),
            });
          }
          // If product doesn't exist, skip updating it (don't create new documents)
        } catch (e) {
          print('Warning: Could not update timesBought for product ${entry.key}: $e');
          // Continue with other products even if one fails
        }
      }
      // Link order to user
      final userOrdersRef = FirebaseFirestore.instance.collection('Users').doc(user.uid).collection('Orders').doc(orderRef.id);
      batch.set(userOrdersRef, {
        'orderId': orderRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'total': widget.cartProducts.fold<int>(0, (sum, p) => sum + p.price * (productQuantities[p.id] ?? 1)),
      });
      await batch.commit();

      // Update user's purchase history with quantities and product IDs
      await _updateUserPurchaseHistory(user.uid, widget.cartProducts, productQuantities);

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

  Future<void> _updateUserPurchaseHistory(String userId, List<Product> products, Map<String, int> quantities) async {
    try {
      final userDocRef = FirebaseFirestore.instance.collection('Users').doc(userId);
      
      // Get current user data
      final userDoc = await userDocRef.get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        // Map of productId -> total quantity ever bought
        final Map<String, int> productTotals = Map<String, int>.from(userData['productsBought'] ?? {});
        // List of product IDs bought at least once
        final Set<String> purchaseIds = Set<String>.from(userData['purchaseHistory'] ?? <String>[]);

        for (final Product product in products) {
          final int qty = quantities[product.id] ?? 1;
          productTotals[product.id] = (productTotals[product.id] ?? 0) + qty;
          purchaseIds.add(product.id);
        }

        await userDocRef.update({
          'productsBought': productTotals,
          'purchaseHistory': purchaseIds.toList(),
          'lastPurchaseDate': FieldValue.serverTimestamp(),
          'totalPurchases': purchaseIds.length,
        });
        
        print('User purchase history updated successfully');
      } else {
        final Map<String, int> initialTotals = {};
        for (final Product p in products) {
          initialTotals[p.id] = (initialTotals[p.id] ?? 0) + (quantities[p.id] ?? 1);
        }
        await userDocRef.set({
          'productsBought': initialTotals,
          'purchaseHistory': products.map((p) => p.id).toList(),
          'lastPurchaseDate': FieldValue.serverTimestamp(),
          'totalPurchases': initialTotals.length,
        }, SetOptions(merge: true));
        
        print('User document created with purchase history');
      }
    } catch (e) {
      print('Error updating user purchase history: $e');

    }
  }

  @override
  Widget build(BuildContext context) {
    final quantitiesWatch = ref.watch(cartQuantitiesProvider);
    final displayTotal = widget.cartProducts.fold<int>(
      0,
      (sum, p) => sum + p.price * (quantitiesWatch[p.id] ?? 1),
    );
    return Scaffold(
      appBar: AppBar(
           flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary,
                      Colors.white,
                    ],
                    stops: const [0, 0.2,1],
                  ),
                ),
              ),
        backgroundColor: Colors.white,
        title:  Text('Checkout',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
        ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.primary,),
        ),
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
                              child: Container(
                                width: 50,
                                height: 50,
                                child: _ProductImage(image: product.image),
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
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text('x${(ref.watch(cartQuantitiesProvider)[product.id] ?? 1)}', style: const TextStyle(fontSize: 12)),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        ' \$${product.price}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '\$${product.price * (ref.watch(cartQuantitiesProvider)[product.id] ?? 1)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
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
                            '\$' + displayTotal.toString(),
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
                keyboardType: TextInputType.phone,
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
              const SizedBox(height: 16),

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

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.image});

  final String image;

  bool get _isNetwork => image.startsWith('http://') || image.startsWith('https://');
  bool get _isDataUrl => image.startsWith('data:image/');

  @override
  Widget build(BuildContext context) {
    if (_isDataUrl) {
      // Data URL: decode and render
      try {
        final uri = Uri.parse(image);
        final data = uri.data; // data URI
        if (data != null) {
          return Image.memory(
            data.contentAsBytes(), 
            fit: BoxFit.cover,
            width: 50,
            height: 50,
          );
        }
      } catch (_) {}
      return Image.asset(
        'assets/products/backpack.png', 
        fit: BoxFit.cover,
        width: 50,
        height: 50,
      );
    }
    if (_isNetwork) {
      return CachedNetworkImage(
        imageUrl: image,
        fit: BoxFit.cover,
        width: 50,
        height: 50,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, url, error) => Image.asset(
          'assets/products/backpack.png', 
          fit: BoxFit.cover,
          width: 50,
          height: 50,
        ),
      );
    }
    return Image.asset(
      image, 
      fit: BoxFit.cover,
      width: 50,
      height: 50,
    );
  }
}
