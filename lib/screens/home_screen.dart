import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Função para deslogar e voltar para a tela de login
  Future<void> _fazerSignOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;
      
      // Remove todas as telas anteriores e volta para o login
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao sair")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color azulPrincipal = const Color(0xFF1B2C57);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Axis Solutions",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: azulPrincipal,
        centerTitle: true,
        actions: [
          // Botão de Logout no AppBar
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _fazerSignOut(context),
            tooltip: "Sair",
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_shipping, size: 80, color: Color(0xFF1B2C57)),
            const SizedBox(height: 20),
            const Text(
              "Painel Logístico",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            
            // Botão de Sair Alternativo no corpo da tela
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _fazerSignOut(context),
                  icon: const Icon(Icons.exit_to_app, color: Colors.red),
                  label: const Text("SAIR DO SISTEMA", style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}