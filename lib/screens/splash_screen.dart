import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _iniciarTransicao();
  }

  void _iniciarTransicao() {
    // Tempo de exibição da Splash antes da transição
    Timer(const Duration(seconds: 3), () async {
      // Verifica se o usuário já está autenticado no Firebase
      User? user = FirebaseAuth.instance.currentUser;

      if (!mounted) return;

      if (user != null) {
        // Se já estiver logado, vai direto para a Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // Se não, vai para a tela de Login que acabamos de ajustar
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Mantendo o fundo limpo do seu layout
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Usando a sua logo exata
            Image.asset(
              'assets/images/logo_axis_login.png',
              height: 150,
            ),
            const SizedBox(height: 30),
            // Indicador de carregamento sutil com a cor da Axis
            const CircularProgressIndicator(
              color: Color(0xFF1B2C57),
            ),
          ],
        ),
      ),
    );
  }
}