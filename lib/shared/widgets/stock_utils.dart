import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_commerece/providers/stock_provider.dart';

class StockUtils {
  /// Initializes the stock provider with product data
  /// This method is used across multiple screens to sync stock data
  static void initializeStockProvider(
    WidgetRef ref,
    List<Map<String, dynamic>> products,
  ) {
    ref.read(stockProvider.notifier).syncStockFromProducts(products);
  }

  /// Gets stock status text based on stock quantity
  static String getStockStatusText(int stockQuantity) {
    return stockQuantity > 0 ? 'In Stock' : 'Out of Stock';
  }

  /// Gets stock status color based on stock quantity
  static int getStockStatusColor(int stockQuantity) {
    return stockQuantity > 0 ? 0xFF4CAF50 : 0xFFF44336; // Green : Red
  }

  /// Gets stock status icon based on stock quantity
  static String getStockStatusIcon(int stockQuantity) {
    return stockQuantity > 0 ? '✓' : '✗';
  }

  /// Checks if a product is in stock
  static bool isInStock(int stockQuantity) {
    return stockQuantity > 0;
  }

  /// Gets stock warning level
  static String getStockWarningLevel(int stockQuantity) {
    if (stockQuantity <= 0) return 'out_of_stock';
    if (stockQuantity <= 5) return 'low_stock';
    if (stockQuantity <= 10) return 'medium_stock';
    return 'good_stock';
  }
}
