# Checkout Provider Usage Guide

## Overview
The checkout provider manages the state of the checkout process and automatically clears the cart when a purchase is completed.

## Features
- **State Management**: Tracks checkout status (initial, processing, completed, failed)
- **Automatic Cart Clearing**: Automatically clears the cart when checkout is completed
- **Error Handling**: Provides error messages and failure states
- **Processing States**: Shows loading states during checkout

## Usage

### 1. Basic Setup
```dart
import 'package:e_commerece/providers/checkout_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkoutState = ref.watch(checkoutNotifierProvider);
    
    return ElevatedButton(
      onPressed: checkoutState.isProcessing ? null : _handleCheckout,
      child: Text(checkoutState.isProcessing ? 'Processing...' : 'Checkout'),
    );
  }
}
```

### 2. Starting Checkout
```dart
// Start the checkout process
ref.read(checkoutNotifierProvider.notifier).startProcessing();
```

### 3. Completing Checkout
```dart
// Mark checkout as completed (this will automatically clear the cart)
ref.read(checkoutNotifierProvider.notifier).completeCheckout();
```

### 4. Handling Errors
```dart
// Mark checkout as failed with error message
ref.read(checkoutNotifierProvider.notifier).failCheckout('Payment failed');
```

### 5. Resetting State
```dart
// Reset checkout state to initial
ref.read(checkoutNotifierProvider.notifier).reset();
```

## State Properties

### CheckoutState
- `status`: Current checkout status (CheckoutStatus enum)
- `errorMessage`: Error message if checkout failed
- `isProcessing`: Whether checkout is currently processing

### CheckoutStatus Enum
- `initial`: Default state
- `processing`: Checkout is in progress
- `completed`: Checkout completed successfully
- `failed`: Checkout failed with error

## Automatic Cart Clearing

The checkout provider automatically clears the cart when `completeCheckout()` is called. This is handled through:

1. **Checkout Screen**: Calls `completeCheckout()` when order is successful
2. **Cart Screen**: Listens to checkout state changes and shows confirmation
3. **Cart Provider**: Automatically clears cart items when checkout completes

## Example Integration

### In Checkout Screen
```dart
Future<void> _completeOrder() async {
  // Start processing
  ref.read(checkoutNotifierProvider.notifier).startProcessing();
  
  try {
    // Process order...
    
    // Mark as completed (this clears the cart)
    ref.read(checkoutNotifierProvider.notifier).completeCheckout();
    
    // Navigate to success page
    Navigator.pushReplacement(context, SuccessPage());
  } catch (e) {
    // Handle error
    ref.read(checkoutNotifierProvider.notifier).failCheckout(e.toString());
  }
}
```

### In Cart Screen
```dart
@override
void initState() {
  super.initState();
  
  // Listen to checkout completion
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.listen(checkoutNotifierProvider, (previous, next) {
      if (next.status == CheckoutStatus.completed) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order completed! Cart cleared.')),
        );
      }
    });
  });
}
```

## Benefits

1. **Centralized State**: All checkout logic is managed in one place
2. **Automatic Cart Management**: No need to manually clear cart after purchase
3. **Reactive UI**: UI automatically updates based on checkout state
4. **Error Handling**: Built-in error states and messages
5. **Type Safety**: Strong typing with Riverpod code generation

## Dependencies

- `flutter_riverpod`: State management
- `riverpod_annotation`: Code generation
- `build_runner`: Code generation tool

## Code Generation

After making changes to the checkout provider, run:
```bash
flutter packages pub run build_runner build
```

This generates the necessary `.g.dart` files for Riverpod to work properly.
