import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _lembrarMe = false;
  bool _carregando = false;

  final Color azulPrincipal = const Color(0xFF1B2C57);
  final Color laranjaDestaque = const Color(0xFFF7941D);

  @override
  void initState() {
    super.initState();
    _carregarConfiguracoes();
  }

  void _carregarConfiguracoes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userController.text = prefs.getString('saved_user') ?? '';
      _lembrarMe = prefs.getBool('remember_me') ?? false;
      if (_lembrarMe) {
        _passController.text = prefs.getString('saved_password') ?? '';
      }
    });
  }

  Future<void> _realizarLogin() async {
    if (_userController.text.isEmpty || _passController.text.isEmpty) return;
    setState(() => _carregando = true);
    try {
      String emailFinal = "${_userController.text.trim()}@max.com";
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailFinal, password: _passController.text.trim());

      final prefs = await SharedPreferences.getInstance();
      if (_lembrarMe) {
        await prefs.setString('saved_user', _userController.text);
        await prefs.setString('saved_password', _passController.text);
        await prefs.setBool('remember_me', true);
      } else {
        await prefs.setBool('remember_me', false);
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/splash');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro no login")));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Stack(
        children: [
          Positioned(
            top: -size.height * 0.2,
            right: -size.width * 0.1,
            child: Container(
              width: size.width * 0.5,
              height: size.width * 0.5,
              decoration: BoxDecoration(color: azulPrincipal.withOpacity(0.05), shape: BoxShape.circle),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container( // Corrigido aqui: Container em vez de SizedBox
                width: 450,
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Image.asset('assets/images/logo_axis_login.png', height: 120),
                    const SizedBox(height: 15),
                    Text("MAX ENTREGADORA", style: TextStyle(color: laranjaDestaque, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
                      ),
                      child: Column(
                        children: [
                          _campo(controller: _userController, label: "Login", icon: Icons.person_outline),
                          const SizedBox(height: 20),
                          _campo(controller: _passController, label: "Senha", icon: Icons.lock_outline, obscure: true),
                          Row(
                            children: [
                              Checkbox(value: _lembrarMe, activeColor: azulPrincipal, onChanged: (v) => setState(() => _lembrarMe = v!)),
                              const Text("Lembrar de mim", style: TextStyle(fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _carregando ? null : _realizarLogin,
                              style: ElevatedButton.styleFrom(backgroundColor: azulPrincipal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                              child: _carregando ? const CircularProgressIndicator(color: Colors.white) : const Text("ENTRAR", style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campo({required TextEditingController controller, required String label, required IconData icon, bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: azulPrincipal),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}