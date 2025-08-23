import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:e_commerece/shared/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Initialize Firebase
Future<void> initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

// Fetch products from Firebase with caching
Future<List<Map<String, dynamic>>> fetchProducts() async {
  try {
    final collection = FirebaseFirestore.instance.collection('Products');
    // Use cache first, then server to improve loading speed
    final querySnapshot = await collection.get(const GetOptions(source: Source.cache))
        .catchError((_) => collection.get()); // Fallback to server if cache fails

    final results = querySnapshot.docs.map((doc) {
      final data = doc.data();
      if (data.containsKey('secureId')) {
        data['id'] = data['secureId']; 
      } else {
        print(' Warning: Product ${doc.id} missing secureId, using Firestore ID');
        data['id'] = doc.id;
      }
      return data;
    }).toList();

    // Prefer remote products; if none exist, return empty (no local fallback)
    return results;
  } catch (e) {
    if (e is FirebaseException) {
      print('Products fetch: Firebase error [${e.code}] ${e.message}');
    } else {
      print('Error fetching products: $e');
    }
    // Return empty on error to avoid mixing dummy data with database
    return [];
  }
}

/// Fetch latest products, ordered by `createdAt` descending when present.
/// Falls back to any order and limits the result if `createdAt` is missing.
Future<List<Map<String, dynamic>>> fetchLatestProducts({int limit = 1}) async {
  try {
    final collection = FirebaseFirestore.instance.collection('Products');
    try {
      // Try cache first for faster loading
      final querySnapshot = await collection
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get(const GetOptions(source: Source.cache))
          .catchError((_) => collection
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get()); // Fallback to server
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        if (data.containsKey('secureId')) {
          data['id'] = data['secureId'];
        } else {
          data['id'] = doc.id;
        }
        return data;
      }).toList();
    } on FirebaseException catch (_) {
      // If field/index missing, fallback to simple get + slice
      final querySnapshot = await collection.get();
      final docs = querySnapshot.docs.take(limit).map((doc) {
        final data = doc.data();
        if (data.containsKey('secureId')) {
          data['id'] = data['secureId'];
        } else {
          data['id'] = doc.id;
        }
        return data;
      }).toList();
      return docs;
    }
  } catch (e) {
    print('Error fetching latest products: $e');
    return [];
  }
}

// Upload products to Firebase
Future<void> uploadProducts(List<Map<String, dynamic>> products) async {
  try {
    final collection = FirebaseFirestore.instance.collection('Products');
    final WriteBatch batch = FirebaseFirestore.instance.batch();
    
    for (final Map<String, dynamic> item in products) {
    
      final cleanProductData = Map<String, dynamic>.from(item);
      
      
      if (cleanProductData.containsKey('id')) {
        cleanProductData['secureId'] = cleanProductData['id'];
       
      }
      
      final docRef = collection.doc();
      batch.set(docRef, cleanProductData);
    }
    
    await batch.commit();
    print(' Products uploaded successfully with secure IDs preserved');
  } catch (e) {
    print(' Error uploading products: $e');
    rethrow;
  }
}


// Local default products removed to save space. Use Firestore only.


Future<Map<String, dynamic>?> fetchProductById(String productId) async {
  try {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('Products')
        .doc(productId)
        .get();
    if (!docSnapshot.exists) return null;
    final data = docSnapshot.data()!;
    data['id'] = docSnapshot.id;
    return data;
  } catch (e) {
    print('Error fetching product: $e');
    return null;
  }
}

// Get user data
Future<Map<String, dynamic>?> getUserData(String userId) async {
  try {
    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .get();
    if (!userDoc.exists) return null;
    return userDoc.data();
  } catch (e) {
    print('Error fetching user: $e');
    return null;
  }
}

// Test connection
Future<void> testDatabaseConnection() async {
  try {
    await FirebaseFirestore.instance.collection('Products').limit(1).get();
    print(' Firebase connected');
  } catch (e) {
    print(' Firebase failed: $e');
  }
}


Future<int> getProductsCount() async {
  try {
    final snap = await FirebaseFirestore.instance.collection('Products').get();
    return snap.docs.length;
  } catch (e) {
    if (e is FirebaseException) {
      print('Products count: Firebase error [${e.code}] ${e.message}');
    } else {
      print('Products count: $e');
    }
    return 0;
  }
}

/// Identifies and returns redundant product documents that were created during checkout.
/// These are documents that only have 'timesBought' field and no other product data.
Future<List<String>> findRedundantProductDocuments() async {
  try {
    final collection = FirebaseFirestore.instance.collection('Products');
    final querySnapshot = await collection.get();
    
    final List<String> redundantDocIds = [];
    
    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      
      // Check if this document only has 'timesBought' field (redundant document)
      if (data.length == 1 && data.containsKey('timesBought')) {
        redundantDocIds.add(doc.id);
        print('Found redundant document: ${doc.id} with timesBought: ${data['timesBought']}');
      }
    }
    
    print('Total redundant documents found: ${redundantDocIds.length}');
    return redundantDocIds;
  } catch (e) {
    print('Error finding redundant documents: $e');
    return [];
  }
}

/// Deletes redundant product documents that were created during checkout.
/// Returns the number of deleted documents.
Future<int> deleteRedundantProductDocuments() async {
  try {
    final redundantDocIds = await findRedundantProductDocuments();
    
    if (redundantDocIds.isEmpty) {
      print('No redundant documents found to delete');
      return 0;
    }
    
    final batch = FirebaseFirestore.instance.batch();
    final collection = FirebaseFirestore.instance.collection('Products');
    
    for (final docId in redundantDocIds) {
      batch.delete(collection.doc(docId));
    }
    
    await batch.commit();
    print('Successfully deleted ${redundantDocIds.length} redundant documents');
    return redundantDocIds.length;
  } catch (e) {
    print('Error deleting redundant documents: $e');
    return 0;
  }
}

/// Deletes all documents in the `Products` collection.
/// Returns the number of deleted documents.
Future<int> clearProductsCollection() async {
  try {
    final collection = FirebaseFirestore.instance.collection('Products');
    final snapshot = await collection.get();
    if (snapshot.docs.isEmpty) return 0;
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    print('Products clear: deleted ${snapshot.docs.length} docs');
    return snapshot.docs.length;
  } catch (e) {
    if (e is FirebaseException) {
      print('Products clear failed [${e.code}] ${e.message}');
    } else {
      print('Products clear failed: $e');
    }
    return 0;
  }
}

// === CART FUNCTIONS ===

/// Save user's cart to Firebase
Future<void> saveUserCart(List<Map<String, dynamic>> cartItems, Map<String, int> quantities) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .set({
      'cart': cartItems,
      'cartQuantities': quantities,
    }, SetOptions(merge: true));
  } catch (e) {
    print('Error saving cart: $e');
  }
}

/// Load user's cart from Firebase
Future<Map<String, dynamic>> loadUserCart() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return {'cart': <Map<String, dynamic>>[], 'cartQuantities': <String, int>{}};

  try {
    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .get();
    
    if (!userDoc.exists) return {'cart': <Map<String, dynamic>>[], 'cartQuantities': <String, int>{}};
    
    final data = userDoc.data()!;
    return {
      'cart': List<Map<String, dynamic>>.from(data['cart'] ?? []),
      'cartQuantities': Map<String, int>.from(data['cartQuantities'] ?? {}),
    };
  } catch (e) {
    print('Error loading cart: $e');
    return {'cart': <Map<String, dynamic>>[], 'cartQuantities': <String, int>{}};
  }
}

// === FAVORITES FUNCTIONS ===

/// Save user's favorites to Firebase
Future<void> saveUserFavorites(List<Map<String, dynamic>> favorites) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .set({
      'favorites': favorites,
    }, SetOptions(merge: true));
  } catch (e) {
    print('Error saving favorites: $e');
  }
}

/// Load user's favorites from Firebase
Future<List<Map<String, dynamic>>> loadUserFavorites() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];

  try {
    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .get();
    
    if (!userDoc.exists) return [];
    
    final data = userDoc.data()!;
    return List<Map<String, dynamic>>.from(data['favorites'] ?? []);
  } catch (e) {
    print('Error loading favorites: $e');
    return [];
  }
}

/// Get real-time stream of products from Firebase
Stream<List<Map<String, dynamic>>> getProductsStream() {
  return FirebaseFirestore.instance
      .collection('Products')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      if (data.containsKey('secureId')) {
        data['id'] = data['secureId'];
      } else {
        data['id'] = doc.id;
      }
      return data;
    }).toList();
  });
}

/// Get real-time stream of latest products from Firebase
Stream<List<Map<String, dynamic>>> getLatestProductsStream({int limit = 3}) {
  return FirebaseFirestore.instance
      .collection('Products')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      if (data.containsKey('secureId')) {
        data['id'] = data['secureId'];
      } else {
        data['id'] = doc.id;
      }
      return data;
    }).toList();
  }).handleError((error) {
    print('Error in latest products stream: $error');
    return <Map<String, dynamic>>[];
  });
}


