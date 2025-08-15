import 'package:flutter/material.dart';
import 'package:e_commerece/screens/splash/splash_screen.dart';
import 'package:e_commerece/screens/auth/login_screen.dart';
import 'package:e_commerece/screens/auth/register_screen.dart';
import 'package:e_commerece/screens/home/home_screen.dart';

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';

  // Route generation
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
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
}