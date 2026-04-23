import 'package:flutter/material.dart';
import 'splash_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 80.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.motorcycle, size: 100, color: Colors.blueAccent),
              const SizedBox(height: 20),
              const Text(
                "SERVICE EXPRESS",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
              const SizedBox(height: 40),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Usuário (Diligente)',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const SplashScreen()),
                    );
                  },
                  child: const Text("ENTRAR", style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}