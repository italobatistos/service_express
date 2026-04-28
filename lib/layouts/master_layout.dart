import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/import_xml_screen.dart';
import '../screens/admin_users_screen.dart';

class MasterLayout extends StatefulWidget {
  const MasterLayout({super.key});

  @override
  State<MasterLayout> createState() => _MasterLayoutState();
}

class _MasterLayoutState extends State<MasterLayout> {
  final Color primaryColor = const Color(0xFF1B2C57);
  int _indiceAtual = 0;

  // Lista de telas que serão alternadas no corpo do layout
  final List<Widget> _telas = [
    const ImportXmlScreen(),      // Índice 0
    const AdminUsersScreen(),     // Índice 1
    const Center(child: Text("Módulo Dashboard em desenvolvimento")), // 2
    const Center(child: Text("Módulo Relatórios em desenvolvimento")), // 3
    const Center(child: Text("Módulo Pesquisas em desenvolvimento")),  // 4
    const Center(child: Text("Módulo Portal Impressões em desenvolvimento")), // 5
    const Center(child: Text("Módulo Vinculação de Protocolos em desenvolvimento")), // 6
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // O segredo para a Sidebar aparecer é esta Row envolvendo o corpo
      body: Row(
        children: [
          // 1. Sidebar Fixa na Esquerda
          _buildSidebar(),
          
          // 2. Área de Conteúdo Dinâmico
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FA), // Cor de fundo para destacar os cards
              child: IndexedStack(
                index: _indiceAtual,
                children: _telas,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      color: primaryColor,
      child: Column(
        children: [
          const SizedBox(height: 50),
          // Logo/Ícone do Sistema
          Container(
            height: 80, width: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.business_center, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 15),
          const Text(
            "Axis Solutions",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),

          // Menu de Navegação
          Expanded(
            child: ListView(
              children: [
                _sidebarItem(Icons.upload_file, "Importar XML", 0),
                _sidebarItem(Icons.people_alt_outlined, "Gestão de Usuários", 1),
                _sidebarItem(Icons.dashboard_customize_outlined, "Dashboard", 2),
                _sidebarItem(Icons.bar_chart_outlined, "Relatórios", 3),
                _sidebarItem(Icons.search_rounded, "Pesquisas", 4),
                _sidebarItem(Icons.print_outlined, "Portal Impressões", 5),
                _sidebarItem(Icons.link, "Vinculação Protocolos", 6),
              ],
            ),
          ),

          // Botão de Logoff
          _sidebarItem(Icons.logout, "Sair", -1, isLogout: true),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String label, int index, {bool isLogout = false}) {
    bool active = _indiceAtual == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
      decoration: BoxDecoration(
        color: active ? Colors.white.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: isLogout 
          ? () => _confirmarSair()
          : () => setState(() => _indiceAtual = index),
        leading: Icon(
          icon, 
          color: isLogout ? Colors.redAccent : (active ? Colors.blueAccent : Colors.white),
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isLogout ? Colors.redAccent : Colors.white,
            fontSize: 13,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _confirmarSair() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sair do Sistema"),
        content: const Text("Deseja realmente encerrar sua sessão?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            }, 
            child: const Text("Sair", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}