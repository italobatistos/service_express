import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _verificarAuth();
  }

  Future<void> _verificarAuth() async {
    // 2 segundos de exibição da logo
    await Future.delayed(const Duration(seconds: 2));

    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    } else {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.email)
            .get();

        if (mounted) {
          if (userDoc.exists) {
            String perfil = userDoc['perfil'] ?? '';
            // Permissão para os perfis que podem acessar a Web
            if (perfil == 'admin' || perfil == 'gestor') {
              Navigator.pushReplacementNamed(context, '/usuarios');
            } else {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            }
          } else {
            Navigator.pushReplacementNamed(context, '/login');
          }
        }
      } catch (e) {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // MUDANÇA CRUCIAL: Fundo branco puro para não virar "essa azul" de novo
      backgroundColor: Colors.white, 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Axis
            Image.asset(
              'assets/images/logo_axis_login.png', 
              height: 150,
            ),
            const SizedBox(height: 30),
            // Carregamento no azul principal do seu projeto
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B2C57)),
            ),
          ],
        ),
      ),
    );
  }
}