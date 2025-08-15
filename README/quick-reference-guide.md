# Quick Reference Guide - Checkout System

## 🚀 Quick Start

### **Adding New Checkout States**
```dart
// 1. Add to enum
enum CheckoutStatus {
  initial,
  processing,
  completed,
  failed,
  // Add new state here
  paymentPending,
}

// 2. Add to CheckoutState
class CheckoutState {
  final CheckoutStatus status;
  final String? errorMessage;
  final bool isProcessing;
  // Add new property here
  final bool isPaymentPending;

  const CheckoutState({
    this.status = CheckoutStatus.initial,
    this.errorMessage,
    this.isProcessing = false,
    this.isPaymentPending = false, // Add default value
  });

  // 3. Update copyWith method
  CheckoutState copyWith({
    CheckoutStatus? status,
    String? errorMessage,
    bool? isProcessing,
    bool? isPaymentPending, // Add new parameter
  }) {
    return CheckoutState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      isProcessing: isProcessing ?? this.isProcessing,
      isPaymentPending: isPaymentPending ?? this.isPaymentPending, // Add new property
    );
  }
}

// 4. Add new method to CheckoutNotifier
void setPaymentPending() {
  state = state.copyWith(
    status: CheckoutStatus.paymentPending,
    isPaymentPending: true,
  );
}
```

### **Adding New Cart Functionality**
```dart
// In CartNotifier class
void updateProductQuantity(Product product, int quantity) {
  if (quantity <= 0) {
    removeProduct(product);
  } else {
    // Remove existing and add new quantity
    final currentProducts = state.where((p) => p.id != product.id).toSet();
    for (int i = 0; i < quantity; i++) {
      currentProducts.add(product);
    }
    state = currentProducts;
  }
}

void moveToWishlist(Product product) {
  // Implementation for wishlist functionality
  removeProduct(product);
  // Add to wishlist provider
}
```

## 🔧 Common Operations

### **Checkout State Management**
```dart
// Start checkout
ref.read(checkoutNotifierProvider.notifier).startProcessing();

// Complete checkout
ref.read(checkoutNotifierProvider.notifier).completeCheckout();

// Handle errors
ref.read(checkoutNotifierProvider.notifier).failCheckout('Error message');

// Reset state
ref.read(checkoutNotifierProvider.notifier).reset();

// Check current state
final checkoutState = ref.watch(checkoutNotifierProvider);
if (checkoutState.isCompleted) {
  // Do something
}
```

### **Cart Operations**
```dart
// Add product
ref.read(cartNotifierProvider.notifier).addProduct(product);

// Remove product
ref.read(cartNotifierProvider.notifier).removeProduct(product);

// Clear cart
ref.read(cartNotifierProvider.notifier).clearCart();

// Get cart state
final cartProducts = ref.watch(cartNotifierProvider);
final total = ref.watch(cartTotalProvider);
```

### **UI State Watching**
```dart
// Watch for UI updates
final cartProducts = ref.watch(cartNotifierProvider);
final checkoutState = ref.watch(checkoutNotifierProvider);

// One-time read for actions
ref.read(cartNotifierProvider.notifier).clearCart();
```

## 🐛 Troubleshooting

### **UI Not Updating**
1. **Check if widget is const**: Remove `const` keyword
2. **Verify ConsumerWidget**: Use `ConsumerWidget` or `ConsumerStatefulWidget`
3. **Check provider watching**: Use `ref.watch()` not `ref.read()`
4. **Verify code generation**: Run `flutter packages pub run build_runner build`

### **Cart Not Clearing**
1. **Check checkout completion**: Verify `completeCheckout()` is called
2. **Check cart clearing**: Verify `clearCart()` is called
3. **Check navigation**: Ensure user returns to home screen
4. **Check provider state**: Use debug prints to verify state changes

### **Build Errors**
1. **Missing generated files**: Run build runner
2. **Import errors**: Check provider imports
3. **Type errors**: Verify provider types match usage
4. **Riverpod errors**: Check `@riverpod` annotations

## 📱 Screen Integration

### **Adding Checkout to New Screen**
```dart
import 'package:e_commerece/providers/checkout_provider.dart';
import 'package:e_commerece/providers/cart_provider.dart';

class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkoutState = ref.watch(checkoutNotifierProvider);
    final cartProducts = ref.watch(cartNotifierProvider);
    
    return Scaffold(
      body: Column(
        children: [
          // Show checkout status
          if (checkoutState.isProcessing)
            LinearProgressIndicator(),
          
          // Show cart items
          ...cartProducts.map((product) => ProductCard(product)),
          
          // Checkout button
          ElevatedButton(
            onPressed: checkoutState.isProcessing ? null : _startCheckout,
            child: Text(checkoutState.isProcessing ? 'Processing...' : 'Checkout'),
          ),
        ],
      ),
    );
  }
  
  void _startCheckout(WidgetRef ref) {
    ref.read(checkoutNotifierProvider.notifier).startProcessing();
    // Navigate to checkout screen
  }
}
```

### **Listening to Checkout Events**
```dart
@override
void initState() {
  super.initState();
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.listen(checkoutNotifierProvider, (previous, next) {
      if (next.status == CheckoutStatus.completed) {
        // Handle checkout completion
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order completed!')),
        );
      } else if (next.hasError) {
        // Handle errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${next.errorMessage}')),
        );
      }
    });
  });
}
```

## 🧪 Testing

### **Manual Testing Checklist**
- [ ] Add items to cart
- [ ] Verify buttons change to "Remove"
- [ ] Go to cart screen
- [ ] Proceed to checkout
- [ ] Complete order
- [ ] Verify cart is cleared
- [ ] Return to home
- [ ] Verify buttons are "Add to Cart"

### **Provider Testing**
```dart
// Test checkout state transitions
test('checkout state transitions correctly', () {
  final container = ProviderContainer();
  final checkout = container.read(checkoutNotifierProvider.notifier);
  
  expect(container.read(checkoutNotifierProvider).status, CheckoutStatus.initial);
  
  checkout.startProcessing();
  expect(container.read(checkoutNotifierProvider).isProcessing, true);
  
  checkout.completeCheckout();
  expect(container.read(checkoutNotifierProvider).status, CheckoutStatus.completed);
});
```

## 📚 File Locations

### **Core Files**
- `lib/providers/checkout_provider.dart` - Checkout state management
- `lib/providers/cart_provider.dart` - Cart state management
- `lib/screens/checkout/checkout_screen.dart` - Checkout UI
- `lib/screens/cart/cart_screen.dart` - Cart UI
- `lib/screens/tabs/home_tab.dart` - Home tab with cart integration
- `lib/screens/home/home_screen.dart` - Main screen with tabs

### **Generated Files**
- `lib/providers/checkout_provider.g.dart` - Auto-generated Riverpod code
- `lib/providers/cart_provider.g.dart` - Auto-generated Riverpod code

## 🔄 State Flow

### **Checkout Process**
```
Initial → Processing → Completed → Cart Cleared → UI Updated
   ↓           ↓          ↓           ↓           ↓
startProc() → Firebase → complete() → clearCart() → Rebuild
```

### **Cart State Changes**
```
Cart Empty → Add Product → Cart Has Items → Remove Product → Cart Empty
     ↓           ↓             ↓              ↓           ↓
"Add to Cart" → "Remove" → Button State → "Add to Cart" → Button State
```

## 💡 Best Practices

### **State Management**
- ✅ Use immutable state with `copyWith`
- ✅ Keep state logic in providers
- ✅ Use `ref.watch()` for UI updates
- ✅ Use `ref.read()` for actions

### **Widget Design**
- ✅ Use `ConsumerWidget` for provider state
- ✅ Avoid `const` widgets when state changes
- ✅ Watch only necessary providers
- ✅ Handle loading and error states

### **Error Handling**
- ✅ Always check `mounted` before UI updates
- ✅ Use try-catch blocks for async operations
- ✅ Provide user feedback for errors
- ✅ Reset state after completion

### **Performance**
- ✅ Minimize unnecessary rebuilds
- ✅ Use efficient data structures
- ✅ Dispose resources properly
- ✅ Optimize provider dependencies

## 🚨 Common Mistakes

### **❌ Don't Do This**
```dart
// Don't use const widgets that need state updates
const HomeTab()  // ❌ Won't rebuild

// Don't forget to check mounted
if (mounted) {  // ❌ Missing check
  // UI updates
}

// Don't use ref.read() for UI updates
final cart = ref.read(cartNotifierProvider);  // ❌ Won't rebuild
```

### **✅ Do This Instead**
```dart
// Use non-const widgets for state updates
HomeTab()  // ✅ Will rebuild

// Always check mounted
if (mounted) {  // ✅ Proper check
  // UI updates
}

// Use ref.watch() for UI updates
final cart = ref.watch(cartNotifierProvider);  // ✅ Will rebuild
```

## 🔮 Future Enhancements

### **Planned Features**
- [ ] Payment method selection
- [ ] Shipping options
- [ ] Order tracking
- [ ] Inventory management
- [ ] Wishlist functionality
- [ ] Order history
- [ ] Discount codes
- [ ] Multiple currencies

### **Implementation Notes**
- Extend `CheckoutState` for new properties
- Add new methods to `CheckoutNotifier`
- Update UI screens to use new state
- Run build runner after changes
- Test thoroughly before deployment

---

**Remember**: Always run `flutter packages pub run build_runner build` after modifying provider files!
