import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_commerece/models/product.dart';
import 'package:e_commerece/providers/cart_provider.dart';
import 'package:e_commerece/providers/favorites_provider.dart';
import 'package:e_commerece/providers/stock_provider.dart';
import 'package:e_commerece/providers/products_stream_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_commerece/screens/product/edit_product_screen.dart';
import 'package:e_commerece/shared/widgets/multi_image_viewer.dart';
import 'package:e_commerece/providers/deletion_provider.dart';
import 'package:e_commerece/providers/user_role_provider.dart';


class ItemScreen extends ConsumerStatefulWidget {
  final Product product;
  
  const ItemScreen({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<ItemScreen> createState() => _ItemScreenState();
}

class _ItemScreenState extends ConsumerState<ItemScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  int quantity = 1;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations with a delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });

    // Initialize quantity from cart if already present
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final existingQuantity = ref.read(cartQuantitiesProvider)[widget.product.id];
        if (existingQuantity != null && existingQuantity > 0) {
          setState(() {
            quantity = existingQuantity;
          });
        }
      } catch (_) {
        // If ref is not available yet for some reason, ignore and keep default quantity
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // Get current product from stream
  Product _getCurrentProduct(List<Map<String, dynamic>> products) {
    try {
      final updatedProductMap = products.firstWhere(
        (p) => p['id'] == widget.product.id,
        orElse: () => widget.product.toMap(),
      );
      return Product.fromMap(updatedProductMap);
    } catch (e) {
      return widget.product;
    }
  }

  // Get images filtered by deletion state
  List<String> _getFilteredImages(Product product) {
    final deletionState = ref.read(deletionProvider);
    final deletedIndices = deletionState[product.id] ?? [];
    
    final allImages = product.allImages;
    final filteredImages = <String>[];
    
    for (int i = 0; i < allImages.length; i++) {
      if (!deletedIndices.contains(i.toString())) {
        filteredImages.add(allImages[i]);
      }
    }
    
    // If all images are deleted, return at least the main image
    if (filteredImages.isEmpty) {
      return [product.image];
    }
    
    return filteredImages;
  }

  @override
  Widget build(BuildContext context) {
    // Watch products stream to get real-time updates
    final productsAsync = ref.watch(productsStreamProvider);
    
    return productsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Error loading product: $error'),
        ),
      ),
      data: (products) {
        // Get the current product from the stream
        final _product = _getCurrentProduct(products);
        
        final cartProducts = ref.watch(cartNotifierProvider);
        final cartQuantities = ref.watch(cartQuantitiesProvider);
        final isInCart = cartProducts.any((p) => p.id == _product.id);
        
        // Use stock information from the current product
        final currentStock = _product.stockQuantity;
        final isInStock = _product.isInStock;
        final hasSufficientStock = currentStock >= quantity;
        
        // Sync local quantity with cart quantity when item is in cart
        if (isInCart) {
          final cartQuantity = cartQuantities[_product.id] ?? 1;
          if (cartQuantity != quantity) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  quantity = cartQuantity;
                });
              }
            });
          }
        }
        
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: CustomScrollView(
            slivers: [
              // Custom App Bar with Hero Image
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                backgroundColor: Theme.of(context).colorScheme.surface,
                elevation: 0,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                actions: [
                  // Edit Button - Only show for sellers
                  Consumer(
                    builder: (context, ref, child) {
                      final userRoleAsync = ref.watch(autoRefreshUserRoleProvider);
                      final isSeller = userRoleAsync.when(
                        data: (role) => role == 'seller',
                        loading: () => false,
                        error: (_, __) => false,
                      );
                      if (!isSeller) return const SizedBox.shrink();
                      
                      return Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProductScreen(product: _product),
                              ),
                            );
                            // No need to handle result since we're watching the stream
                          },
                        ),
                      );
                    },
                  ),
                  // Favorite Button
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: () {
                        setState(() {
                          isFavorite = !isFavorite;
                        });
                        ref.read(favoritesProvider.notifier).toggle(_product);
                      },
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
                          Theme.of(context).colorScheme.surface,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Hero(
                        tag: 'product-${_product.id}',
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          child: MultiImageViewer(
                            images: _getFilteredImages(_product),
                            height: 250,
                            width: 250,
                            fit: BoxFit.contain,
                            showIndicators: false,
                            autoPlayInterval: const Duration(seconds: 2),
                            autoPlay: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Product Details
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Title and Price
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _product.title.toUpperCase(),
                                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (_product.sellerName != null && _product.sellerName!.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.store_outlined,
                                                size: 14,
                                                color: Theme.of(context).colorScheme.secondary,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Sold by ${_product.sellerName}',
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.secondary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'Premium Quality',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context).colorScheme.primary,
                                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '\$${_product.price}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Stock Status Section
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isInStock 
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isInStock 
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.red.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isInStock ? Icons.check_circle : Icons.cancel,
                                    color: isInStock ? Colors.green : Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isInStock ? 'Available' : 'Out of Stock',
                                          style: TextStyle(
                                            color: isInStock ? Colors.green : Colors.red,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (isInStock) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            '$currentStock items in stock',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            
                            // Description Section
                            Text(
                              'Description',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _product.description?.isNotEmpty == true 
                                ? _product.description!
                                : 'This premium ${_product.title} is crafted with the finest materials and attention to detail. Perfect for everyday use with exceptional durability and style that meets modern standards.',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                height: 1.6,
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Features
                            Text(
                              'Features',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildFeatureItem('Premium Quality Materials'),
                            _buildFeatureItem('Durable Construction'),
                            _buildFeatureItem('Modern Design'),
                            _buildFeatureItem('Easy to Use'),
                            
                            const SizedBox(height: 32),
                            
                            // Quantity Selector
                            Row(
                              children: [
                                Text(
                                  'Quantity',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Row(
                                    children: [
                                      _buildQuantityButton(
                                        icon: Icons.remove,
                                        onPressed: quantity > 1 ? () {
                                          setState(() => quantity--);
                                          if (isInCart) {
                                            ref.read(cartQuantitiesProvider.notifier).setQuantity(_product.id, quantity);
                                          }
                                        } : null,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20),
                                        child: Text(
                                          quantity.toString(),
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      _buildQuantityButton(
                                        icon: Icons.add,
                                        onPressed: quantity < currentStock ? () {
                                          setState(() => quantity++);
                                          if (isInCart) {
                                            ref.read(cartQuantitiesProvider.notifier).setQuantity(_product.id, quantity);
                                          }
                                        } : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Add to Cart Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: isInStock && hasSufficientStock ? () {
                                  if (isInCart) {
                                    ref.read(cartNotifierProvider.notifier).removeProduct(_product);
                                    ref.read(cartQuantitiesProvider.notifier).remove(_product.id);
                                  } else {
                                    ref.read(cartNotifierProvider.notifier).addProduct(_product);
                                    ref.read(cartQuantitiesProvider.notifier)
                                        .setQuantity(_product.id, quantity);
                                  }
                                } : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: !isInStock || !hasSufficientStock
                                      ? Colors.grey
                                      : isInCart 
                                          ? Colors.orange 
                                          : Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 8,
                                  shadowColor: (!isInStock || !hasSufficientStock
                                          ? Colors.grey
                                          : isInCart 
                                              ? Colors.orange 
                                              : Theme.of(context).colorScheme.primary)
                                      .withOpacity(0.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      !isInStock || !hasSufficientStock
                                          ? Icons.block
                                          : isInCart 
                                              ? Icons.remove_shopping_cart 
                                              : Icons.add_shopping_cart,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      !isInStock || !hasSufficientStock
                                          ? 'Out of Stock'
                                          : isInCart 
                                              ? 'Remove from Cart' 
                                              : 'Add to Cart',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      height: 50,
      width: 50,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: onPressed != null 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          foregroundColor: onPressed != null 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
        ),
      ),
    );
  }
}