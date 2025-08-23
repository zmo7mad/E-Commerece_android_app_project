import 'package:flutter/material.dart';
import 'package:e_commerece/screens/splash/splash_screen.dart';
import 'package:e_commerece/screens/auth/login_screen.dart';
import 'package:e_commerece/screens/auth/register_screen.dart';
import 'package:e_commerece/screens/home/home_screen.dart';
import 'package:e_commerece/screens/product/item_screen.dart';
import 'package:e_commerece/screens/product/create_item_screen.dart';
import 'package:e_commerece/models/product.dart';

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String item = '/item';
  static const String createItem = '/create-item';

  // Route generation
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        );
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case home:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        );
      case item:
        final product = settings.arguments as Product;
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ItemScreen(product: product),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
      case createItem:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const CreateItemScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Route not found!'),
            ),
          ),
        );
    }
  }

  // Navigation helpers
  static void navigateToLogin(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(login);
  }  

  static void navigateToHome(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(home);
  }

  static void navigateToRegister(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(register);
  }

  static void navigateToItem(BuildContext context, Product product) {
    Navigator.of(context).pushNamed(item, arguments: product);
  }

  static void navigateToCreateItem(BuildContext context) {
    Navigator.of(context).pushNamed(createItem);
  }
}