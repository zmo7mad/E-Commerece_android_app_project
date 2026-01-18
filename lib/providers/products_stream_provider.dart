import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_commerece/shared/firebase.dart';

/// All tabs should use this
final productsStreamProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) {
    print('ProductsStreamProvider: Fetching products from Firebase');
    return getProductsStream().handleError((error) {
      print('Stream error in productsStreamProvider: $error');
      // Return empty list on error instead of throwing
      return <Map<String, dynamic>>[];
    });
   
  },
);

/// Computed providers that derive data from the main stream
/// These don't create new streams, they just filter/transform the main one

/// Latest products (for banner/home highlights)
final latestProductsProvider = Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final productsAsync = ref.watch(productsStreamProvider);
  return productsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
    data: (products) {
      // Sort by creation time and return latest
      final sortedProducts = List<Map<String, dynamic>>.from(products);
      sortedProducts.sort((a, b) {
        final aTime = a['createdAt'];
        final bTime = b['createdAt'];
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime); // Newest first
      });
      return AsyncValue.data(sortedProducts.take(10).toList()); // Latest 10
    },
  );
});

/// Categories list provider (derived from products)
final categoriesProvider = Provider<List<String>>((ref) {
  final productsAsync = ref.watch(productsStreamProvider);
  return productsAsync.when(
    loading: () => ['All'],
    error: (_, __) => ['All'],
    data: (products) {
      final Set<String> categories = {'All'};
      for (final product in products) {
        final category = product['category']?.toString().trim();
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }
      return categories.toList();
    },
  );
});

/// Filtered products by category provider
final filteredProductsProvider = Provider.family<List<Map<String, dynamic>>, String>((ref, category) {
  final productsAsync = ref.watch(productsStreamProvider);
  return productsAsync.when(
    loading: () => [],
    error: (_, __) => [],
    data: (products) {
      if (category == 'All') return products;
      
      return products.where((product) {
        final productCategory = product['category']?.toString().trim();
        return productCategory == category;
      }).toList();
    },
  );
});