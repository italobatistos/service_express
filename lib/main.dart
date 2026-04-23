import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const ServiceExpressApp());
}

class ServiceExpressApp extends StatelessWidget {
  const ServiceExpressApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Service Express',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}