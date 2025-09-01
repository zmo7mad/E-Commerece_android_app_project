import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import 'package:e_commerece/models/product.dart';
import 'package:e_commerece/screens/product/item_screen.dart';
import 'package:e_commerece/providers/cart_provider.dart';
import 'package:e_commerece/providers/products_stream_provider.dart';
import 'package:e_commerece/shared/widgets/product_image.dart';
import 'package:e_commerece/shared/widgets/text_utils.dart';
import 'package:e_commerece/shared/widgets/stock_utils.dart';
import 'package:e_commerece/shared/widgets/category_utils.dart';
import 'package:e_commerece/providers/stock_provider.dart';

class CategoriesTab extends ConsumerStatefulWidget {
  const CategoriesTab({super.key});

  @override
  ConsumerState<CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends ConsumerState<CategoriesTab> {
  String selectedCategory = 'All';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Delay initialization to prevent race conditions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeStockProvider();
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  void _initializeStockProvider() {
    try {
      final productsAsync = ref.read(categoriesProductsStreamProvider);
      productsAsync.whenData((products) {
        if (products.isNotEmpty && mounted) {
          StockUtils.initializeStockProvider(ref, products);
        }
      });
    } catch (e) {
      debugPrint('Error initializing stock provider in CategoriesTab: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while initializing
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final asyncProducts = ref.watch(categoriesProductsStreamProvider);
    final cart = ref.watch(cartNotifierProvider);
    
    // Add null safety check
    try {
      final stock = ref.watch(stockProvider);
    } catch (e) {
      debugPrint('Error watching stock provider: $e');
    }
    
    // Sync stock provider when products are loaded with error handling
    asyncProducts.whenData((products) {
      try {
        if (products.isNotEmpty && mounted) {
          StockUtils.initializeStockProvider(ref, products);
        }
      } catch (e) {
        debugPrint('Error syncing stock provider: $e');
      }
    });

    return Scaffold(
      body: asyncProducts.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading categories...'),
            ],
          ),
        ),
        error: (err, stack) {
          debugPrint('Categories error: $err');
          debugPrint('Stack trace: $stack');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Failed to load categories',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: $err',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(categoriesProductsStreamProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
        data: (products) {
          try {
            return _buildCategoriesContent(products, cart);
          } catch (e) {
            debugPrint('Error building categories content: $e');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Error displaying categories'),
                  const SizedBox(height: 8),
                  Text('$e'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(categoriesProductsStreamProvider);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildCategoriesContent(List<Map<String, dynamic>> products, Set<Product> cart) {
    // Add null and type checks for products
    if (products.isEmpty) {
      return const Center(
        child: Text('No products available'),
      );
    }

    // FIXED: Only remove items that are clearly invalid/placeholder
    final validProducts = products.where((productMap) {
      try {
        final String title = (productMap['title'] ?? '').toString().trim();
        final String image = (productMap['image'] ?? '').toString().trim();
        
        // Only filter out items with no title or "no title" - allow items with just title and image
        final bool hasValidTitle = title.isNotEmpty && title.toLowerCase() != 'no title';
        final bool hasValidImage = image.isNotEmpty;
        
        return hasValidTitle && hasValidImage;
      } catch (e) {
        debugPrint('Error filtering product: $e');
        return false;
      }
    }).toList();

    // Build categories list from valid data
    final Set<String> categories = {'All'};
    for (final p in validProducts) {
      try {
        final cat = (p['category']?.toString().trim().isNotEmpty == true)
            ? p['category'].toString()
            : CategoryUtils.deriveCategory(p['title']?.toString() ?? '');
        categories.add(cat);
      } catch (e) {
        debugPrint('Error processing category for product: $e');
      }
    }

    // Filter products by selected category
    final filtered = selectedCategory == 'All'
        ? validProducts
        : validProducts.where((p) {
            try {
              final cat = (p['category']?.toString().trim().isNotEmpty == true)
                  ? p['category'].toString()
                  : CategoryUtils.deriveCategory(p['title']?.toString() ?? '');
              return cat == selectedCategory;
            } catch (e) {
              debugPrint('Error filtering by category: $e');
              return false;
            }
          }).toList();

    return CustomScrollView(
      slivers: [
        // Header with title and category chips
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((c) {
                      final bool selected = c == selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () {
                            if (mounted) {
                              setState(() => selectedCategory = c);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.black87
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Text(
                              c,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : Colors.black54,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        // Product grid with sliver layout
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 16,
              childAspectRatio: 0.56,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                try {
                  return _buildProductItem(filtered[index], cart);
                } catch (e) {
                  debugPrint('Error building product item at index $index: $e');
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text('Error loading product'),
                    ),
                  );
                }
              },
              childCount: filtered.length,
            ),
          ),
        ),
        // Bottom padding for better scrolling experience
        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
      ],
    );
  }

  Widget _buildProductItem(Map<String, dynamic> p, Set<Product> cart) {
    final String title = (p['title'] ?? '').toString();
    final int price = p['price'] is int
        ? p['price'] as int
        : int.tryParse(p['price']?.toString() ?? '') ?? 0;
    final String image = (p['image'] ?? '').toString();
    final int stockQuantity = p['stockQuantity'] != null
        ? int.tryParse(p['stockQuantity'].toString()) ?? 0
        : 0;
    
    // Create product for cart checking
    final product = Product(
      id: (p['id'] ?? '').toString(),
      title: title,
      price: price,
      image: image,
      sellerName: p['sellerName']?.toString(),
      description: p['description']?.toString(),
      stockQuantity: stockQuantity,
    );
    final inCart = cart.any((p) => p.id == product.id);

    return OpenContainer(
      closedElevation: 0,
      openElevation: 0,
      closedColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 350),
      transitionType: ContainerTransitionType.fade,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      openBuilder: (context, close) {
        // Navigate to item screen requires Product model
        final product = Product(
          id: (p['id'] ?? '').toString(),
          title: title,
          price: price,
          image: image,
          images: p['images'] != null 
              ? (p['images'] as List).map((e) => e.toString()).toList()
              : null,
          sellerName: p['sellerName']?.toString(),
          description: p['description']?.toString(),
          stockQuantity: stockQuantity,
        );
        return ItemScreen(product: product);
      },
      closedBuilder: (context, open) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: open,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 24, 24, 24).withOpacity(0.1),
                    spreadRadius: 3,
                    blurRadius: 10,
                    offset: const Offset(9, 10),
                  ),
                ],
                color: const Color.fromARGB(255, 246, 246, 246),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color.fromARGB(255, 227, 227, 227),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Product Image Section
                  Expanded(
                    flex: 7,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ProductImage(image: image),
                      ),
                    ),
                  ),
                  // Product Info Section
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Stock Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: product.isInStock 
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: product.isInStock 
                                    ? Colors.green.withOpacity(0.3)
                                    : Colors.red.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  product.isInStock ? Icons.check_circle : Icons.cancel,
                                  color: product.isInStock ? Colors.green : Colors.red,
                                  size: 10,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  product.isInStock ? 'In Stock' : 'Out of Stock',
                                  style: TextStyle(
                                    color: product.isInStock ? Colors.green : Colors.red,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 6),
                          
                          // Product Title with truncation logic
                          TextUtils.buildTruncatedTitleWidget(
                            title,
                            maxWords: 4,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              height: 1.2,
                            ),
                            truncatedColor: const Color(0xFF2196F3),
                          ),
                          
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '\$${price}',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              // Add to Cart Button
                              GestureDetector(
                                onTap: product.isInStock ? () {
                                  try {
                                    final cartNotifier = ref.read(cartNotifierProvider.notifier);
                                    if (inCart) {
                                      cartNotifier.removeProduct(product);
                                      ref.read(cartQuantitiesProvider.notifier).remove(product.id);
                                    } else {
                                      cartNotifier.addProduct(product);
                                      ref.read(cartQuantitiesProvider.notifier).setQuantity(product.id, 1);
                                    }
                                  } catch (e) {
                                    debugPrint('Error updating cart: $e');
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Error updating cart'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                } : null,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6, 
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !product.isInStock
                                        ? Colors.grey.shade400
                                        : inCart 
                                            ? Colors.orange.shade500
                                            : const Color(0xFF2196F3),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    !product.isInStock
                                        ? Icons.block
                                        : inCart 
                                            ? Icons.remove_shopping_cart
                                            : Icons.add_shopping_cart,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
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
      },
    );
  }
}