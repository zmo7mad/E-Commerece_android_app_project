# Providers Documentation

## Overview

This document covers all Riverpod providers used in the e-commerce application for state management.

## Cart Provider

### Location: `lib/providers/cart_provider.dart`

The cart provider manages the shopping cart state using Riverpod's `@riverpod` annotation.

### CartNotifier Class

```dart
@riverpod
class CartNotifier extends _$CartNotifier {
  @override
  Set<Product> build() {
    return const {};
  }

  void addProduct(Product product) {
    if (!state.contains(product)) {
      state = {...state, product};
    }
  }

  void removeProduct(Product product) {
    if (state.contains(product)) {
      state = state.where((p) => p.id != product.id).toSet();
    }
  }
}
```

#### Generated Provider: `cartNotifierProvider`

- **Type**: `AutoDisposeNotifierProvider<CartNotifier, Set<Product>>`
- **Purpose**: Manages the shopping cart state
- **Initial State**: Empty `Set<Product>`

#### Methods

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `build()` | None | `Set<Product>` | Initializes cart as empty set |
| `addProduct()` | `Product product` | `void` | Adds product if not already in cart |
| `removeProduct()` | `Product product` | `void` | Removes product by ID |

#### Usage Examples

```dart
// Watch cart state
final cartProducts = ref.watch(cartNotifierProvider);

// Add product to cart
ref.read(cartNotifierProvider.notifier).addProduct(product);

// Remove product from cart
ref.read(cartNotifierProvider.notifier).removeProduct(product);
```

### Cart Total Provider

```dart
@riverpod 
int cartTotal(ref) {
  final cartProducts = ref.watch(cartNotifierProvider);
  int total = 0;
  for (Product product in cartProducts) {
    total += product.price;
  }
  return total;
}
```

#### Generated Provider: `cartTotalProvider`

- **Type**: `AutoDisposeProvider<int>`
- **Purpose**: Calculates total price of all items in cart
- **Dependencies**: Watches `cartNotifierProvider`

#### Usage Examples

```dart
// Watch cart total
final total = ref.watch(cartTotalProvider);

// Display total
Text('Total: $total \$')
```

## Products Provider

### Location: `lib/providers/products_providers.dart`

Manages product data and filtering functionality.

### Products Data

```dart
const List<Product> allProducts = [
  Product(id: '1', title: 'backpack', price: 43, image: 'assets/products/backpack.png'),
  Product(id: '2', title: 'guitar', price: 56, image: 'assets/products/guitar.png'),
  Product(id: '3', title: 'drum', price: 55, image: 'assets/products/drum.png'),
  Product(id: '4', title: 'jeans', price: 67, image: 'assets/products/jeans.png'),
  Product(id: '5', title: 'skates', price: 32, image: 'assets/products/skates.png'),
  Product(id: '6', title: 'karati', price: 88, image: 'assets/products/karati.png'),
  Product(id: '7', title: 'shorts', price: 33, image: 'assets/products/shorts.png'),
  Product(id: '8', title: 'suitcase', price: 21, image: 'assets/products/suitcase.png'),
];
```

### All Products Provider

```dart
@riverpod
List<Product> products(ref) {
  return allProducts;
}
```

#### Generated Provider: `productsProvider`

- **Type**: `AutoDisposeProvider<List<Product>>`
- **Purpose**: Provides all available products
- **Data**: Static list of 8 products

#### Usage Examples

```dart
// Watch all products
final allProducts = ref.watch(productsProvider);

// Display in GridView
GridView.builder(
  itemCount: allProducts.length,
  itemBuilder: (context, index) {
    return ProductCard(allProducts[index]);
  },
)
```

### Reduced Products Provider

```dart
@riverpod
List<Product> reducedProducts(ref) {
  return allProducts.where((p) => p.price < 50).toList();
}
```

#### Generated Provider: `reducedProductsProvider`

- **Type**: `AutoDisposeProvider<List<Product>>`
- **Purpose**: Provides products under $50
- **Filter**: Price < 50

#### Usage Examples

```dart
// Watch reduced products
final reducedProducts = ref.watch(reducedProductsProvider);

// Display filtered products
ListView.builder(
  itemCount: reducedProducts.length,
  itemBuilder: (context, index) {
    return ProductCard(reducedProducts[index]);
  },
)
```

## Provider Dependencies

### Dependency Graph

```
cartTotalProvider
    ↓ watches
cartNotifierProvider
    ↓ uses
Product model

productsProvider
    ↓ uses
allProducts (const list)

reducedProductsProvider
    ↓ uses
allProducts (const list)
```

## Code Generation

### Generated Files

- `lib/providers/cart_provider.g.dart`
- `lib/providers/products_providers.g.dart`

### Regeneration Command

```bash
dart run build_runner build
```

### Generated Providers Summary

| Provider | Type | Purpose | Dependencies |
|----------|------|---------|--------------|
| `cartNotifierProvider` | `AutoDisposeNotifierProvider` | Cart state management | None |
| `cartTotalProvider` | `AutoDisposeProvider` | Cart total calculation | `cartNotifierProvider` |
| `productsProvider` | `AutoDisposeProvider` | All products | None |
| `reducedProductsProvider` | `AutoDisposeProvider` | Filtered products | None |

## Best Practices

1. **AutoDispose**: All providers use `AutoDispose` for automatic cleanup
2. **Immutable State**: State updates create new objects rather than modifying existing ones
3. **Separation of Concerns**: Cart and products are managed separately
4. **Reactive Updates**: UI automatically updates when provider state changes
5. **Type Safety**: Strong typing with generics for better compile-time safety 