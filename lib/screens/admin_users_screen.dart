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

// *********************bloco02 ************
// VARIÁVEIS E INICIALIZAÇÃO DE PERFIL
// *********************bloco02 ************
class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final Color primaryColor = const Color(0xFF1B2C57);
  String perfilUsuarioLogado = "";
  bool _carregando = false; 
  String _filtroBusca = ""; 
  
  int totalUsuarios = 0;
  int totalMotoristas = 0;
  int totalAdminGestao = 0;
  int totalCartorio = 0;

  @override
  void initState() {
    super.initState();
    _buscarPerfilLogado();
    _contarUsuarios(); 
  }

  void _contarUsuarios() {
    FirebaseFirestore.instance.collection('usuarios').snapshots().listen((snapshot) {
      if (mounted) {
        setState(() {
          totalUsuarios = snapshot.docs.length;
          totalMotoristas = snapshot.docs.where((d) => d['perfil'] == 'motorista').length;
          totalCartorio = snapshot.docs.where((d) => d['perfil'] == 'cartorio').length;
          totalAdminGestao = snapshot.docs.where((d) => d['perfil'] == 'admin' || d['perfil'] == 'gestor').length;
        });
      }
    });
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
// CABEÇALHO, CARDS DE RESUMO E BUSCA
// *********************bloco06 ************
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título e Botão no topo
        Row(
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
        ),
        const SizedBox(height: 30),
        // Cards de resumo dinâmicos
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _cardInfo("Total Usuários", totalUsuarios.toString(), Icons.people_outline),
              const SizedBox(width: 20),
              _cardInfo("Motoristas", totalMotoristas.toString(), Icons.delivery_dining_outlined),
              const SizedBox(width: 20),
              _cardInfo("Cartório", totalCartorio.toString(), Icons.assignment_outlined),
              const SizedBox(width: 20),
              _cardInfo("Admin/Gestão", totalAdminGestao.toString(), Icons.admin_panel_settings_outlined),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cardInfo(String titulo, String valor, IconData icone) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: primaryColor.withOpacity(0.1),
            child: Icon(icone, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
              Text(valor, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: TextField(
        onChanged: (val) => setState(() => _filtroBusca = val.toLowerCase()),
        decoration: const InputDecoration(
          hintText: "Pesquisar usuário por nome ou e-mail...", 
          border: InputBorder.none, 
          icon: Icon(Icons.search, color: Colors.grey),
        ),
      ),
    );
  }
// *********************bloco07 ************
// LISTA DE USUÁRIOS E LINHAS (LAYOUT ESTÁVEL)
// *********************bloco07 ************
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text("NOME", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
          Expanded(flex: 3, child: Text("E-MAIL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
          Expanded(flex: 2, child: Text("PERFIL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
          Expanded(flex: 2, child: Text("VEÍCULO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
          Expanded(flex: 2, child: Text("ACESSO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
          Expanded(flex: 2, child: Text("AÇÕES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        var docs = snapshot.data!.docs.where((doc) {
          String nome = (doc['nome'] ?? '').toString().toLowerCase();
          String email = (doc['email'] ?? '').toString().toLowerCase();
          return nome.contains(_filtroBusca) || email.contains(_filtroBusca);
        }).toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            return _buildUserRow(data, docs[index].id);
          },
        );
      },
    );
  }

  Widget _buildUserRow(Map<String, dynamic> data, String docId) {
    bool isInativo = data['status'] == 'inativo';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(data['nome'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isInativo ? Colors.grey : Colors.black, decoration: isInativo ? TextDecoration.lineThrough : null))),
          Expanded(flex: 3, child: Text(data['email'] ?? '', style: TextStyle(fontSize: 13, color: isInativo ? Colors.grey : Colors.black))),
          Expanded(flex: 2, child: Text(data['perfil'] ?? '', style: TextStyle(fontSize: 13, color: isInativo ? Colors.grey : Colors.black))),
          Expanded(flex: 2, child: Text(data['veiculo'] ?? '---', style: TextStyle(fontSize: 13, color: isInativo ? Colors.grey : Colors.black))),
          Expanded(flex: 2, child: Text(perfilUsuarioLogado == 'gestor' ? (data['senha_inicial'] ?? '') : '******', style: const TextStyle(fontSize: 13))),
          Expanded(flex: 2, child: Row(
            children: [
              _actionIcon(Icons.edit_outlined, Colors.blue, () => _validarAcaoGestor(() => _showUserDialog(context, userData: data))),
              const SizedBox(width: 10),
              _actionIcon(Icons.vpn_key_outlined, Colors.orange, () => _validarAcaoGestor(() => _modalSenha(docId, data['nome']))),
              const SizedBox(width: 10),
              _actionIcon(
                isInativo ? Icons.play_circle_outline : Icons.block_flipped, 
                isInativo ? Colors.green : Colors.red, 
                () => _validarAcaoGestor(() => _confirmarAlterarStatus(docId, data['status'] ?? 'ativo'))
              ),
            ],
          )),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return IconButton(icon: Icon(icon, color: color, size: 20), onPressed: onTap, splashRadius: 20);
  }
void _modalSenha(String id, String nome) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.vpn_key_outlined, color: Colors.orange),
            SizedBox(width: 10),
            Text("Resetar Senha"),
          ],
        ),
        content: Text("Deseja resetar a senha de $nome para a senha padrão (max1234)?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              try {
                // Atualiza o campo senha_inicial no Firestore para consulta do usuário
                await FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(id)
                    .update({'senha_inicial': 'max1234'});
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Senha de $nome resetada para max1234!"),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                debugPrint("Erro ao resetar senha: $e");
              }
            },
            child: const Text("Confirmar Reset", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _confirmarAlterarStatus(String id, String statusAtual) {
    String novoStatus = statusAtual == 'ativo' ? 'inativo' : 'ativo';
    String acao = statusAtual == 'ativo' ? 'DESATIVAR' : 'REATIVAR';
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("$acao acesso"),
        content: Text("Deseja realmente mudar o status de $id para $novoStatus?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Não")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: novoStatus == 'ativo' ? Colors.green : Colors.red),
            onPressed: _carregando ? null : () async {
              setState(() => _carregando = true);
              try {
                await FirebaseFirestore.instance.collection('usuarios').doc(id).update({'status': novoStatus});
                if (mounted) Navigator.pop(context);
              } finally {
                if (mounted) setState(() => _carregando = false);
              }
            }, 
            child: _carregando 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text("Sim, $acao", style: const TextStyle(color: Colors.white)),
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
                TextField(controller: veiculoController, decoration: const InputDecoration(labelText: "Veículo / Placa"), textCapitalization: TextCapitalization.characters),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: _carregando ? null : () async {
                if (nomeController.text.isNotEmpty && emailController.text.isNotEmpty) {
                  setState(() => _carregando = true);
                  try {
                    String senhaPadrao = "max1234";
                    await FirebaseFirestore.instance.collection('usuarios').doc(emailController.text.trim()).set({
                      'nome': nomeController.text.trim(),
                      'email': emailController.text.trim(),
                      'perfil': perfilSel,
                      'veiculo': veiculoController.text.trim().toUpperCase(),
                      'senha_inicial': isEdit ? (userData?['senha_inicial'] ?? senhaPadrao) : senhaPadrao,
                      'status': userData?['status'] ?? 'ativo',
                    }, SetOptions(merge: true));

                    if (!isEdit) {
                      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: emailController.text.trim(), password: senhaPadrao);
                    }
                    if (context.mounted) Navigator.pop(context);
                  } finally {
                    if (mounted) setState(() => _carregando = false);
                  }
                }
              },
              child: _carregando 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Salvar", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}