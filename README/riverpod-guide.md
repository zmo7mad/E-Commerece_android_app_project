# Riverpod Implementation Guide

## Overview

This guide covers the Riverpod state management implementation in the e-commerce application, including patterns, best practices, and code generation.

## Riverpod Setup

### Dependencies

```yaml
dependencies:
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3

dev_dependencies:
  build_runner: ^2.4.7
  riverpod_generator: ^2.3.9
```

### App Setup

```dart
// main.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: ECommereceApp()));
}
```

## Provider Types Used

### 1. NotifierProvider (Stateful)

Used for managing cart state with methods to modify state.

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

**Generated Provider**: `cartNotifierProvider`

### 2. Provider (Stateless)

Used for computed values and data access.

```dart
@riverpod
List<Product> products(ref) {
  return allProducts;
}

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

**Generated Providers**: `productsProvider`, `cartTotalProvider`

## Code Generation

### Annotations

#### @riverpod Class

```dart
@riverpod
class CartNotifier extends _$CartNotifier {
  // Implementation
}
```

- **Purpose**: Creates a stateful provider with methods
- **Generated**: `cartNotifierProvider`
- **Type**: `AutoDisposeNotifierProvider<CartNotifier, Set<Product>>`

#### @riverpod Function

```dart
@riverpod
int cartTotal(ref) {
  // Implementation
}
```

- **Purpose**: Creates a computed provider
- **Generated**: `cartTotalProvider`
- **Type**: `AutoDisposeProvider<int>`

### Generated Files

#### cart_provider.g.dart

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'cart_provider.dart';

String _$cartTotalHash() => r'c1c73ff9e529ccfc4f1d57e2074b69db9700c8c0';

@ProviderFor(cartTotal)
final cartTotalProvider = AutoDisposeProvider<int>.internal(
  cartTotal,
  name: r'cartTotalProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cartTotalHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

String _$cartNotifierHash() => r'9c5b34f84dff825cd9e01f5573f2e124a21f4d95';

@ProviderFor(CartNotifier)
final cartNotifierProvider =
    AutoDisposeNotifierProvider<CartNotifier, Set<Product>>.internal(
      CartNotifier.new,
      name: r'cartNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$cartNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );
```

### Regeneration Commands

```bash
# Generate all providers
dart run build_runner build

# Watch for changes and regenerate
dart run build_runner watch

# Clean and regenerate
dart run build_runner clean
dart run build_runner build
```

## Provider Usage Patterns

### 1. Watching State (Reactive UI)

```dart
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartProducts = ref.watch(cartNotifierProvider);
    final allProducts = ref.watch(productsProvider);
    
    // UI automatically rebuilds when state changes
    return Scaffold(
      body: GridView.builder(
        itemCount: allProducts.length,
        itemBuilder: (context, index) {
          final product = allProducts[index];
          final isInCart = cartProducts.contains(product);
          
          return ProductCard(
            product: product,
            isInCart: isInCart,
          );
        },
      ),
    );
  }
}
```

### 2. Reading State (One-time Access)

```dart
// Access provider state without watching
final currentCart = ref.read(cartNotifierProvider);

// Access provider notifier for methods
ref.read(cartNotifierProvider.notifier).addProduct(product);
```

### 3. Conditional UI Based on State

```dart
// Show different buttons based on cart state
if (cartProducts.contains(product))
  TextButton(
    onPressed: () {
      ref.read(cartNotifierProvider.notifier).removeProduct(product);
    },
    child: const Text("remove"),
  ),
else
  TextButton(
    onPressed: () {
      ref.read(cartNotifierProvider.notifier).addProduct(product);
    },
    child: const Text("add to cart"),
  ),
```

## State Management Patterns

### 1. Immutable State Updates

```dart
// ✅ Good: Create new state object
void addProduct(Product product) {
  if (!state.contains(product)) {
    state = {...state, product}; // New Set with added product
  }
}

// ❌ Bad: Modify existing state
void addProduct(Product product) {
  state.add(product); // Don't modify existing state
}
```

### 2. Conditional State Updates

```dart
void removeProduct(Product product) {
  if (state.contains(product)) {
    state = state.where((p) => p.id != product.id).toSet();
  }
}
```

### 3. Computed State

```dart
@riverpod 
int cartTotal(ref) {
  final cartProducts = ref.watch(cartNotifierProvider);
  return cartProducts.fold(0, (total, product) => total + product.price);
}
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
```

### Watching Other Providers

```dart
@riverpod 
int cartTotal(ref) {
  // Watch cartNotifierProvider for changes
  final cartProducts = ref.watch(cartNotifierProvider);
  
  // Calculate total based on cart state
  int total = 0;
  for (Product product in cartProducts) {
    total += product.price;
  }
  return total;
}
```

## AutoDispose Behavior

### Automatic Cleanup

All providers use `AutoDispose` which means:

- **Automatic Cleanup**: Providers are disposed when no longer watched
- **Memory Efficiency**: Reduces memory usage
- **State Reset**: State is reset when provider is recreated

### When AutoDispose Triggers

```dart
// Provider is created when first watched
final cart = ref.watch(cartNotifierProvider);

// Provider is disposed when no widgets are watching it
// This happens when navigating away from screens that use the provider
```

## Error Handling

### Provider Error Handling

```dart
@riverpod
List<Product> products(ref) {
  try {
    return allProducts;
  } catch (e) {
    // Handle errors gracefully
    return [];
  }
}
```

### UI Error Handling

```dart
// Using AsyncValue for async providers
final productsAsync = ref.watch(productsProvider);

productsAsync.when(
  data: (products) => ProductGrid(products: products),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => ErrorWidget(error.toString()),
);
```

## Testing Providers

### Unit Testing

```dart
void main() {
  group('CartNotifier', () {
    test('should add product to cart', () {
      final container = ProviderContainer();
      final notifier = container.read(cartNotifierProvider.notifier);
      
      notifier.addProduct(testProduct);
      
      expect(container.read(cartNotifierProvider), contains(testProduct));
    });
  });
}
```

### Widget Testing

```dart
testWidgets('should display cart count', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(actions: [CartIcon()]),
        ),
      ),
    ),
  );
  
  expect(find.text('0'), findsOneWidget);
});
```

## Performance Optimizations

### 1. Selective Watching

```dart
// ✅ Good: Watch only what you need
final cartCount = ref.watch(cartNotifierProvider).length;

// ❌ Bad: Watch entire cart when you only need count
final cart = ref.watch(cartNotifierProvider);
final cartCount = cart.length;
```

### 2. Computed Providers

```dart
// ✅ Good: Use computed provider for derived state
final total = ref.watch(cartTotalProvider);

// ❌ Bad: Calculate in widget
final cart = ref.watch(cartNotifierProvider);
final total = cart.fold(0, (sum, product) => sum + product.price);
```

### 3. Provider Families (Future Enhancement)

```dart
// For filtering products by category
@riverpod
List<Product> productsByCategory(ref, String category) {
  final allProducts = ref.watch(productsProvider);
  return allProducts.where((p) => p.category == category).toList();
}
```

## Best Practices

### 1. Provider Organization

- **Single Responsibility**: Each provider has one clear purpose
- **Separation of Concerns**: Cart and products managed separately
- **Naming Conventions**: Use descriptive names ending with "Provider"

### 2. State Updates

- **Immutable Updates**: Always create new state objects
- **Conditional Logic**: Check state before updating
- **Error Handling**: Handle edge cases gracefully

### 3. Performance

- **Selective Watching**: Only watch what you need
- **Computed Values**: Use providers for derived state
- **AutoDispose**: Let providers clean up automatically

### 4. Code Generation

- **Regular Regeneration**: Run build_runner after provider changes
- **Clean Generation**: Use clean command when issues arise
- **Version Control**: Don't commit generated files

## Common Patterns

### 1. Loading States

```dart
@riverpod
Future<List<Product>> asyncProducts(ref) async {
  // Simulate API call
  await Future.delayed(Duration(seconds: 1));
  return allProducts;
}
```

### 2. Filtering

```dart
@riverpod
List<Product> filteredProducts(ref, String searchTerm) {
  final products = ref.watch(productsProvider);
  return products.where((p) => 
    p.title.toLowerCase().contains(searchTerm.toLowerCase())
  ).toList();
}
```

### 3. Pagination (Future Enhancement)

```dart
@riverpod
class PaginatedProducts extends _$PaginatedProducts {
  @override
  List<Product> build() {
    return [];
  }

  void loadMore() {
    // Load more products logic
  }
}
```

## Troubleshooting

### Common Issues

1. **Provider Not Found**: Run `dart run build_runner build`
2. **State Not Updating**: Ensure using `ref.watch()` not `ref.read()`
3. **Build Errors**: Check for syntax errors in provider files
4. **Memory Leaks**: Use AutoDispose providers

### Debug Tools

```dart
// Enable provider debugging
void main() {
  runApp(
    ProviderScope(
      child: ECommereceApp(),
      observers: [ProviderLogger()], // Add for debugging
    ),
  );
}
``` 