import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/validadores.dart';
import '../utils/conversores.dart';
import '../utils/estilos.dart';

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
  String _filtroPerfilStatus = "Todos";

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

  void _alternarStatusUsuario(String email, String statusAtual) async {
    String novoStatus = (statusAtual.toLowerCase() == 'ativo') ? 'inativo' : 'ativo';
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(email).update(
        {'status': novoStatus},
      );
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
          Expanded(child: _buildUsersGrid()),
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
          _cardInfo("Todos", totalUsuarios.toString(), Icons.people, Colors.blue),
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
    bool selecionado = _filtroPerfilStatus == title;

    return InkWell(
      onTap: () {
        setState(() {
          _filtroPerfilStatus = selecionado ? "Todos" : title;
        });
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: selecionado ? Border.all(color: color, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: selecionado ? color.withOpacity(0.1) : Colors.black.withOpacity(0.02), 
              blurRadius: 10
            )
          ],
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
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: 450,
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

  Widget _buildUsersGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        var docs = snapshot.data!.docs.where((d) {
          var dados = d.data() as Map<String, dynamic>;
          var nome = (dados['nome'] ?? "").toString().toLowerCase();
          var email = (dados['email'] ?? "").toString().toLowerCase();
          var perfil = (dados['perfil'] ?? "").toString();
          var status = (dados['status'] ?? "").toString();

          bool bateBusca = nome.contains(_filtroBusca) || email.contains(_filtroBusca);

          bool bateCategoria = true;
          if (_filtroPerfilStatus == "Motoristas") bateCategoria = perfil == 'motorista';
          if (_filtroPerfilStatus == "Admin/Gestão") bateCategoria = (perfil == 'admin' || perfil == 'gestor');
          if (_filtroPerfilStatus == "Cartório") bateCategoria = perfil == 'cartorio';
          if (_filtroPerfilStatus == "Ativos") bateCategoria = status == 'ativo';
          if (_filtroPerfilStatus == "Inativos") bateCategoria = status == 'inativo';

          return bateBusca && bateCategoria;
        }).toList();

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 450,
            mainAxisExtent: 180,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var user = docs[index].data() as Map<String, dynamic>;
            String veiculo = (user['veiculo'] ?? "").toString();
            String perfil = (user['perfil'] ?? 'motorista').toString();
            String status = (user['status'] ?? 'inativo').toString();
            String nomeUser = (user['nome'] ?? "Sem Nome").toString();

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: primaryColor.withOpacity(0.1),
                        child: Text(nomeUser.isNotEmpty ? nomeUser[0].toUpperCase() : "U",
                            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nomeUser, 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: EstilosApp.corPerfil(perfil).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                EstilosApp.nomePerfil(perfil).toUpperCase(),
                                style: TextStyle(color: EstilosApp.corPerfil(perfil), fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                        onPressed: () => _abrirModalUsuario(userData: user, isEdit: true),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(user['email'] ?? "Sem E-mail", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 8),
                  // AJUSTE DE PADRONIZAÇÃO: Usamos um Stack ou Row com Spacer para garantir que o Status fique sempre à direita
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Se não tem veículo, o SizedBox expandido empurra o badge para a direita
                      if (veiculo.isNotEmpty) 
                        Row(
                          children: [
                            Icon(Icons.directions_car, size: 16, color: primaryColor.withOpacity(0.6)),
                            const SizedBox(width: 5),
                            Text(veiculo, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        )
                      else 
                        const Spacer(), // Empurra o que vem depois para o final da linha
                      
                      if (veiculo.isNotEmpty) const Spacer(), // Também empurra se tiver placa

                      InkWell(
                        onTap: () => _alternarStatusUsuario(user['email'], status),
                        child: _statusBadgeInterno(status),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _statusBadgeInterno(String status) {
    Color cor = Conversores.corStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        Conversores.formatarStatus(status),
        style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.bold),
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
      nomeController.text = (widget.userData!['nome'] ?? '').toString();
      emailController.text = (widget.userData!['email'] ?? '').toString();
      placaController.text = (widget.userData!['veiculo'] ?? '').toString();
      perfilSel = (widget.userData!['perfil'] ?? 'motorista').toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(widget.isEdit ? "Editar Usuário" : "Novo Usuário", style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.grey)),
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
              style: ElevatedButton.styleFrom(backgroundColor: widget.primaryColor, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: _carregando ? null : _processarSalvar,
              child: _carregando 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Salvar", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _processarSalvar() async {
    if (nomeController.text.isEmpty || emailController.text.isEmpty) return;

    String placaLimpa = placaController.text.trim().toUpperCase();
    if (perfilSel == 'motorista') {
      String? erroPlaca = Validadores.validarPlaca(placaLimpa);
      if (erroPlaca != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erroPlaca), backgroundColor: Colors.red));
        return;
      }
    }

    setState(() => _carregando = true);
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(emailController.text.trim()).set({
        'nome': nomeController.text.trim(),
        'email': emailController.text.trim(),
        'perfil': perfilSel,
        'veiculo': perfilSel == 'motorista' ? placaLimpa : "",
        'status': widget.userData?['status'] ?? 'ativo',
      }, SetOptions(merge: true));

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }
}