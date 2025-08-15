# Flutter Riverpod E-Commerce App

A Flutter e-commerce application built with Riverpod for state management, featuring a product catalog, shopping cart functionality, and modern UI design.

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── product.dart         # Product data model
├── providers/
│   ├── cart_provider.dart   # Cart state management
│   └── products_providers.dart # Products data management
├── screens/
│   ├── home/
│   │   └── home_screen.dart # Main product catalog
│   └── cart/
│       └── cart_screen.dart # Shopping cart view
└── shared/
    └── cart_icon.dart       # Reusable cart icon widget
```

## 🚀 Features

- **Product Catalog**: Display products in a responsive grid layout
- **Shopping Cart**: Add/remove products with real-time updates
- **Cart Icon**: Badge showing cart item count
- **State Management**: Riverpod for reactive state management
- **Modern UI**: Clean, responsive design with Material Design

## 📚 Documentation

- [Models Documentation](./models.md) - Data structures and models
- [Providers Documentation](./providers.md) - Riverpod state management
- [Screens Documentation](./screens.md) - UI screens and widgets
- [Shared Components](./shared.md) - Reusable widgets
- [Riverpod Guide](./riverpod-guide.md) - Riverpod implementation details

## 🛠️ Setup & Installation

1. Ensure Flutter is installed on your system
2. Clone the repository
3. Run `flutter pub get` to install dependencies
4. Run `dart run build_runner build` to generate Riverpod code
5. Run `flutter run` to start the application

## 📦 Dependencies

- `flutter_riverpod`: State management
- `riverpod_annotation`: Code generation for Riverpod
- `build_runner`: Code generation tool

## 🔧 Code Generation

This project uses Riverpod code generation. After making changes to providers:

```bash
dart run build_runner build
```

## 📱 Screenshots

- **Home Screen**: Product catalog with add/remove functionality
- **Cart Screen**: Shopping cart with total calculation
- **Cart Icon**: Badge showing item count in app bar

---

For detailed documentation on specific components, please refer to the individual documentation files in this README folder. 