import 'package:e_commerece/models/product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:e_commerece/shared/firebase.dart';
import 'package:e_commerece/providers/stock_provider.dart';

part 'cart_provider.g.dart';

@riverpod
class CartNotifier extends _$CartNotifier {
  @override
  Set<Product> build() {
    _loadCart();
    return const {};
  }

  Future<void> _loadCart() async {
    final cartData = await loadUserCart();
    final cartList = cartData['cart'] as List<Map<String, dynamic>>;
    final cartProducts = cartList.map((json) => Product.fromMap(json)).toSet();
    state = cartProducts;
  }

  Future<void> reloadFromFirebase() async {
    await _loadCart();
  }

  Future<void> _saveCart() async {
    final cartList = state.map((product) => product.toMap()).toList();
    final quantities = ref.read(cartQuantitiesProvider);
    await saveUserCart(cartList, quantities);
  }

  void addProduct(Product product) {
    if (!state.any((p) => p.id == product.id)) {
      // Check stock availability before adding to cart
      final stockAsync = ref.read(stockProvider);
      final currentStock = stockAsync.when(
        data: (stock) => stock[product.id] ?? 0,
        loading: () => product.stockQuantity,
        error: (_, __) => product.stockQuantity,
      );
      
      if (currentStock > 0) {
        state = {...state, product};
        _saveCart();
      }
    }
  }

  void removeProduct(Product product) {
    state = state.where((p) => p.id != product.id).toSet();
    _saveCart();
  }

  void clearCart() {
    state = const {};
    _saveCart();
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

// Quantities per productId
class CartQuantitiesNotifier extends StateNotifier<Map<String, int>> {
  CartQuantitiesNotifier(this.ref) : super(<String, int>{}) {
    _loadQuantities();
  }

  final Ref ref;

  Future<void> _loadQuantities() async {
    final cartData = await loadUserCart();
    final quantities = cartData['cartQuantities'] as Map<String, int>;
    state = quantities;
  }

  Future<void> reloadFromFirebase() async {
    await _loadQuantities();
  }

  Future<void> _saveQuantities() async {
    final cart = ref.read(cartNotifierProvider);
    final cartList = cart.map((product) => product.toMap()).toList();
    await saveUserCart(cartList, state);
  }

  int getQuantity(String productId) => state[productId] ?? 1;

  void setQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      final newState = {...state};
      newState.remove(productId);
      state = newState;
    } else {
      // Check stock availability before setting quantity
      final stockAsync = ref.read(stockProvider);
      final currentStock = stockAsync.when(
        data: (stock) => stock[productId] ?? 0,
        loading: () => 0,
        error: (_, __) => 0,
      );
      
      // Don't allow quantity to exceed available stock
      final adjustedQuantity = quantity > currentStock ? currentStock : quantity;
      
      state = {
        ...state,
        productId: adjustedQuantity,
      };
    }
    _saveQuantities();
  }

  void increment(String productId) {
    final current = state[productId] ?? 1;
    state = {
      ...state,
      productId: current + 1,
    };
    _saveQuantities();
  }

  void decrement(String productId) {
    final current = state[productId] ?? 1;
    if (current <= 1) {
      final newState = {...state};
      newState.remove(productId);
      state = newState;
    } else {
      state = {
        ...state,
        productId: current - 1,
      };
    }
    _saveQuantities();
  }

  void remove(String productId) {
    final newState = {...state};
    newState.remove(productId);
    state = newState;
    _saveQuantities();
  }

  void clear() {
    state = <String, int>{};
    _saveQuantities();
  }
}

final cartQuantitiesProvider =
    StateNotifierProvider<CartQuantitiesNotifier, Map<String, int>>(
  (ref) => CartQuantitiesNotifier(ref),
);


