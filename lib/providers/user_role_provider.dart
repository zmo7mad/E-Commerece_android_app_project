import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Provider to get the current user's role with automatic refresh
final userRoleProvider = FutureProvider<String>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('UserRoleProvider: No authenticated user found');
    return 'user'; // Default to user if not authenticated
  }
  
  print('UserRoleProvider: Fetching role for user: ${user.uid}');
  
  try {
    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .get();
    
    if (doc.exists) {
      final userData = doc.data();
      final userRole = userData?['userRole'] as String? ?? 'user';
      print('UserRoleProvider: Found user role: $userRole');
      print('UserRoleProvider: Full user data: $userData');
      return userRole;
    } else {
      print('UserRoleProvider: User document does not exist');
      return 'user'; // Default to user if document doesn't exist
    }
  } catch (e) {
    print('UserRoleProvider: Error fetching user role: $e');
    return 'user'; // Default to user on error
  }
});

// Provider to check if current user is a seller
final isSellerProvider = Provider<bool>((ref) {
  final userRoleAsync = ref.watch(userRoleProvider);
  return userRoleAsync.when(
    data: (role) {
      final isSeller = role == 'seller';
      print('IsSellerProvider: Role is $role, isSeller: $isSeller');
      return isSeller;
    },
    loading: () {
      print('IsSellerProvider: Loading...');
      return false;
    },
    error: (error, stack) {
      print('IsSellerProvider: Error: $error');
      return false;
    },
  );
});

// Provider to check if current user is a regular user
final isUserProvider = Provider<bool>((ref) {
  final userRoleAsync = ref.watch(userRoleProvider);
  return userRoleAsync.when(
    data: (role) {
      final isUser = role == 'user';
      print('IsUserProvider: Role is $role, isUser: $isUser');
      return isUser;
    },
    loading: () {
      print('IsUserProvider: Loading...');
      return false;
    },
    error: (error, stack) {
      print('IsUserProvider: Error: $error');
      return false;
    },
  );
});

// Provider to manually refresh user role
final userRoleRefreshProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    print('UserRoleProvider: Manually refreshing user role');
    ref.invalidate(userRoleProvider);
  };
});

// Provider to automatically refresh user role when auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Provider that automatically refreshes user role when auth state changes
final autoRefreshUserRoleProvider = FutureProvider<String>((ref) async {
  // Watch auth state changes
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (user) async {
      if (user == null) {
        print('AutoRefreshUserRoleProvider: No authenticated user');
        return 'user';
      }
      
      print('AutoRefreshUserRoleProvider: User authenticated, fetching role for: ${user.uid}');
      
      try {
        final doc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          final userData = doc.data();
          final userRole = userData?['userRole'] as String? ?? 'user';
          print('AutoRefreshUserRoleProvider: Found user role: $userRole');
          return userRole;
        } else {
          print('AutoRefreshUserRoleProvider: User document does not exist');
          return 'user';
        }
      } catch (e) {
        print('AutoRefreshUserRoleProvider: Error fetching user role: $e');
        return 'user';
      }
    },
    loading: () {
      print('AutoRefreshUserRoleProvider: Auth state loading...');
      return 'user';
    },
    error: (error, stack) {
      print('AutoRefreshUserRoleProvider: Auth state error: $error');
      return 'user';
    },
  );
});
