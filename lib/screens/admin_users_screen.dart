import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/validadores.dart';
import '../utils/conversores.dart'; // Import da sua nova utils

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final Color primaryColor = const Color(0xFF1B2C57);
  String perfilUsuarioLogado = "";
  bool _carregando = false;
  String _filtroBusca = "";

  int totalUsuarios = 0;
  int totalMotoristas = 0;
  int totalAdminGestao = 0;
  int totalCartorio = 0;
  int totalAtivos = 0;
  int totalInativos = 0;

  @override
  void initState() {
    super.initState();
    _buscarPerfilLogado();
    _contarUsuarios();
  }

  // FUNÇÃO PARA ALTERNAR STATUS (O MOTOR DO CLIQUE)
  void _alternarStatusUsuario(String email, String statusAtual) async {
    String novoStatus = (statusAtual.toLowerCase() == 'ativo') ? 'inativo' : 'ativo';
    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(email)
          .update({'status': novoStatus});
          
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Usuário agora está $novoStatus"),
          backgroundColor: Conversores.corStatus(novoStatus),
          duration: const Duration(milliseconds: 800),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao mudar status: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _contarUsuarios() {
    FirebaseFirestore.instance.collection('usuarios').snapshots().listen((snapshot) {
      if (mounted) {
        setState(() {
          totalUsuarios = snapshot.docs.length;
          totalMotoristas = snapshot.docs.where((d) => d['perfil'] == 'motorista').length;
          totalAdminGestao = snapshot.docs.where((d) => d['perfil'] == 'admin' || d['perfil'] == 'gestor').length;
          totalCartorio = snapshot.docs.where((d) => d['perfil'] == 'cartorio').length;
          totalAtivos = snapshot.docs.where((d) => (d.data() as Map)['status'] == 'ativo').length;
          totalInativos = snapshot.docs.where((d) => (d.data() as Map)['status'] == 'inativo').length;
        });
      }
    });
  }

  void _buscarPerfilLogado() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.email).get();
      if (mounted && doc.exists) {
        setState(() => perfilUsuarioLogado = doc['perfil'] ?? 'admin');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 30),
          _buildStatsRow(),
          const SizedBox(height: 30),
          _buildSearchBar(),
          const SizedBox(height: 20),
          Expanded(child: _buildUsersTable()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Gestão de Usuários", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            Text("Administre os acessos e permissões do sistema", style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _abrirModalUsuario(),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Novo Usuário", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _cardInfo("Total", totalUsuarios.toString(), Icons.people, Colors.blue),
          _cardInfo("Motoristas", totalMotoristas.toString(), Icons.directions_car, Colors.orange),
          _cardInfo("Admin/Gestão", totalAdminGestao.toString(), Icons.admin_panel_settings, Colors.purple),
          _cardInfo("Cartório", totalCartorio.toString(), Icons.edit_document, Colors.teal),
          _cardInfo("Ativos", totalAtivos.toString(), Icons.check_circle, Colors.green),
          _cardInfo("Inativos", totalInativos.toString(), Icons.cancel, Colors.red),
        ],
      ),
    );
  }

  Widget _cardInfo(String title, String value, IconData icon, Color color) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: TextField(
        onChanged: (val) => setState(() => _filtroBusca = val.toLowerCase()),
        decoration: const InputDecoration(
          icon: Icon(Icons.search, color: Colors.grey),
          hintText: "Buscar por nome ou e-mail...",
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildUsersTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          var docs = snapshot.data!.docs.where((d) {
            var nome = (d['nome'] ?? "").toString().toLowerCase();
            var email = (d['email'] ?? "").toString().toLowerCase();
            return nome.contains(_filtroBusca) || email.contains(_filtroBusca);
          }).toList();

          return ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[100]),
              itemBuilder: (context, index) {
                var user = docs[index].data() as Map<String, dynamic>;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Text((user['nome'] ?? "U")[0].toUpperCase(), style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(user['nome'] ?? "Sem Nome", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(user['email'] ?? "Sem E-mail"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ALTERAÇÃO LINHA 127: ADICIONADO INKWELL PARA O CLIQUE
                      InkWell(
                        onTap: () => _alternarStatusUsuario(user['email'], user['status'] ?? 'inativo'),
                        borderRadius: BorderRadius.circular(20),
                        child: _statusBadge(user['status'] ?? 'inativo'),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20), 
                        onPressed: () => _abrirModalUsuario(userData: user, isEdit: true)
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        // USANDO O CONVERSOR DA UTILS
        color: Conversores.corStatus(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        Conversores.formatarStatus(status),
        style: TextStyle(
          color: Conversores.corStatus(status), 
          fontSize: 11, 
          fontWeight: FontWeight.bold
        ),
      ),
    );
  }

  void _abrirModalUsuario({Map<String, dynamic>? userData, bool isEdit = false}) {
    showDialog(
      context: context,
      builder: (context) => _UserFormModal(userData: userData, isEdit: isEdit, primaryColor: primaryColor),
    );
  }
}

class _UserFormModal extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final bool isEdit;
  final Color primaryColor;
  const _UserFormModal({this.userData, this.isEdit = false, required this.primaryColor});

  @override
  State<_UserFormModal> createState() => _UserFormModalState();
}

class _UserFormModalState extends State<_UserFormModal> {
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final placaController = TextEditingController();
  String perfilSel = 'motorista';
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.userData != null) {
      nomeController.text = widget.userData!['nome'] ?? '';
      emailController.text = widget.userData!['email'] ?? '';
      placaController.text = widget.userData!['veiculo'] ?? '';
      perfilSel = widget.userData!['perfil'] ?? 'motorista';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      // ADICIONADO O "X" DE FECHAR
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(widget.isEdit ? "Editar Usuário" : "Novo Usuário", style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.grey),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nomeController, decoration: const InputDecoration(labelText: "Nome Completo", prefixIcon: Icon(Icons.person_outline))),
            const SizedBox(height: 15),
            TextField(controller: emailController, enabled: !widget.isEdit, decoration: const InputDecoration(labelText: "E-mail", prefixIcon: Icon(Icons.email_outlined))),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: perfilSel,
              decoration: const InputDecoration(labelText: "Perfil de Acesso", prefixIcon: Icon(Icons.security)),
              items: const [
                DropdownMenuItem(value: 'admin', child: Text("Administrador")),
                DropdownMenuItem(value: 'gestor', child: Text("Gestão")),
                DropdownMenuItem(value: 'cartorio', child: Text("Cartório")),
                DropdownMenuItem(value: 'motorista', child: Text("Motorista")),
              ],
              onChanged: (val) => setState(() => perfilSel = val!),
            ),
            if (perfilSel == 'motorista') ...[
              const SizedBox(height: 15),
              TextField(controller: placaController, decoration: const InputDecoration(labelText: "Placa do Veículo", prefixIcon: Icon(Icons.directions_car_filled_outlined))),
            ],
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (nomeController.text.isNotEmpty && emailController.text.isNotEmpty) {
                  String placaLimpa = placaController.text.trim().toUpperCase();

                  // TRAVA DE PLACA USANDO UTILS
                  if (perfilSel == 'motorista') {
                    String? erroPlaca = Validadores.validarPlaca(placaLimpa);
                    if (erroPlaca != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(erroPlaca), backgroundColor: Colors.red),
                      );
                      return;
                    }
                  }

                  setState(() => _carregando = true);
                  try {
                    String senhaPadrao = "max1234";
                    
                    await FirebaseFirestore.instance.collection('usuarios').doc(emailController.text.trim()).set({
                      'nome': nomeController.text.trim(),
                      'email': emailController.text.trim(),
                      'perfil': perfilSel,
                      'veiculo': perfilSel == 'motorista' ? placaLimpa : "",
                      'status': widget.userData?['status'] ?? 'ativo',
                    }, SetOptions(merge: true));

                    if (!widget.isEdit) {
                      await FirebaseAuth.instance.createUserWithEmailAndPassword(
                        email: emailController.text.trim(), 
                        password: senhaPadrao
                      );
                    }
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
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