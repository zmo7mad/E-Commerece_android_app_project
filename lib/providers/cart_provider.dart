import 'package:e_commerece/models/product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cart_provider.g.dart';

@riverpod
class CartNotifier extends _$CartNotifier {
  @override
  Set<Product> build() {
    return const {};
  }

  void addProduct(Product product) {
    // Check if product with same ID already exists
    if (!state.any((p) => p.id == product.id)) {
      state = {...state, product};
    }
  }

  void removeProduct(Product product) {
    // Remove product with same ID
    state = state.where((p) => p.id != product.id).toSet();
  }

  void clearCart() {
    state = const {};
  }
}

@riverpod
int cartTotal(CartTotalRef ref) {
  final cartProducts = ref.watch(cartNotifierProvider);
  int total = 0;
  for (Product product in cartProducts) {
    total += product.price;
  }
  return total;
}


