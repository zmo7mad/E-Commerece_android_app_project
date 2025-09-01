import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_commerece/models/product.dart';
import 'package:e_commerece/screens/product/item_screen.dart';
import 'package:e_commerece/providers/cart_provider.dart';
import 'package:e_commerece/providers/products_stream_provider.dart';
import 'package:e_commerece/shared/widgets/product_image.dart';
import 'package:e_commerece/shared/widgets/text_utils.dart';
import 'package:e_commerece/shared/widgets/stock_utils.dart';
import 'package:e_commerece/shared/widgets/category_utils.dart';
import 'package:e_commerece/providers/stock_provider.dart';

class SearchTab extends ConsumerStatefulWidget {
  const SearchTab({super.key});

  @override
  ConsumerState<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<SearchTab> with WidgetsBindingObserver {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _query = '';
  
  // Filter states
  String _selectedCategory = 'All';
  RangeValues _priceRange = const RangeValues(0, 1000);
  String _sortBy = 'newest'; // newest, price_low, price_high, name
  bool _showFilters = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Delay initialization to ensure proper widget setup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _initializeStockProvider();
      }
    });
  }

  void _initializeStockProvider() {
    // Initialize stock provider with product data
    final asyncProducts = ref.read(searchProductsStreamProvider);
    asyncProducts.whenData((products) {
      StockUtils.initializeStockProvider(ref, products);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed && mounted) {
      // Force a rebuild when app resumes to ensure proper state
      setState(() {});
    }
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> products) {
    var filtered = products.where((p) {
      // Text search filter
      if (_query.isNotEmpty) {
        final lower = _query.toLowerCase();
        final title = (p['title'] ?? '').toString().toLowerCase();
        final seller = (p['sellerName'] ?? '').toString().toLowerCase();
        final category = (p['category'] ?? '').toString().toLowerCase();
        final description = (p['description'] ?? '').toString().toLowerCase();
        
        final matches = title.contains(lower) ||
            seller.contains(lower) ||
            category.contains(lower) ||
            description.contains(lower);
        
        if (!matches) return false;
      }
      
      // Category filter
      if (_selectedCategory != 'All') {
        final cat = (p['category']?.toString().trim().isNotEmpty == true)
            ? p['category'].toString()
            : CategoryUtils.deriveCategory(p['title']?.toString() ?? '');
        if (cat != _selectedCategory) return false;
      }
      
      // Price filter
      final price = p['price'] != null ? 
          (int.tryParse(p['price'].toString()) ?? 0).toDouble() : 0.0;
      if (price < _priceRange.start || price > _priceRange.end) return false;
      
      return true;
    }).toList();

    // Apply sorting
    if (_sortBy != 'newest') {
      filtered.sort((a, b) {
        switch (_sortBy) {
          case 'price_low':
            final priceA = int.tryParse(a['price']?.toString() ?? '0') ?? 0;
            final priceB = int.tryParse(b['price']?.toString() ?? '0') ?? 0;
            return priceA.compareTo(priceB);
          case 'price_high':
            final priceA = int.tryParse(a['price']?.toString() ?? '0') ?? 0;
            final priceB = int.tryParse(b['price']?.toString() ?? '0') ?? 0;
            return priceB.compareTo(priceA);
          case 'name':
            final titleA = (a['title'] ?? '').toString().toLowerCase();
            final titleB = (b['title'] ?? '').toString().toLowerCase();
            return titleA.compareTo(titleB);
          default:
            return 0;
        }
      });
    }

    return filtered;
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = 'All';
      _priceRange = const RangeValues(0, 1000);
      _sortBy = 'newest';
    });
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

    final asyncProducts = ref.watch(searchProductsStreamProvider);
    final stock = ref.watch(stockProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false, // Changed to false to prevent keyboard resize
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable content that includes search bar and filters
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  children: [
                    // Search Bar Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Search Bar
                          TextField(
                            controller: _queryController,
                            onChanged: (value) => setState(() => _query = value.trim()),
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'Search products... (name, seller, category, desc)',
                              prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showFilters ? Icons.filter_list : Icons.tune,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                onPressed: () {
                                  // Hide keyboard when toggling filters
                                  FocusScope.of(context).unfocus();
                                  setState(() => _showFilters = !_showFilters);
                                },
                              ),
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
                            ),
                          ),
                          
                          // Filter Panel
                          if (_showFilters) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Filters',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: _resetFilters,
                                        child: const Text('Reset All'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Category Filter
                                  asyncProducts.when(
                                    loading: () => const SizedBox(),
                                    error: (_, __) => const SizedBox(),
                                    data: (products) {
                                      final categories = {'All'};
                                      for (final p in products) {
                                        final cat = (p['category']?.toString().trim().isNotEmpty == true)
                                            ? p['category'].toString()
                                            : CategoryUtils.deriveCategory(p['title']?.toString() ?? '');
                                        categories.add(cat);
                                      }
                                      
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Category', style: TextStyle(fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            children: categories.map((category) {
                                              final isSelected = _selectedCategory == category;
                                              return FilterChip(
                                                label: Text(category),
                                                selected: isSelected,
                                                onSelected: (_) => setState(() => _selectedCategory = category),
                                                selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                                checkmarkColor: Theme.of(context).colorScheme.primary,
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Price Range Filter
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Price Range: \$${_priceRange.start.round()} - \$${_priceRange.end.round()}',
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      RangeSlider(
                                        values: _priceRange,
                                        min: 0,
                                        max: 1000,
                                        divisions: 20,
                                        onChanged: (values) => setState(() => _priceRange = values),
                                        activeColor: Theme.of(context).colorScheme.primary,
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  // Sort Options
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Sort By', style: TextStyle(fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        children: [
                                          _SortChip(
                                            label: 'Newest',
                                            value: 'newest',
                                            groupValue: _sortBy,
                                            onSelected: (value) => setState(() => _sortBy = value),
                                          ),
                                          _SortChip(
                                            label: 'Price: Low to High',
                                            value: 'price_low',
                                            groupValue: _sortBy,
                                            onSelected: (value) => setState(() => _sortBy = value),
                                          ),
                                          _SortChip(
                                            label: 'Price: High to Low',
                                            value: 'price_high',
                                            groupValue: _sortBy,
                                            onSelected: (value) => setState(() => _sortBy = value),
                                          ),
                                          _SortChip(
                                            label: 'Name A-Z',
                                            value: 'name',
                                            groupValue: _sortBy,
                                            onSelected: (value) => setState(() => _sortBy = value),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Products Results
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          
                          asyncProducts.when(
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (err, stack) => Center(
                              child: Text('Failed to load products', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                            ),
                            data: (products) {
                              // Sync stock provider with current products
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                StockUtils.initializeStockProvider(ref, products);
                              });
                              final filtered = _applyFilters(products);

                              if (_query.isEmpty && _selectedCategory == 'All' && _priceRange.start == 0 && _priceRange.end == 1000) {
                                return _SearchPlaceholder();
                              }
                              
                              if (filtered.isEmpty) {
                                return SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.4,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          size: 64,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No products found',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Try adjusting your filters or search terms',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return Column(
                                children: [
                                  // Results count
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        Text(
                                          '${filtered.length} result${filtered.length == 1 ? '' : 's'} found',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Results list
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final p = filtered[index];
                                      final product = Product(
                                        id: (p['id'] ?? '').toString(),
                                        title: (p['title'] ?? '').toString(),
                                        price: p['price'] != null ? int.tryParse(p['price'].toString()) ?? 0 : 0,
                                        image: (p['image'] ?? '').toString(),
                                        images: p['images'] != null 
                                            ? (p['images'] as List).map((e) => e.toString()).toList()
                                            : null,
                                        sellerName: p['sellerName']?.toString(),
                                        description: p['description']?.toString(),
                                        stockQuantity: p['stockQuantity'] != null ? int.tryParse(p['stockQuantity'].toString()) ?? 0 : 0,
                                      );
                                      
                                      // Get cart and stock information
                                      final cartProducts = ref.watch(cartNotifierProvider);
                                      final isInCart = cartProducts.any((cartProduct) => cartProduct.id == product.id);

                                      return Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surface,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Theme.of(context).colorScheme.shadow.withOpacity(0.06),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(12),
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => ItemScreen(product: product),
                                                ),
                                              );
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Row(
                                                children: [
                                                  // Product Image
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: SizedBox(
                                                      width: 80,
                                                      height: 80,
                                                      child: ProductImage(
                                                        image: product.image,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  // Product Details
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          product.title,
                                                          style: const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const SizedBox(height: 4),
                                                        if (product.sellerName != null) ...[
                                                          Text(
                                                            'by ${product.sellerName}',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                                            ),
                                                          ),
                                                          const SizedBox(height: 4),
                                                        ],
                                                        Row(
                                                          children: [
                                                            Text(
                                                              '\$${product.price}',
                                                              style: TextStyle(
                                                                fontSize: 18,
                                                                fontWeight: FontWeight.bold,
                                                                color: Theme.of(context).colorScheme.primary,
                                                              ),
                                                            ),
                                                            const Spacer(),
                                                            // Stock indicator
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                              decoration: BoxDecoration(
                                                                color: product.stockQuantity > 0 
                                                                    ? Colors.green.withOpacity(0.1)
                                                                    : Colors.red.withOpacity(0.1),
                                                                borderRadius: BorderRadius.circular(12),
                                                                border: Border.all(
                                                                  color: product.stockQuantity > 0 
                                                                      ? Colors.green.withOpacity(0.3)
                                                                      : Colors.red.withOpacity(0.3),
                                                                  width: 1,
                                                                ),
                                                              ),
                                                              child: Row(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  Icon(
                                                                    product.stockQuantity > 0 ? Icons.check_circle : Icons.cancel,
                                                                    size: 12,
                                                                    color: product.stockQuantity > 0 ? Colors.green : Colors.red,
                                                                  ),
                                                                  const SizedBox(width: 4),
                                                                  Text(
                                                                    product.stockQuantity > 0 ? 'In Stock' : 'Out of Stock',
                                                                    style: TextStyle(
                                                                      fontSize: 10,
                                                                      fontWeight: FontWeight.w600,
                                                                      color: product.stockQuantity > 0 ? Colors.green : Colors.red,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  // Add to Cart Button
                                                  SizedBox(
                                                    width: 80,
                                                    child: ElevatedButton(
                                                      onPressed: product.stockQuantity > 0
                                                          ? () {
                                                              final cartNotifier = ref.read(cartNotifierProvider.notifier);
                                                              if (isInCart) {
                                                                cartNotifier.removeProduct(product);
                                                              } else {
                                                                cartNotifier.addProduct(product);
                                                              }
                                                            }
                                                          : null,
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: isInCart
                                                            ? Theme.of(context).colorScheme.error
                                                            : Theme.of(context).colorScheme.primary,
                                                        foregroundColor: Colors.white,
                                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                      ),
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            isInCart ? Icons.remove_shopping_cart : Icons.add_shopping_cart,
                                                            size: 16,
                                                            color: Colors.white,
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            isInCart
                                                                ? 'Remove'
                                                                : 'Add to Cart',
                                                            style: const TextStyle(
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.w600,
                                                              color: Colors.white,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  // Add bottom padding for keyboard
                                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
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

class _SortChip extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onSelected;

  const _SortChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }
}

class _SearchPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Search Products',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Type to find items or use filters to browse',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}