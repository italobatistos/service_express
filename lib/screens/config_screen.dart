import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _configController = TextEditingController();

  void _salvarEmpresa() async {
    if (_configController.text.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      // Salva 'max' ou 'empresab' para usar no login depois
      await prefs.setString('codigo_empresa', _configController.text.trim().toLowerCase());
      
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.business, size: 80, color: Color(0xFF1B2C57)),
            const SizedBox(height: 20),
            const Text("Configuração Inicial", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text("Digite o código da sua empresa para continuar"),
            const SizedBox(height: 30),
            TextField(
              controller: _configController,
              decoration: InputDecoration(
                labelText: "Código da Empresa",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _salvarEmpresa,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B2C57)),
                child: const Text("CONFIGURAR APP", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}