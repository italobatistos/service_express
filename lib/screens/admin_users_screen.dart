// *********************bloco01 ************
// IMPORTS E CLASSE PRINCIPAL
// *********************bloco01 ************
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
// *********************bloco02 ************
// VARIÁVEIS E INICIALIZAÇÃO DE PERFIL
// *********************bloco02 ************
  final Color primaryColor = const Color(0xFF1B2C57);
  String perfilUsuarioLogado = "";

  @override
  void initState() {
    super.initState();
    _buscarPerfilLogado();
  }

  void _buscarPerfilLogado() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.email).get();
      if (mounted && doc.exists) {
        setState(() {
          perfilUsuarioLogado = doc['perfil'] ?? 'admin';
        });
      }
    }
  }

// *********************bloco03 ************
// LÓGICA DE SEGURANÇA E VALIDAÇÃO DE GESTOR
// *********************bloco03 ************
  void _validarAcaoGestor(VoidCallback acao) {
    if (perfilUsuarioLogado != 'gestor') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Apenas GESTORES podem alterar dados."), backgroundColor: Colors.red),
      );
      return;
    }
    acao();
  }

// *********************bloco04 ************
// ESTRUTURA PRINCIPAL (BUILD)
// *********************bloco04 ************
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  _buildSearchBar(),
                  const SizedBox(height: 25),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTableHeader(),
                        _buildUsersList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

// *********************bloco05 ************
// SIDEBAR E ITENS DO MENU LATERAL
// *********************bloco05 ************
  Widget _buildSidebar() {
    return Container(
      width: 280,
      color: primaryColor,
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            height: 100, width: 100,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.business_center, color: Colors.white, size: 50),
          ),
          const SizedBox(height: 20),
          const Text("Axis Solutions", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          _sidebarItem(Icons.dashboard_outlined, "Painel Principal", false),
          _sidebarItem(Icons.people_alt, "Gestão de Usuários", true),
          _sidebarItem(Icons.directions_car, "Frota / Veículos", false),
          const Spacer(),
          _sidebarItem(Icons.logout, "Sair", false, isLogout: true),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String label, bool active, {bool isLogout = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      decoration: BoxDecoration(
        color: active ? Colors.white.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: isLogout ? () => FirebaseAuth.instance.signOut().then((_) => Navigator.pushReplacementNamed(context, '/login')) : null,
        leading: Icon(icon, color: isLogout ? Colors.redAccent : Colors.white, size: 22),
        title: Text(label, style: TextStyle(color: isLogout ? Colors.redAccent : Colors.white, fontSize: 14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        dense: true,
      ),
    );
  }

// *********************bloco06 ************
// CABEÇALHO DA PÁGINA E BARRA DE BUSCA
// *********************bloco06 ************
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Gestão de Usuários", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            Text("Controle de acessos e perfis da equipe", style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.add, color: Colors.white, size: 18),
          label: const Text("Novo Usuário", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            shape: const StadiumBorder(),
          ),
          onPressed: () => _showUserDialog(context),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: const TextField(
        decoration: InputDecoration(hintText: "Pesquisar usuário...", border: InputBorder.none, icon: Icon(Icons.search, color: Colors.grey)),
      ),
    );
  }

// *********************bloco07 ************
// TABELA: HEADER, LISTAGEM E LINHAS
// *********************bloco07 ************
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(15))),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text("NOME", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54))),
          Expanded(flex: 3, child: Text("E-MAIL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54))),
          Expanded(flex: 2, child: Text("PERFIL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54))),
          Expanded(flex: 2, child: Text("VEÍCULO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54))),
          Expanded(flex: 2, child: Text("ACESSO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54))),
          Expanded(flex: 2, child: Text("AÇÕES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54))),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100, indent: 20, endIndent: 20),
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            String docId = docs[index].id;
            return _buildUserRow(data, docId);
          },
        );
      },
    );
  }

  Widget _buildUserRow(Map<String, dynamic> data, String docId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(data['nome'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(flex: 3, child: Text(data['email'] ?? '', style: const TextStyle(fontSize: 13))),
          Expanded(flex: 2, child: Text(data['perfil'] ?? '', style: const TextStyle(fontSize: 13))),
          Expanded(flex: 2, child: Text(data['veiculo'] ?? '---', style: const TextStyle(fontSize: 13))),
          Expanded(flex: 2, child: Text(perfilUsuarioLogado == 'gestor' ? (data['senha_inicial'] ?? '') : '******', style: const TextStyle(fontSize: 13))),
          Expanded(flex: 2, child: Row(
            children: [
              _actionIcon(Icons.edit_outlined, Colors.blue, () => _validarAcaoGestor(() => _showUserDialog(context, userData: data))),
              const SizedBox(width: 10),
              _actionIcon(Icons.vpn_key_outlined, Colors.orange, () => _validarAcaoGestor(() => _modalSenha(docId, data['nome']))),
              const SizedBox(width: 10),
              _actionIcon(Icons.delete_outline, Colors.red, () => _validarAcaoGestor(() => _confirmarDelete(docId))),
            ],
          )),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Padding(padding: const EdgeInsets.all(5), child: Icon(icon, color: color, size: 18)),
    );
  }

void _modalSenha(String id, String nome) {
    final nova = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Nova Senha - $nome"),
        content: TextField(
          controller: nova, 
          decoration: const InputDecoration(labelText: "Digite a nova senha"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('usuarios').doc(id).update({
                'senha_inicial': nova.text.trim(),
              });
              Navigator.pop(context);
            },
            child: const Text("Salvar", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _confirmarDelete(String id) {
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text("Excluir"),
        content: const Text("Deseja remover este acesso?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Não")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('usuarios').doc(id).delete();
              Navigator.pop(context);
            }, 
            child: const Text("Sim")
          ),
        ],
      ),
    );
  }

  void _showUserDialog(BuildContext context, {Map<String, dynamic>? userData}) {
    final nomeController = TextEditingController(text: userData?['nome']);
    final emailController = TextEditingController(text: userData?['email']);
    final veiculoController = TextEditingController(text: userData?['veiculo']);
    String perfilSel = userData?['perfil'] ?? 'motorista';
    bool isEdit = userData != null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(isEdit ? "Editar Usuário" : "Novo Usuário"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nomeController, decoration: const InputDecoration(labelText: "Nome Completo")),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: "E-mail"), enabled: !isEdit),
                DropdownButtonFormField<String>(
                  value: perfilSel,
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text("Administrador")),
                    DropdownMenuItem(value: 'gestor', child: Text("Gestor")),
                    DropdownMenuItem(value: 'cartorio', child: Text("Cartório")),
                    DropdownMenuItem(value: 'motorista', child: Text("Motorista")),
                  ],
                  onChanged: (val) => setState(() => perfilSel = val!),
                  decoration: const InputDecoration(labelText: "Perfil"),
                ),
                TextField(
                  controller: veiculoController, 
                  decoration: const InputDecoration(labelText: "Veículo / Placa"),
                  textCapitalization: TextCapitalization.characters,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () async {
                if (nomeController.text.isNotEmpty && emailController.text.isNotEmpty) {
                  try {
                    String senhaPadrao = "max1234";

                    // 1. Tenta criar no Authentication PRIMEIRO
                    if (!isEdit) {
                      await FirebaseAuth.instance.createUserWithEmailAndPassword(
                        email: emailController.text.trim(),
                        password: senhaPadrao,
                      );
                    }

                    // 2. Se o Auth deu certo (ou é edição), salva no Firestore
                    await FirebaseFirestore.instance.collection('usuarios').doc(emailController.text.trim()).set({
                      'nome': nomeController.text.trim(),
                      'email': emailController.text.trim(),
                      'perfil': perfilSel,
                      'veiculo': veiculoController.text.trim().toUpperCase(),
                      'senha_inicial': isEdit ? (userData?['senha_inicial'] ?? senhaPadrao) : senhaPadrao,
                    }, SetOptions(merge: true));

                    if (context.mounted) Navigator.pop(context);

                  } on FirebaseAuthException catch (e) {
                    // Aqui pegamos o erro do Firebase (como "too-many-requests")
                    String msg = "Erro: ${e.message}";
                    if (e.code == 'too-many-requests') msg = "Bloqueado temporariamente por excesso de tentativas.";
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg), backgroundColor: Colors.red),
                    );
                  } catch (e) {
                    print(e);
                  }
                }
              },
              child: const Text("Salvar", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}