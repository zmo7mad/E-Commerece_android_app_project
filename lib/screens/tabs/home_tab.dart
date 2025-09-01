import 'package:e_commerece/models/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_commerece/providers/cart_provider.dart';
import 'package:e_commerece/providers/products_stream_provider.dart';
import 'package:e_commerece/screens/product/item_screen.dart';
import 'package:e_commerece/shared/widgets/product_image.dart';
import 'package:e_commerece/shared/widgets/text_utils.dart';
import 'package:e_commerece/shared/widgets/stock_utils.dart';
import 'package:e_commerece/shared/new_updates_banner.dart';
import 'package:e_commerece/providers/deletion_provider.dart';
import 'package:e_commerece/providers/stock_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  @override
  void initState() {
    super.initState();
    // StreamProvider automatically handles real-time updates
    // Initialize stock provider when products are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeStockProvider();
    });
  }

  void _initializeStockProvider() {
    final productsAsync = ref.read(productsStreamProvider);
    productsAsync.whenData((products) {
      if (products.isNotEmpty) {
        StockUtils.initializeStockProvider(ref, products);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the providers
    final asyncProducts = ref.watch(productsStreamProvider);
    final asyncLatest = ref.watch(latestProductsStreamProvider);
    final cart = ref.watch(cartNotifierProvider);
    final stock = ref.watch(stockProvider); // Watch stock provider for real-time updates
    
    // Sync stock provider when products are loaded
    asyncProducts.whenData((products) {
      if (products.isNotEmpty) {
        StockUtils.initializeStockProvider(ref, products);
      }
    });

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE3F2FD), // Light blue
            Colors.white,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Mountain Background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 400,
            child: Opacity(
              opacity: 0.15,
              child: ClipPath(
                clipper: MountainClipper(),
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200&h=400&fit=crop'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Main Content
          CustomScrollView(
            slivers: [
              // Enhanced SliverAppBar for the banner section
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: _buildEnhancedBannerSection(asyncLatest),
                    ),
                  ),
                ),
              ),
              
              // Enhanced SliverGrid for products
              _buildEnhancedSliverProductsGrid(asyncProducts, cart.toList()),
              
              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedBannerSection(AsyncValue<List<Map<String, dynamic>>> asyncLatest) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: asyncLatest.when(
        loading: () => _buildEnhancedBannerLoading(),
        error: (e, st) {
          print('Banner error: $e');
          return _buildEnhancedBannerFallback();
        },
        data: (latest) {
          return _buildEnhancedBannerWithData(latest);
        },
      ),
    );
  }

  Widget _buildEnhancedBannerLoading() {
    return Container(
      key: const ValueKey('banner-loading'),
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2196F3).withOpacity(0.1),
            const Color(0xFF64B5F6).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF2196F3).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: const Color(0xFF2196F3),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading latest updates...',
              style: TextStyle(
                color: const Color(0xFF2196F3),
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedBannerFallback() {
    return Container(
      key: const ValueKey('banner-fallback'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: NewUpdatesBanner(
          height: 160,
          items: const [
            {'text': '🎉 Welcome to our store!', 'image': 'assets/products/backpack.png'},
            {'text': '✨ Discover amazing products', 'image': 'assets/products/guitar.png'},
            {'text': '🚀 New items added regularly', 'image': 'assets/products/drum.png'},
          ],
          onTap: (index, text) {
            // Handle fallback banner taps
          },
        ),
      ),
    );
  }

  Widget _buildEnhancedBannerWithData(List<Map<String, dynamic>> latest) {
    final items = <Map<String, dynamic>>[];
    
    // Sort products by creation time (newest first) and take the latest 3
    final sortedProducts = List<Map<String, dynamic>>.from(latest);
    sortedProducts.sort((a, b) {
      final aTime = a['createdAt'] as Timestamp?;
      final bTime = b['createdAt'] as Timestamp?;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime); // Newest first
    });
    
    // Build banner items from latest products (left to right)
    for (final product in sortedProducts.take(3)) {
      final title = (product['title'] ?? 'New Product').toString();
      final image = (product['image'] ?? '').toString();
      
      items.add({
        'text': ' New Arrival: $title',
        'image': image, 
        'productId': product['id']?.toString(),
      });
    }

    // Add fallback if no products
    if (items.isEmpty) {
      items.addAll([
        {'text': '🎉 Welcome to our store!', 'image': 'assets/products/drum.png'},
        {'text': '✨ Discover amazing products', 'image': 'assets/products/guitar.png'},
        {'text': '🚀 New items added regularly', 'image': 'assets/products/jeans.png'},
      ]);
    }
    
    // Always ensure we have fallback images for banner items
    for (int i = 0; i < items.length; i++) {
      if (items[i]['image'] == null || (items[i]['image'] as String).isEmpty) {
        items[i]['image'] = 'assets/products/backpack.png'; // Fallback image
      }
    }

    return Container(
      key: const ValueKey('banner-data'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            spreadRadius: 0,
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: NewUpdatesBanner(
          height: 160,
          items: items,
          onTap: (index, text) {
            // Navigate to specific product if available
            if (index < items.length && items[index]['productId'] != null) {
              final productId = items[index]['productId'] as String;
              _navigateToProduct(productId, latest);
            }
          },
        ),
      ),
    );
  }

  Widget _buildEnhancedSliverProductsGrid(AsyncValue<List<Map<String, dynamic>>> asyncProducts, List<Product> cart) {
    return asyncProducts.when(
      loading: () => _buildEnhancedSliverProductsLoading(),
      error: (err, stack) {
        print('Products error: $err');
        return _buildEnhancedSliverProductsError();
      },
      data: (products) {
        return _buildEnhancedSliverProductsSuccess(products, cart);
      },
    );
  }

  Widget _buildEnhancedSliverProductsLoading() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Fixed 2 columns
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.65,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      margin: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(19),
                      child: Column(
                        children: [
                          Container(
                            height: 14,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                height: 16,
                                width: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2196F3).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              Container(
                                height: 28,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(14),
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
            );
          },
          childCount: 6,
        ),
      ),
    );
  }

  Widget _buildEnhancedSliverProductsError() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(24),
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 20),
              Text(
                'Failed to load products',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please check your connection and try again',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(productsStreamProvider);
                  ref.invalidate(latestProductsStreamProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedSliverProductsSuccess(List<Map<String, dynamic>> products, List<Product> cart) {
    // Your existing filtering logic
    List<Map<String, dynamic>> cleaned = products.where((productMap) {
      final String rawTitle = (productMap['title'] ?? '').toString().trim();
      final String title = rawTitle.toLowerCase();
      final String description = (productMap['description'] ?? '').toString().trim();
      final String sellerName = (productMap['sellerName'] ?? '').toString().trim();
      final bool titleMissingOrDefault = rawTitle.isEmpty || title == 'no title';
      final bool noInfo = description.isEmpty && sellerName.isEmpty;
      final bool isPlaceholder = titleMissingOrDefault && noInfo;
      return !isPlaceholder;
    }).toList();

    if (cleaned.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.all(16),
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No products available yet',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later for new arrivals!',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        key: ValueKey('sleek-products-grid-${cleaned.length}'),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Fixed 2 columns
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.56,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final productMap = cleaned[index];
            final originalImages = productMap['images'] != null 
                ? (productMap['images'] as List).map((e) => e.toString()).toList()
                : null;
            final filteredImages = _getFilteredImages(
              productMap['id']?.toString() ?? 'no-id-$index',
              originalImages
            );
            
            final product = Product(
              id: productMap['id']?.toString() ?? 'no-id-$index',
              title: productMap['title']?.toString() ?? 'No title',
              price: productMap['price'] != null
                  ? int.tryParse(productMap['price'].toString()) ?? 0
                  : 0,
              image: productMap['image']?.toString() ?? 'assets/products/backpack.png',
              images: filteredImages.isNotEmpty ? filteredImages : null,
              sellerName: productMap['sellerName']?.toString(),
              description: productMap['description']?.toString(),
              stockQuantity: productMap['stockQuantity'] != null
                  ? int.tryParse(productMap['stockQuantity'].toString()) ?? 0
                  : 0,
            );
            final inCart = cart.any((p) => p.id == product.id);

            return SleekProductCard(
              key: ValueKey('sleek-product-${product.id}'),
              product: product,
              inCart: inCart,
              onAddToCart: () {
                // Check if product is in stock before adding to cart
                if (product.isInStock) {
                  final cartNotifier = ref.read(cartNotifierProvider.notifier);
                  if (inCart) {
                    cartNotifier.removeProduct(product);
                    ref.read(cartQuantitiesProvider.notifier).remove(product.id);
                  } else {
                    cartNotifier.addProduct(product);
                    ref.read(cartQuantitiesProvider.notifier).setQuantity(product.id, 1);
                  }
                } else {
                  // Show out of stock message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('This item is out of stock'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemScreen(product: product),
                  ),
                );
              },
            );
          },
          childCount: cleaned.length,
        ),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 3;
    if (width > 600) return 2;
    return 1;
  }

  // Get images filtered by deletion state
  List<String> _getFilteredImages(String productId, List<String>? originalImages) {
    final deletionState = ref.read(deletionProvider);
    final deletedIndices = deletionState[productId] ?? [];
    
    if (originalImages == null || originalImages.isEmpty) {
      return [];
    }
    
    final filteredImages = <String>[];
    for (int i = 0; i < originalImages.length; i++) {
      if (!deletedIndices.contains(i.toString())) {
        filteredImages.add(originalImages[i]);
      }
    }
    
    return filteredImages;
  }

  void _navigateToProduct(String productId, List<Map<String, dynamic>> products) {
    final productMap = products.firstWhere(
      (p) => p['id']?.toString() == productId,
      orElse: () => <String, dynamic>{},
    );

    if (productMap.isNotEmpty) {
      final originalImages = productMap['images'] != null 
          ? (productMap['images'] as List).map((e) => e.toString()).toList()
          : null;
      final filteredImages = _getFilteredImages(
        productMap['id']?.toString() ?? productId,
        originalImages
      );
      
      final product = Product(
        id: productMap['id']?.toString() ?? productId,
        title: productMap['title']?.toString() ?? 'Product',
        price: productMap['price'] != null
            ? int.tryParse(productMap['price'].toString()) ?? 0
            : 0,
        image: productMap['image']?.toString() ?? 'assets/products/backpack.png',
        images: filteredImages.isNotEmpty ? filteredImages : null,
        sellerName: productMap['sellerName']?.toString(),
        description: productMap['description']?.toString(),
        stockQuantity: productMap['stockQuantity'] != null
            ? int.tryParse(productMap['stockQuantity'].toString()) ?? 0
            : 0,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ItemScreen(product: product),
        ),
      );
    }
  }
}

// Sleek Product Card Widget - Minimal and Clean
class SleekProductCard extends StatefulWidget {
  final Product product;
  final bool inCart;
  final VoidCallback onAddToCart;
  final VoidCallback onTap;

  const SleekProductCard({
    super.key,
    required this.product,
    required this.inCart,
    required this.onAddToCart,
    required this.onTap,
  });

  @override
  State<SleekProductCard> createState() => _SleekProductCardState();
}

class _SleekProductCardState extends State<SleekProductCard> {
  bool _isPressed = false;



  @override
  Widget build(BuildContext context) {
    final isInStock = widget.product.isInStock;
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              spreadRadius: 5,
              blurRadius: 10,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
               // Image Section
             Expanded(
               flex: 2,
               child: ClipRRect(
                
                 borderRadius: const BorderRadius.only(
                   topLeft: Radius.circular(16),
                   topRight: Radius.circular(16),
                 ),
                 child: Container(
               
                   width: double.infinity,
                   color: Colors.grey[50],
                 child: Hero(
                   tag: 'sleek-product-${widget.product.id}',
                   child: ProductImage(
                     image: widget.product.image,
                     fit: BoxFit.cover,
                   ),
                 ),
               ),
               ),
             ),
            
            // Content Section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stock Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isInStock 
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isInStock 
                              ? Colors.green.withOpacity(0.3)
                              : Colors.red.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isInStock ? Icons.check_circle : Icons.cancel,
                            color: isInStock ? Colors.green : Colors.red,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isInStock ? 'Available' : 'Out of Stock',
                            style: TextStyle(
                              color: isInStock ? Colors.green : Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Product Title with tooltip for long titles
                    TextUtils.buildTruncatedTitleWidget(
                      widget.product.title,
                      maxWords: 4,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      truncatedColor: const Color(0xFF2196F3),
                    ),
                    
                    const Spacer(),
                    
                    // Price and Button Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                                                 // Price
                         Text(
                           '\$${widget.product.price}',
                           style: const TextStyle(
                             fontSize: 16,
                             fontWeight: FontWeight.bold,
                             color: Color(0xFF2196F3),
                           ),
                         ),
                        
                          // Add Button
                         GestureDetector(
                           onTap: isInStock ? widget.onAddToCart : null,
                           child: AnimatedContainer(
                             duration: const Duration(milliseconds: 200),
                             padding: const EdgeInsets.symmetric(
                               horizontal: 8, 
                               vertical: 4,
                             ),
                             decoration: BoxDecoration(
                               color: !isInStock
                                   ? Colors.grey.shade400
                                   : widget.inCart 
                                       ? Colors.orange.shade500
                                       : const Color(0xFF2196F3),
                               borderRadius: BorderRadius.circular(8),
                             ),
                             child: Icon(
                               !isInStock
                                   ? Icons.block
                                   : widget.inCart 
                                       ? Icons.remove_shopping_cart
                                       : Icons.add_shopping_cart,
                               size: 16,
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
    );
  }
}



class MountainClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.7);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}