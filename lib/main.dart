import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:axis_solutions/firebase_options.dart';
import 'package:axis_solutions/screens/login_screen.dart';
import 'package:axis_solutions/screens/splash_screen.dart';
import 'package:axis_solutions/screens/admin_users_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AxisApp());
}

class AxisApp extends StatelessWidget {
  const AxisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Axis Solutions',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B2C57)),
        primaryColor: const Color(0xFF1B2C57),
        useMaterial3: true,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/usuarios': (context) => AdminUsersScreen(),
      },
    );
  }
}