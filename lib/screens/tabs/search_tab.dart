import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_commerece/models/product.dart';
import 'package:e_commerece/screens/product/item_screen.dart';
import 'package:e_commerece/shared/firebase.dart';

// REAL-TIME: Use StreamProvider for live search updates
final searchProductsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return getProductsStream();
});

class SearchTab extends ConsumerStatefulWidget {
  const SearchTab({super.key});

  @override
  ConsumerState<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<SearchTab> {
  final TextEditingController _queryController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncProducts = ref.watch(searchProductsStreamProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: _queryController,
            onChanged: (value) => setState(() => _query = value.trim()),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search products... (name, seller, category, desc)',
              prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
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
          const SizedBox(height: 20),
          Expanded(
            child: asyncProducts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Failed to load products', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
              data: (products) {
                final lower = _query.toLowerCase();
                final filtered = _query.isEmpty
                    ? <Map<String, dynamic>>[]
                    : products.where((p) {
                        final title = (p['title'] ?? '').toString().toLowerCase();
                        final seller = (p['sellerName'] ?? '').toString().toLowerCase();
                        final category = (p['category'] ?? '').toString().toLowerCase();
                        final description = (p['description'] ?? '').toString().toLowerCase();
                        return title.contains(lower) ||
                            seller.contains(lower) ||
                            category.contains(lower) ||
                            description.contains(lower);
                      }).toList();

                if (_query.isEmpty) {
                  return _SearchPlaceholder();
                }
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No results for "$_query"',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final p = filtered[index];
                    final product = Product(
                      id: (p['id'] ?? '').toString(),
                      title: (p['title'] ?? '').toString(),
                      price: p['price'] != null ? int.tryParse(p['price'].toString()) ?? 0 : 0,
                      image: (p['image'] ?? '').toString(),
                      sellerName: p['sellerName']?.toString(),
                      description: p['description']?.toString(),
                    );

                    return InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ItemScreen(product: product)),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
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
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 56,
                                height: 56,
                                child: _ProductImage(image: product.image),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.title,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '\$${product.price}',
                                        style: TextStyle(color: Theme.of(context).colorScheme.primary),
                                      ),
                                      if ((product.sellerName ?? '').isNotEmpty) ...[
                                        const SizedBox(width: 10),
                                        Icon(Icons.store_mall_directory_outlined, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                                        const SizedBox(width: 4),
                                        Text(
                                          product.sellerName!,
                                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                          ],
                        ),
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

class _SearchPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
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
            'Type to find items by name, seller, category, or description',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
      return Image.asset('assets/products/backpack.png', fit: BoxFit.cover);
    }
    if (_isNetwork) {
      return CachedNetworkImage(
        imageUrl: image,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (context, url, error) => Image.asset('assets/products/backpack.png', fit: BoxFit.cover),
      );
    }
    return Image.asset(image, fit: BoxFit.cover);
  }
}