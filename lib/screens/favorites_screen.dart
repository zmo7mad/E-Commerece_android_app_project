import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_commerece/providers/favorites_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';


class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider).toList();

    return Scaffold(
      appBar: AppBar(
        title:  Text('Favorites',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
        ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.primary,),
        ),
      ),
      body: favorites.isEmpty
          ? Center(
              child: Text(
                'No favorites yet',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final product = favorites[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                      Container(
                        width: 56,
                        height: 56,
                        child: _ProductImage(image: product.image),
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
                            Text('${product.price}\$',
                                style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          ref.read(favoritesProvider.notifier).remove(product);
                        },
                      )
                    ],
                  ),
                );
              },
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
      // Data URL: decode and render
      try {
        final uri = Uri.parse(image);
        final data = uri.data; // data URI
        if (data != null) {
          return Image.memory(
            data.contentAsBytes(), 
            fit: BoxFit.cover,
            width: 56,
            height: 56,
          );
        }
      } catch (_) {}
      return Image.asset(
        'assets/products/backpack.png', 
        fit: BoxFit.cover,
        width: 56,
        height: 56,
      );
    }
    if (_isNetwork) {
      return CachedNetworkImage(
        imageUrl: image,
        fit: BoxFit.cover,
        width: 56,
        height: 56,
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



