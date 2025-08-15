# Screens Documentation

## Overview

This document covers all UI screens in the e-commerce application, their functionality, and implementation details.

## Home Screen

### Location: `lib/screens/home/home_screen.dart`

The main product catalog screen displaying all available products in a grid layout.

### Class Definition

```dart
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Implementation
  }
}
```

### Features

- **Product Grid**: Displays products in a 2-column responsive grid
- **Add/Remove Cart**: Dynamic buttons based on cart state
- **Cart Icon**: Badge showing cart item count in app bar
- **Real-time Updates**: UI updates automatically when cart changes

### UI Structure

```
Scaffold
├── AppBar
│   ├── Title: "the available products"
│   └── Actions: [CartIcon]
└── Body
    └── Padding
        └── GridView.builder
            └── Product Containers
                ├── Product Image
                ├── Product Title
                ├── Product Price
                └── Add/Remove Button
```

### Key Components

#### AppBar Configuration

```dart
AppBar(
  title: const Text(
    'the available products', 
    style: TextStyle(
      color: Colors.black, 
      fontSize: 20, 
      fontWeight: FontWeight.bold,
    ),
    textAlign: TextAlign.center
  ),
  actions: [CartIcon()],
)
```

#### GridView Configuration

```dart
GridView.builder(
  itemCount: allproducts.length,
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: 20,
    crossAxisSpacing: 20,
    childAspectRatio: 0.9,
  ),
  itemBuilder: (context, index) {
    // Product container
  },
)
```

#### Product Container

```dart
Container(
  padding: const EdgeInsets.all(20),
  color: Colors.blueGrey.withOpacity(0.05),
  child: Column(
    children: [
      Image.asset(allproducts[index].image, height: 50, width: 50),
      Text(allproducts[index].title),
      Text("${allproducts[index].price} \$"),
      // Conditional Add/Remove button
    ],
  ),
)
```

#### Dynamic Cart Buttons

```dart
// Show "Remove" if product is in cart
if (cartProducts.contains(allproducts[index]))
  TextButton(
    onPressed: () {
      ref.read(cartNotifierProvider.notifier)
        .removeProduct(allproducts[index]);
    },
    child: const Text("remove"),
  ),

// Show "Add to cart" if product is not in cart
if (!cartProducts.contains(allproducts[index]))
  TextButton(
    onPressed: () {
      ref.read(cartNotifierProvider.notifier)
        .addProduct(allproducts[index]);
    },
    child: const Text("add to cart"),
  ),
```

### State Management

#### Watched Providers

```dart
final allproducts = ref.watch(productsProvider);
final cartProducts = ref.watch(cartNotifierProvider);
```

#### Provider Interactions

- **Read Operations**: `ref.read(cartNotifierProvider.notifier)` for cart modifications
- **Watch Operations**: `ref.watch()` for reactive UI updates

### Responsive Design

- **Grid Layout**: 2 columns with responsive spacing
- **Aspect Ratio**: 0.9 for consistent product card proportions
- **Spacing**: 20px between grid items
- **Padding**: 20px container padding

## Cart Screen

### Location: `lib/screens/cart/cart_screen.dart`

The shopping cart screen displaying all items in the cart with total calculation.

### Class Definition

```dart
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool showCoupon = true; // Future feature

  @override
  Widget build(BuildContext context) {
    // Implementation
  }
}
```

### Features

- **Cart Items List**: Displays all products in cart
- **Total Calculation**: Shows total price of all items
- **Product Details**: Image, title, and price for each item
- **Navigation**: Accessible via cart icon in app bar

### UI Structure

```
Scaffold
├── AppBar
│   └── Title: "Your Cart"
└── Body
    └── Container
        └── Column
            ├── Cart Items Column
            │   └── Product Rows
            │       ├── Product Image
            │       ├── Product Title
            │       └── Product Price
            └── Total Display
```

### Key Components

#### AppBar Configuration

```dart
AppBar(
  title: const Text('Your Cart'),
  centerTitle: true,
)
```

#### Cart Items Display

```dart
Column(
  children: cartProducts.map((product) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10, top: 10),
      child: Row(
        children: [
          Image.asset(
            product.image,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
          const SizedBox(width: 10),
          Text('${product.title}... '),
          const Expanded(child: SizedBox()),
          Text('${product.price} \$'),
        ],
      ),
    );
  }).toList(),
)
```

#### Total Display

```dart
Text('Total: $total \$')
```

### State Management

#### Watched Providers

```dart
final cartProducts = ref.watch(cartNotifierProvider);
final total = ref.watch(cartTotalProvider);
```

### Navigation

#### Access from Home Screen

```dart
// In CartIcon widget
Navigator.push(
  context, 
  MaterialPageRoute(builder: (context) {
    return const CartScreen();
  })
);
```

### Design Features

- **Product Images**: 60x60px with cover fit
- **Row Layout**: Horizontal arrangement for each product
- **Spacing**: 10px between image and text
- **Expanded Spacer**: Pushes price to the right
- **Container Padding**: 10px top and bottom for each item

### Future Enhancements

- **Remove Items**: Individual remove buttons for each product
- **Quantity Controls**: Increase/decrease quantity for each item
- **Coupon System**: Discount code functionality (showCoupon variable)
- **Checkout Process**: Proceed to payment screen

## Screen Navigation Flow

```
App Launch
    ↓
HomeScreen (Product Catalog)
    ↓ (via CartIcon)
CartScreen (Shopping Cart)
    ↓ (back button)
HomeScreen
```

## Responsive Considerations

### Grid Layout
- **Cross Axis Count**: 2 columns for mobile
- **Aspect Ratio**: 0.9 maintains consistent card proportions
- **Spacing**: 20px provides adequate breathing room

### List Layout
- **Row Structure**: Horizontal layout for cart items
- **Image Sizing**: 60x60px provides good visibility
- **Text Truncation**: "..." for long product titles

## Performance Optimizations

1. **GridView.builder**: Efficient rendering for large product lists
2. **Conditional Rendering**: Only shows relevant buttons
3. **Reactive Updates**: UI updates only when state changes
4. **Asset Loading**: Efficient image loading with proper sizing 