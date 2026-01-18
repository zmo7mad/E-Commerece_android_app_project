import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_commerece/screens/cart/cart_icon.dart';
import 'package:e_commerece/screens/tabs/profile_tab.dart';
import 'package:e_commerece/screens/tabs/home_tab.dart';
import 'package:e_commerece/screens/tabs/search_tab.dart';
import 'package:e_commerece/screens/tabs/categories_tab.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:animations/animations.dart';
import 'package:e_commerece/providers/products_stream_provider.dart';
import 'package:e_commerece/shared/widgets/stock_utils.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  int selectedIndex = 0;
  bool _isInitialized = false;
  bool _stockProviderInitialized = false;
  
  final List<BottomNavigationBarItem> bottomNavigationBarItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Home',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.category),
      label: 'Categories',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.search),
      label: 'Search',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // SIMPLIFIED: Just wait for the widget tree to be ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        // Initialize stock provider once when app starts
        _initializeStockProvider();
      }
    });
  }

  // SIMPLIFIED: Only initialize stock provider, no complex logic
  void _initializeStockProvider() {
    try {
      final productsAsync = ref.read(productsStreamProvider);
      productsAsync.whenData((products) {
        if (products.isNotEmpty && mounted && !_stockProviderInitialized) {
          StockUtils.initializeStockProvider(ref, products);
          _stockProviderInitialized = true;
          debugPrint('✅ Stock provider initialized successfully');
        }
      });
    } catch (e) {
      debugPrint('❌ Error initializing stock provider: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {
        // Force rebuild on app resume
      });
    }
  }

  void _onTabTapped(int index) {
    if (mounted && index != selectedIndex) {
      try {
        setState(() {
          selectedIndex = index;
        });
        debugPrint('🔄 Tab switched to: $index');
      } catch (e) {
        debugPrint('❌ Error switching tabs: $e');
      }
    }
  }

  String _subtitleForTab(int index) {
    switch (index) {
      case 0: return 'Discover amazing products';
      case 1: return 'Browse by category';
      case 2: return 'Find what you need';
      case 3: return 'Your account';
      default: return 'Welcome';
    }
  }

  Widget _buildScreen(int index) {
    try {
      switch (index) {
        case 0: return const HomeTab();
        case 1: return const CategoriesTab();
        case 2: return const SearchTab();
        case 3: return const ProfileTab();
        default: return const HomeTab();
      }
    } catch (e) {
      debugPrint('❌ Error building screen $index: $e');
      return _buildErrorScreen(e.toString());
    }
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedIndex = 0; // Go back to home
                });
              },
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Starting app...'),
            ],
          ),
        ),
      );
    }

    // Keep stock provider in sync (but don't re-initialize)
    final productsAsync = ref.watch(productsStreamProvider);
    productsAsync.whenData((products) {
      if (products.isNotEmpty && mounted && !_stockProviderInitialized) {
        try {
          StockUtils.initializeStockProvider(ref, products);
          _stockProviderInitialized = true;
          debugPrint('🔄 Stock provider synced from build');
        } catch (e) {
          debugPrint('❌ Error syncing stock provider: $e');
        }
      }
    });

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              elevation: 0,
              expandedHeight: 72,
              centerTitle: false,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: const BoxDecoration(),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_basket_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ShopEase',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitleForTab(selectedIndex),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              actions: const [CartIcon()],
              shape: const Border(
                bottom: BorderSide(color: Color(0x1A000000), width: 0.5),
              ),
            ),
          ];
        },
        body: PageTransitionSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> primaryAnimation, Animation<double> secondaryAnimation) {
            return FadeThroughTransition(
              animation: primaryAnimation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
          child: KeyedSubtree(
            key: ValueKey<int>(selectedIndex),
            child: _buildScreen(selectedIndex),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.only(bottom: 10),
        child: SalomonBottomBar(
          currentIndex: selectedIndex,
          onTap: _onTabTapped,
          items: [
            SalomonBottomBarItem(
              icon: const Icon(Icons.home),
              title: const Text('Home'),
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.category),
              title: const Text('Categories'),
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.search),
              title: const Text('Search'),
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.person),
              title: const Text('Profile'),
            ),
          ],
        ),
      ),
    );
  }
}