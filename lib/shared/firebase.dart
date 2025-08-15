import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:e_commerece/shared/firebase_options.dart';
import 'package:e_commerece/models/dummy_products.dart';
import 'package:e_commerece/models/product.dart';

// Initialize Firebase
Future<void> initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

// Fetch products from Firebase
Future<List<Map<String, dynamic>>> fetchProducts() async {
  try {
    final collection = FirebaseFirestore.instance.collection('Products');
    final querySnapshot = await collection.get();

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

    // If no remote products, return bundled defaults without writing to DB
    if (results.isEmpty) {
      return _defaultProducts;
    }

    return results;
  } catch (e) {
    if (e is FirebaseException) {
      print('Products fetch: Firebase error [${e.code}] ${e.message}');
    } else {
      print('Error fetching products: $e');
    }
    // Return local products as fallback
    return _defaultProducts;
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


final List<Map<String, dynamic>> _defaultProducts =
    kDummyProducts.map((Product p) => p.toMap()).toList();


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


