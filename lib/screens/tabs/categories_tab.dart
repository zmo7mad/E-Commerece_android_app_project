import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import 'package:e_commerece/shared/firebase.dart';
import 'package:e_commerece/models/product.dart';
import 'package:e_commerece/screens/product/item_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

// REAL-TIME: Use StreamProvider for live category updates
final categoriesProductsProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) => getProductsStream(),
);

String _deriveCategory(String titleOrCategory) {
  final value = titleOrCategory.toLowerCase();
  if (value.contains('guitar') || value.contains('drum')) return 'Music';
  if (value.contains('jeans') || value.contains('shorts')) return 'Clothing';
  if (value.contains('skates') || value.contains('karati')) return 'Sports';
  if (value.contains('backpack') || value.contains('suitcase')) return 'Bags';
  return 'Other';
}

class CategoriesTab extends ConsumerStatefulWidget {
  const CategoriesTab({super.key});

  @override
  ConsumerState<CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends ConsumerState<CategoriesTab> {
  String selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final asyncProducts = ref.watch(categoriesProductsProvider);

    return asyncProducts.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text(
          'Failed to load categories',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      data: (products) {
        // FIXED: Only remove items that are clearly invalid/placeholder
        final validProducts = products.where((productMap) {
          final String title = (productMap['title'] ?? '').toString().trim();
          final String image = (productMap['image'] ?? '').toString().trim();
          
          // Only filter out items with no title or "no title" - allow items with just title and image
          final bool hasValidTitle = title.isNotEmpty && title.toLowerCase() != 'no title';
          final bool hasValidImage = image.isNotEmpty;
          
          return hasValidTitle && hasValidImage;
        }).toList();

        // Build categories list from valid data
        final Set<String> categories = {'All'};
        for (final p in validProducts) {
          final cat = (p['category']?.toString().trim().isNotEmpty == true)
              ? p['category'].toString()
              : _deriveCategory(p['title']?.toString() ?? '');
          categories.add(cat);
        }

        // Filter products by selected category
        final filtered = selectedCategory == 'All'
            ? validProducts
            : validProducts.where((p) {
                final cat = (p['category']?.toString().trim().isNotEmpty == true)
                    ? p['category'].toString()
                    : _deriveCategory(p['title']?.toString() ?? '');
                return cat == selectedCategory;
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
                    Text(
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
                              onTap: () => setState(() => selectedCategory = c),
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
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final p = filtered[index];
                    final String title = (p['title'] ?? '').toString();
                    final int price = p['price'] is int
                        ? p['price'] as int
                        : int.tryParse(p['price']?.toString() ?? '') ?? 0;
                    final String image = (p['image'] ?? '').toString();

                    return OpenContainer(
                      closedElevation: 0,
                      openElevation: 0,
                      transitionDuration: const Duration(milliseconds: 350),
                      transitionType: ContainerTransitionType.fade,
                      openBuilder: (context, close) {
                        // Navigate to item screen requires Product model
                        final product = Product(
                          id: (p['id'] ?? '').toString(),
                          title: title,
                          price: price,
                          image: image,
                          sellerName: p['sellerName']?.toString(),
                          description: p['description']?.toString(),
                        );
                        return ItemScreen(product: product);
                      },
                      closedBuilder: (context, open) {
                        return GestureDetector(
                          onTap: open,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.grey[200]!,
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
                                      child: _ProductImage(image: image),
                                    ),
                                  ),
                                ),
                                // Product Info Section
                                Expanded(
                                  flex: 3,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                            color: Colors.black87,
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '\$${price}',
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
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
                      },
                    );
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
      },
    );
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
      try {
        final uri = Uri.parse(image);
        final data = uri.data;
        if (data != null) {
          return Image.memory(
            data.contentAsBytes(),
            fit: BoxFit.cover,
          );
        }
      } catch (_) {}
      return Image.asset(
        'assets/products/backpack.png',
        fit: BoxFit.cover,
      );
    }
    if (_isNetwork) {
      return CachedNetworkImage(
        imageUrl: image,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Image.asset(
          'assets/products/backpack.png',
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(image, fit: BoxFit.cover);
  }
}