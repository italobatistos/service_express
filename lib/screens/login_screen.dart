import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  // Variáveis de controle lógica (Sem alterar layout)
  bool _lembrarMe = false;
  bool _carregando = false;
  String nomeCliente = "Carregando..."; 

  final Color azulPrincipal = const Color(0xFF1B2C57);
  final Color laranjaDestaque = const Color(0xFFF7941D);

  @override
  void initState() {
    super.initState();
    _carregarConfiguracoes();
  }

  // Carrega o nome da unidade e dados salvos
  void _carregarConfiguracoes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      String empresa = prefs.getString('codigo_empresa') ?? 'max';
      nomeCliente = "${empresa.toUpperCase()} ENTREGADORA";
      
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
    String empresa = 'max';

    try {
      final prefs = await SharedPreferences.getInstance();
      empresa = prefs.getString('codigo_empresa') ?? 'max';
      String emailFinal = "${_userController.text.trim()}@$empresa.com";

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailFinal,
        password: _passController.text.trim(),
      );

      // Salva preferências
      if (_lembrarMe) {
        await prefs.setString('saved_user', _userController.text);
        await prefs.setString('saved_password', _passController.text);
        await prefs.setBool('remember_me', true);
      } else {
        await prefs.remove('saved_user');
        await prefs.remove('saved_password');
        await prefs.setBool('remember_me', false);
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');

    } on FirebaseAuthException catch (e) {
      String msg = "Acesso Negado";
      if (e.code == 'user-not-found') msg = "Usuário não cadastrado na $empresa.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Positioned(
              top: -size.height * 0.1,
              right: -size.width * 0.1,
              child: _circulo(size.width * 0.7, azulPrincipal.withAlpha(13)),
            ),
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.1),
                  Image.asset('assets/images/logo_axis_login.png', height: 120),
                  const SizedBox(height: 10),
                  Text(
                    nomeCliente.toUpperCase(),
                    style: TextStyle(color: laranjaDestaque, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                  SizedBox(height: size.height * 0.05),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 5))],
                    ),
                    child: Column(
                      children: [
                        _campo(controller: _userController, label: "Login", icon: Icons.person_outline),
                        const SizedBox(height: 15),
                        _campo(controller: _passController, label: "Senha", icon: Icons.lock_outline, obscure: true),
                        
                        // Adicionado apenas o Checkbox no espaço existente antes do botão
                        Row(
                          children: [
                            Checkbox(
                              value: _lembrarMe,
                              activeColor: azulPrincipal,
                              onChanged: (val) => setState(() => _lembrarMe = val!),
                            ),
                            const Text("Lembrar de mim", style: TextStyle(color: Colors.black54, fontSize: 12)),
                          ],
                        ),
                        
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _carregando ? null : _realizarLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: azulPrincipal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _carregando 
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("ENTRAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circulo(double s, Color c) => Container(width: s, height: s, decoration: BoxDecoration(color: c, shape: BoxShape.circle));

  Widget _campo({required TextEditingController controller, required String label, required IconData icon, bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: azulPrincipal),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}