import 'package:e_commerece/models/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_commerece/providers/cart_provider.dart';
import 'package:e_commerece/shared/firebase.dart';

// Inline provider for products
final productsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) => fetchProducts());

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the providers
    final asyncProducts = ref.watch(productsProvider);
    final cartProducts = ref.watch(cartNotifierProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header with just the title
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Home",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),

           Expanded(
            child: asyncProducts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load products',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please check your connection and try again',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
              data: (products) {
                if (products.isEmpty) {
                  return const Center(
                    child: Text(
                      'No products available',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }
                
                return GridView.builder(
                  itemCount: products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.75, // Reduced from 0.9 to give more height
                  ),
                  itemBuilder: (context, index) {
                    final productMap = products[index];
                    final product = Product(
                      id: productMap['id']?.toString() ?? 'no-id',
                      title: productMap['title']?.toString() ?? 'No title',
                      price: productMap['price'] != null
                          ? int.tryParse(productMap['price'].toString()) ?? 0
                          : 0,
                      image: productMap['image']?.toString() ?? 'assets/products/backpack.png',
                    );
                    final inCart = cartProducts.any((p) => p.id == product.id);

                    return Container(
                      padding: const EdgeInsets.all(12), // Reduced padding from 20 to 12
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Product Image - Constrained size
                          Expanded(
                            flex: 3,
                            child: Center(
                              child: Image.asset(
                                product.image,
                                height: 60, // Reduced from 80
                                width: 60,  // Reduced from 80
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8), // Reduced from 12
                          
                          // Product Title - Constrained and ellipsized
                          Expanded(
                            flex: 1,
                            child: Text(
                              product.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14, // Reduced from 16
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                          const SizedBox(height: 4), // Reduced from 8
                          
                          // Product Price
                          Expanded(
                            flex: 1,
                            child: Text(
                              '\$${product.price}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 14, // Reduced from 16
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6), // Reduced from 8
                          
                          // Add/Remove Button - Constrained height
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  final cart = ref.read(cartNotifierProvider.notifier);
                                  if (inCart) {
                                    cart.removeProduct(product);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Removed from cart'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  } else {
                                    cart.addProduct(product);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Added to cart'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: inCart ? Colors.red : Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8), // Reduced padding
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  inCart ? 'Remove' : 'Add to Cart', // Shortened text
                                  style: const TextStyle(
                                    fontSize: 12, // Reduced font size
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}