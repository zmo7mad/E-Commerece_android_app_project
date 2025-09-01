import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_commerece/models/product.dart';
import 'package:e_commerece/shared/firebase.dart';

// Provider to manage stock updates
class StockNotifier extends StateNotifier<Map<String, int>> {
  StockNotifier() : super({});

  // Update stock for a specific product
  void updateStock(String productId, int newStockQuantity) {
    state = {...state, productId: newStockQuantity};
    
    // Update in Firebase
    updateProductStockInFirebase(productId, newStockQuantity);
  }

  // Reduce stock when item is purchased
  void reduceStock(String productId, int quantity) {
    final currentStock = state[productId] ?? 0;
    final newStock = (currentStock - quantity).clamp(0, currentStock);
    updateStock(productId, newStock);
  }

  // Get current stock for a product
  int getStock(String productId) {
    return state[productId] ?? 0;
  }

  // Check if product has sufficient stock
  bool hasSufficientStock(String productId, int requestedQuantity) {
    final currentStock = getStock(productId);
    return currentStock >= requestedQuantity;
  }

  // Initialize stock from Firebase data
  void initializeStock(Map<String, int> stockData) {
    state = stockData;
  }

  // Sync stock data from products list
  void syncStockFromProducts(List<Map<String, dynamic>> products) {
    final stockData = <String, int>{};
    for (final product in products) {
      final productId = product['id']?.toString() ?? '';
      final stockQuantity = product['stockQuantity'] != null
          ? int.tryParse(product['stockQuantity'].toString()) ?? 0
          : 0;
      stockData[productId] = stockQuantity;
    }
    state = stockData;
  }

  // Update stock provider with new stock quantities after purchase
  void updateStockAfterPurchase(Map<String, int> productQuantities) {
    try {
      for (final entry in productQuantities.entries) {
        final productId = entry.key;
        final purchasedQuantity = entry.value;
        
        // Use the reduceStock method which handles the calculation and Firebase update
        reduceStock(productId, purchasedQuantity);
      }
    } catch (e) {
      print('Error updating stock provider after purchase: $e');
    }
  }
}

// Stock provider
final stockProvider = StateNotifierProvider<StockNotifier, Map<String, int>>((ref) {
  return StockNotifier();
});

// Provider to get stock for a specific product
final productStockProvider = Provider.family<int, String>((ref, productId) {
  final stock = ref.watch(stockProvider);
  return stock[productId] ?? 0;
});

// Provider to check if product is in stock
final productInStockProvider = Provider.family<bool, String>((ref, productId) {
  final stock = ref.watch(productStockProvider(productId));
  return stock > 0;
});

// Provider to check if product has sufficient stock for a quantity
final productSufficientStockProvider = Provider.family<bool, ({String productId, int quantity})>((ref, params) {
  final stock = ref.watch(productStockProvider(params.productId));
  return stock >= params.quantity;
});



// Helper function to update stock in Firebase
Future<void> updateProductStockInFirebase(String productId, int newStockQuantity) async {
  try {
    await updateProductField(productId, 'stockQuantity', newStockQuantity);
  } catch (e) {
    print('Error updating stock in Firebase: $e');
  }
}
