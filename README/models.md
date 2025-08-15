# Models Documentation

## Product Model

### Location: `lib/models/product.dart`

The `Product` class represents a product in the e-commerce application.

### Class Definition

```dart
class Product {
  const Product({ 
    required this.id, 
    required this.title, 
    required this.price, 
    required this.image 
  });

  final String id;
  final String title;
  final int price;
  final String image;
}
```

### Properties

| Property | Type | Description | Required |
|----------|------|-------------|----------|
| `id` | `String` | Unique identifier for the product | Yes |
| `title` | `String` | Product name/title | Yes |
| `price` | `int` | Product price in dollars | Yes |
| `image` | `String` | Asset path to product image | Yes |

### Usage Examples

#### Creating a Product Instance

```dart
const product = Product(
  id: '1',
  title: 'backpack',
  price: 43,
  image: 'assets/products/backpack.png'
);
```

#### Using in Lists

```dart
List<Product> products = [
  Product(id: '1', title: 'guitar', price: 56, image: 'assets/products/guitar.png'),
  Product(id: '2', title: 'drum', price: 55, image: 'assets/products/drum.png'),
];
```

### Design Decisions

1. **Immutable Design**: The class uses `final` fields and `const` constructor for immutability
2. **Required Parameters**: All fields are required to ensure data integrity
3. **Simple Structure**: Minimal properties for basic e-commerce functionality
4. **Asset Path**: Images are stored as asset paths for easy loading with `Image.asset()`

### Integration with Riverpod

The Product model is used throughout the application:
- **Providers**: Stored in `cartNotifierProvider` and `productsProvider`
- **UI**: Displayed in `HomeScreen` and `CartScreen`
- **State Management**: Used as the data type for cart operations

### Future Enhancements

Potential additions to the Product model:
- `description`: Product description
- `category`: Product category
- `rating`: Product rating/reviews
- `stock`: Available quantity
- `discount`: Discount percentage 