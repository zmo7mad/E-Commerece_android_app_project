import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_commerece/providers/user_role_provider.dart';

class DebugUserRoleScreen extends ConsumerStatefulWidget {
  const DebugUserRoleScreen({super.key});

  @override
  ConsumerState<DebugUserRoleScreen> createState() => _DebugUserRoleScreenState();
}

class _DebugUserRoleScreenState extends ConsumerState<DebugUserRoleScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Debug: Loading data for user: ${user.uid}');
        final doc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          setState(() {
            _userData = doc.data();
            _isLoading = false;
          });
          print('Debug: User data loaded: $_userData');
        } else {
          setState(() {
            _userData = null;
            _isLoading = false;
          });
          print('Debug: User document does not exist');
        }
      } else {
        setState(() {
          _userData = null;
          _isLoading = false;
        });
        print('Debug: No authenticated user');
      }
    } catch (e) {
      print('Debug: Error loading user data: $e');
      setState(() {
        _userData = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRoleAsync = ref.watch(autoRefreshUserRoleProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug User Role'),
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(autoRefreshUserRoleProvider);
              _loadUserData();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current User Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current User',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('UID: ${FirebaseAuth.instance.currentUser?.uid ?? 'Not logged in'}'),
                    Text('Email: ${FirebaseAuth.instance.currentUser?.email ?? 'N/A'}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // User Role Provider Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Role Provider Status',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    userRoleAsync.when(
                      data: (role) => Text('Role: $role'),
                      loading: () => const Text('Loading...'),
                      error: (error, stack) => Text('Error: $error'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Firestore User Data
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Firestore User Data',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const Text('Loading...')
                    else if (_userData == null)
                      const Text('No user data found')
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _userData!.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text('${entry.key}: ${entry.value}'),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actions',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              ref.invalidate(autoRefreshUserRoleProvider);
                            },
                            child: const Text('Refresh Provider'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _loadUserData,
                            child: const Text('Reload Data'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
