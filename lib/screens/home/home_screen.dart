import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_commerece/screens/cart/cart_icon.dart';
import 'package:e_commerece/screens/tabs/profile_tab.dart';
import 'package:e_commerece/screens/tabs/home_tab.dart';
import 'package:e_commerece/screens/tabs/search_tab.dart';
import 'package:e_commerece/screens/tabs/categories_tab.dart';
import 'package:e_commerece/routes/app_routes.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:animations/animations.dart';



class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  //tracking which tab is selected
  int selectedIndex = 0;
  
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

  void _onTabTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  //list of the screens in the main screen
  final List<Widget> _screens = [
    HomeTab(),
    CategoriesTab(),
    SearchTab(),
    ProfileTab(),
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          const CartIcon(),
        ],
      ),
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
      bottomNavigationBar: SalomonBottomBar(
        currentIndex: selectedIndex,
        onTap: _onTabTapped,
        items: [
          SalomonBottomBarItem(
            icon: Icon(Icons.home),
            title: Text('Home'),
          ),
          SalomonBottomBarItem(
            icon: Icon(Icons.category),
            title: Text('Categories'),
          ),
          SalomonBottomBarItem(
            icon: Icon(Icons.search),
            title: Text('Search'),
          ),
          SalomonBottomBarItem(
            icon: Icon(Icons.person),
            title: Text('Profile'),
          ),
        ],
      ),
    );
  }
}
