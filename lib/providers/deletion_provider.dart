import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to track deleted images across the entire app
class DeletionNotifier extends StateNotifier<Map<String, List<String>>> {
  DeletionNotifier() : super({});

  // Map of productId -> list of deleted image indices

  // Mark an image as deleted for a specific product
  void markImageAsDeleted(String productId, int imageIndex) {
    final currentState = Map<String, List<String>>.from(state);
    
    if (!currentState.containsKey(productId)) {
      currentState[productId] = [];
    }
    
    if (!currentState[productId]!.contains(imageIndex.toString())) {
      currentState[productId]!.add(imageIndex.toString());
      state = currentState;
    }
  }

  // Restore a deleted image for a specific product
  void restoreDeletedImage(String productId, int imageIndex) {
    final currentState = Map<String, List<String>>.from(state);
    
    if (currentState.containsKey(productId)) {
      currentState[productId]!.remove(imageIndex.toString());
      
      // Remove the product entry if no more deleted images
      if (currentState[productId]!.isEmpty) {
        currentState.remove(productId);
      }
      
      state = currentState;
    }
  }

  // Check if an image is deleted for a specific product
  bool isImageDeleted(String productId, int imageIndex) {
    return state[productId]?.contains(imageIndex.toString()) ?? false;
  }

  // Get all deleted image indices for a specific product
  List<String> getDeletedImageIndices(String productId) {
    return state[productId] ?? [];
  }

  // Clear all deletion state for a specific product (after saving)
  void clearProductDeletions(String productId) {
    final currentState = Map<String, List<String>>.from(state);
    currentState.remove(productId);
    state = currentState;
  }

  // Clear all deletion state (reset)
  void clearAllDeletions() {
    state = {};
  }

  // Get the number of deleted images for a specific product
  int getDeletedImageCount(String productId) {
    return state[productId]?.length ?? 0;
  }

  // Check if a product has any deleted images
  bool hasDeletedImages(String productId) {
    return state.containsKey(productId) && state[productId]!.isNotEmpty;
  }
}

// Provider instance
final deletionProvider = StateNotifierProvider<DeletionNotifier, Map<String, List<String>>>(
  (ref) => DeletionNotifier(),
);
