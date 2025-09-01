import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_commerece/screens/cart/cart_icon.dart';
import 'package:e_commerece/screens/tabs/profile_tab.dart';
import 'package:e_commerece/screens/tabs/home_tab.dart';
import 'package:e_commerece/screens/tabs/search_tab.dart';
import 'package:e_commerece/screens/tabs/categories_tab.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:animations/animations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  //tracking which tab is selected
  int selectedIndex = 0;
  bool _isInitialized = false;
  
  //list of the tab items in the main screen
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
    // Delay initialization to ensure proper widget setup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
// app state preservation
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App came back to foreground - ensure proper state restoration
        if (mounted) {
          setState(() {
            // Force a rebuild to ensure proper state restoration
          });
        }
        break;
      case AppLifecycleState.inactive:
        // App is inactive
        break;
      case AppLifecycleState.paused:
        // App is paused (backgrounded)
        break;
      case AppLifecycleState.detached:
        // App is detached (terminated)
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        break;
    }
  }

  // on tab tapped
  void _onTabTapped(int index) {
    if (mounted) {
      setState(() {
        selectedIndex = index;
      });
    }
  }

  // subtitle for tab
  String _subtitleForTab(int index) {
    switch (index) {
      case 0:
        return 'Discover amazing products';
      case 1:
        return 'Browse by category';
      case 2:
        return 'Find what you need';
      case 3:
        return 'Your account';
      default:
        return 'Welcome';
    }
  }

  //list of the screens in the main screen - only non-const widgets will rebuild
  final List<Widget> _screens = [
    const HomeTab(),
    const CategoriesTab(),
    const SearchTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while initializing
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
                        color: innerBoxIsScrolled
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ShopEase',
                        style: TextStyle(
                          color: innerBoxIsScrolled
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.primary,
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
                      color: (innerBoxIsScrolled
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.primary)
                          .withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              actions: const [
                CartIcon(),
              ],
              shape: const Border(
                bottom: BorderSide(color: Color(0x1A000000), width: 0.5),
              ),
            ),
          ];
        },
        body: PageTransitionSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (Widget child, Animation<double> primaryAnimation, Animation<double> secondaryAnimation) {
            return FadeThroughTransition(
              animation: primaryAnimation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
          child: KeyedSubtree(
            key: ValueKey<int>(selectedIndex),
            child: _screens[selectedIndex],
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
