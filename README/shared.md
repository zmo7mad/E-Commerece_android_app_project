# Shared Components Documentation

## Overview

This document covers reusable UI components shared across multiple screens in the e-commerce application.

## Cart Icon Component

### Location: `lib/shared/cart_icon.dart`

A reusable cart icon widget with a badge showing the number of items in the cart.

### Class Definition

```dart
class CartIcon extends ConsumerWidget {
  const CartIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Implementation
  }
}
```

### Features

- **Shopping Bag Icon**: Material Design shopping bag icon
- **Item Count Badge**: Red badge showing cart item count
- **Navigation**: Taps navigate to cart screen
- **Real-time Updates**: Badge updates automatically when cart changes

### UI Structure

```
Stack
├── IconButton (Shopping Bag)
│   ├── onPressed: Navigation to CartScreen
│   └── icon: Icons.shopping_bag_outlined
└── Positioned Badge
    └── Container
        ├── Decoration: Blue rounded background
        └── Child: Text (item count)
```

### Implementation Details

#### State Management

```dart
final numberOfItemsInCart = ref.watch(cartNotifierProvider).length;
```

- **Provider**: Watches `cartNotifierProvider` for cart state
- **Reactive**: Automatically updates when cart items change
- **Type**: Returns `int` representing cart item count

#### Icon Button

```dart
IconButton(
  onPressed: () {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return const CartScreen();
    }));
  },
  icon: const Icon(Icons.shopping_bag_outlined),
)
```

- **Icon**: Material Design shopping bag outline icon
- **Navigation**: Pushes `CartScreen` onto navigation stack
- **Route**: Uses `MaterialPageRoute` for smooth transitions

#### Badge Implementation

```dart
Positioned(
  top: 5,
  left: 5,
  child: Container(
    width: 18,
    height: 18,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: Colors.blueAccent,
    ),
    child: Text(
      numberOfItemsInCart.toString(),
      style: const TextStyle(color: Colors.white, fontSize: 12),
    ),
  ),
)
```

#### Badge Properties

| Property | Value | Description |
|----------|-------|-------------|
| **Position** | `top: 5, left: 5` | Offset from icon top-left corner |
| **Size** | `18x18` | Fixed size for consistent appearance |
| **Shape** | `BorderRadius.circular(10)` | Rounded corners |
| **Color** | `Colors.blueAccent` | Blue background |
| **Text Color** | `Colors.white` | White text for contrast |
| **Font Size** | `12` | Small, readable text |

### Usage Examples

#### In AppBar Actions

```dart
AppBar(
  title: const Text('Products'),
  actions: [CartIcon()], // Add to app bar
)
```

#### In Custom Widget

```dart
Row(
  children: [
    Text('Shopping Cart'),
    const SizedBox(width: 8),
    CartIcon(), // Standalone usage
  ],
)
```

### Design Considerations

#### Responsive Design

- **Fixed Badge Size**: 18x18px ensures consistency across devices
- **Positioning**: Absolute positioning relative to icon
- **Text Scaling**: Font size 12px remains readable on all screens

#### Accessibility

- **Semantic Meaning**: Shopping bag icon clearly indicates cart functionality
- **Touch Target**: IconButton provides adequate touch area
- **Visual Feedback**: Badge provides immediate visual feedback

#### Performance

- **Efficient Updates**: Only rebuilds when cart count changes
- **Minimal Widget Tree**: Simple structure for fast rendering
- **Asset Loading**: Uses built-in Material icons (no external assets)

### Integration Points

#### Navigation

- **Target Screen**: `CartScreen`
- **Navigation Method**: `Navigator.push()`
- **Route Type**: `MaterialPageRoute`

#### State Management

- **Provider**: `cartNotifierProvider`
- **Watch Pattern**: `ref.watch()` for reactive updates
- **Data Access**: `.length` property of cart Set

### Customization Options

#### Badge Styling

```dart
// Custom badge colors
decoration: BoxDecoration(
  borderRadius: BorderRadius.circular(10),
  color: Colors.red, // Custom color
  boxShadow: [BoxShadow(...)], // Add shadow
)
```

#### Icon Customization

```dart
// Custom icon
icon: const Icon(
  Icons.shopping_cart, // Different icon
  size: 24, // Custom size
  color: Colors.blue, // Custom color
)
```

#### Badge Position

```dart
// Custom positioning
Positioned(
  top: 8, // Custom top offset
  right: 8, // Right-aligned badge
  child: Container(...),
)
```

### Best Practices

1. **Consistent Usage**: Use in app bars for consistent navigation
2. **State Management**: Always use Riverpod for cart state
3. **Performance**: Keep widget lightweight for frequent updates
4. **Accessibility**: Ensure adequate touch targets and semantic meaning
5. **Testing**: Test with various cart states (empty, single item, multiple items)

### Future Enhancements

#### Potential Features

- **Animation**: Smooth badge count transitions
- **Haptic Feedback**: Vibration on tap
- **Custom Badge**: Different badge styles (dots, numbers, etc.)
- **Badge Visibility**: Hide badge when cart is empty
- **Multiple Carts**: Support for different cart types

#### Animation Example

```dart
// Future animation implementation
AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  width: numberOfItemsInCart > 0 ? 18 : 0,
  child: Text(numberOfItemsInCart.toString()),
)
```

### Error Handling

#### Edge Cases

- **Empty Cart**: Badge shows "0" or can be hidden
- **Large Numbers**: Text remains readable within badge bounds
- **Navigation Errors**: Graceful handling of navigation failures

#### Defensive Programming

```dart
// Safe navigation
onPressed: () {
  try {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return const CartScreen();
    }));
  } catch (e) {
    // Handle navigation errors
    print('Navigation error: $e');
  }
}
``` 