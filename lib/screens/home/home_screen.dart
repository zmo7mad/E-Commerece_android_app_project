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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary,
                      Colors.white,
                    ],
                    stops: const [0, 0.2,1],
                  ),
                ),
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
      ),
    );
    
  }
}
