import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_commerece/shared/firebase.dart';

/// Centralized products stream provider
/// This replaces duplicate stream providers across multiple files
final productsStreamProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) => getProductsStream(),
);

/// Latest products stream provider (for home tab)
final latestProductsStreamProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) => getProductsStream(),
);

/// Search products stream provider (for search tab)
final searchProductsStreamProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) => getProductsStream(),
);

/// Categories products stream provider (for categories tab)
final categoriesProductsStreamProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) => getProductsStream(),
);
