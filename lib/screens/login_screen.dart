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
    String emailDigitado = _userController.text.trim();

    // INTELIGÊNCIA: Se o utilizador não digitou @, completa automaticamente
    if (emailDigitado.isNotEmpty && !emailDigitado.contains('@')) {
      emailDigitado = "$emailDigitado@max.com";
      print("Ajustando e-mail para: $emailDigitado");
    }

    if (emailDigitado.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos")),
      );
      return;
    }

    setState(() => _carregando = true);
    print("--- TENTATIVA DE LOGIN INICIADA ---");

    try {
      // 1. Autenticação no Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailDigitado,
        password: _passController.text.trim(),
      );
      
      print("1. Firebase Auth: Sucesso!");

      // 2. Verificação de Status no Firestore
      var userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(emailDigitado)
          .get();

      if (userDoc.exists) {
        print("2. Documento no Firestore: Encontrado!");
        Map<String, dynamic> dados = userDoc.data() as Map<String, dynamic>;
        String status = dados['status']?.toString().toLowerCase() ?? 'ativo';
        print("3. Status do utilizador: $status");

        // 3. TRAVA DE SEGURANÇA: Se estiver inativo, desloga na hora
        if (status == 'inativo') {
          print("X. BLOQUEIO: Utilizador inativo.");
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Acesso bloqueado. Contacte o administrador."),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _carregando = false);
          return; 
        }
      } else {
        print("Aviso: Documento não encontrado para o e-mail: $emailDigitado");
      }

      // 4. Salvar preferências de "Lembrar-me"
      final prefs = await SharedPreferences.getInstance();
      if (_lembrarMe) {
        await prefs.setString('saved_user', _userController.text.trim());
        await prefs.setString('saved_password', _passController.text.trim());
        await prefs.setBool('remember_me', true);
      } else {
        await prefs.remove('saved_user');
        await prefs.remove('saved_password');
        await prefs.setBool('remember_me', false);
      }

      print("V. LOGIN COMPLETO: Navegando para Home.");
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }

    } on FirebaseAuthException catch (e) {
      print("Erro Firebase Auth: ${e.code}");
      String mensagem = "Erro ao realizar login";
      if (e.code == 'user-not-found') mensagem = "Utilizador não encontrado";
      if (e.code == 'wrong-password') mensagem = "Senha incorreta";
      if (e.code == 'invalid-email') mensagem = "Formato de e-mail inválido";
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print("Erro Geral: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro inesperado: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Lado Esquerdo - Visual
          Expanded(
            flex: 1,
            child: Container(
              color: azulPrincipal,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, size: 100, color: Colors.white),
                    const SizedBox(height: 20),
                    const Text(
                      "AXIS SOLUTIONS", 
                      style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2)
                    ),
                    const Text("Logística Integrada", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
          // Lado Direito - Formulário
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Bem-vindo", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text("Acesse sua conta para continuar", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 40),
                    _campo(controller: _userController, label: "Utilizador ou E-mail", icon: Icons.person_outline),
                    const SizedBox(height: 20),
                    _campo(controller: _passController, label: "Senha", icon: Icons.lock_outline, obscure: true),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _lembrarMe,
                              onChanged: (v) => setState(() => _lembrarMe = v!),
                              activeColor: azulPrincipal,
                            ),
                            const Text("Lembrar-me"),
                          ],
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text("Esqueceu a senha?", style: TextStyle(color: laranjaDestaque)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _carregando ? null : _realizarLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: azulPrincipal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: _carregando 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text("ENTRAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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