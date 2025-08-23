import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_commerece/models/product.dart';
import 'package:e_commerece/shared/firebase.dart';

class FavoritesNotifier extends StateNotifier<Set<Product>> {
  FavoritesNotifier() : super(<Product>{}) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favoritesList = await loadUserFavorites();
    final favoritesProducts = favoritesList.map((json) => Product.fromMap(json)).toSet();
    state = favoritesProducts;
  }

  Future<void> reloadFromFirebase() async {
    await _loadFavorites();
  }

  Future<void> _saveFavorites() async {
    final favoritesList = state.map((product) => product.toMap()).toList();
    await saveUserFavorites(favoritesList);
  }

  bool isFavorite(String productId) {
    return state.any((Product p) => p.id == productId);
  }

  void add(Product product) {
    if (!state.any((Product p) => p.id == product.id)) {
      state = {...state, product};
      _saveFavorites();
    }
  }

  void remove(Product product) {
    if (state.any((Product p) => p.id == product.id)) {
      state = state.where((Product p) => p.id != product.id).toSet();
      _saveFavorites();
    }
  }

  void toggle(Product product) {
    if (isFavorite(product.id)) {
      remove(product);
    } else {
      add(product);
    }
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<Product>>(
  (ref) => FavoritesNotifier(),
);


