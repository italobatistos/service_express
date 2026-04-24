import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:axis_solutions/firebase_options.dart';
import 'package:axis_solutions/screens/login_screen.dart';
import 'package:axis_solutions/screens/config_screen.dart';
import 'package:axis_solutions/screens/home_screen.dart';
import 'package:axis_solutions/screens/splash_screen.dart'; // Import da nova tela

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Removi a lógica de SharedPreferences daqui porque agora 
  // quem vai gerenciar o destino inicial é a Splash_screen.
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
        primaryColor: const Color(0xFF1B2C57),
        useMaterial3: true,
      ),
      // A Splash Screen agora é a porta de entrada obrigatória
      home: const SplashScreen(), 
      
      routes: {
        '/config': (context) => const ConfigScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}