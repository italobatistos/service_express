import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VincularProtocolosScreen extends StatefulWidget {
  const VincularProtocolosScreen({super.key});

  @override
  State<VincularProtocolosScreen> createState() => _VincularProtocolosScreenState();
}

class _VincularProtocolosScreenState extends State<VincularProtocolosScreen> {
  final Color primaryColor = const Color(0xFF1B2C57);
  
  List<Map<String, dynamic>> _protocolosDisponiveis = [];
  Set<String> _selecionados = {}; 
  List<Map<String, dynamic>> _listaDiligentes = [];
  bool _estaCarregando = false;
  
  String? _diligenteIdSelecionado;
  final TextEditingController _leitorController = TextEditingController();
  final FocusNode _focoLeitor = FocusNode();

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    setState(() => _estaCarregando = true);
    await Future.wait([
      _buscarDiligentes(),
      _buscarProtocolosDisponiveis(),
    ]);
    setState(() => _estaCarregando = false);
  }

  // Busca usuários onde o perfil é 'motorista' (conforme seu Firebase)
  Future<void> _buscarDiligentes() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('perfil', isEqualTo: 'motorista')
          .get(); 

      setState(() {
        _listaDiligentes = snapshot.docs.map((doc) => {
          'id': doc.id,
          'nome': doc.data()['nome'] ?? 'Sem Nome',
        }).toList();
      });
    } catch (e) {
      print("Erro ao buscar diligentes: $e");
    }
  }

  Future<void> _buscarProtocolosDisponiveis() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('intimacoes')
          .where('status', isEqualTo: 'Disponível')
          .get();

      setState(() {
        _protocolosDisponiveis = snapshot.docs.map((doc) {
          return {...doc.data(), 'id': doc.id};
        }).toList();
      });
    } catch (e) {
      _notificar("Erro ao carregar protocolos: $e", Colors.red);
    }
  }

  // Bipagem aceita Protocolo ou Código de Barras
  void _processarBipagem(String entrada) {
    String busca = entrada.trim(); 
    if (busca.isEmpty) return;

    try {
      final encontrado = _protocolosDisponiveis.firstWhere(
        (p) => p['barra'].toString().trim() == busca || 
               p['protocolo'].toString().trim() == busca,
      );

      setState(() {
        _selecionados.add(encontrado['id']);
        _leitorController.clear();
      });
      _focoLeitor.requestFocus(); 
    } catch (e) {
      _notificar("Item '$busca' não encontrado ou já vinculado!", Colors.orange);
      _leitorController.clear();
      _focoLeitor.requestFocus();
    }
  }

  // Função de Vínculo (Corrigida a referência)
  Future<void> _vincularProtocolos() async {
    if (_diligenteIdSelecionado == null) {
      _notificar("Por favor, selecione um motorista!", Colors.orange);
      return;
    }

    setState(() => _estaCarregando = true);
    WriteBatch batch = FirebaseFirestore.instance.batch();
    int contador = 0;

    try {
      for (String id in _selecionados) {
        final ref = FirebaseFirestore.instance.collection('intimacoes').doc(id);
        batch.update(ref, {
          'status': 'Vinculado',
          'diligente_id': _diligenteIdSelecionado,
          'data_vinculacao': FieldValue.serverTimestamp(),
        });

        contador++;
        if (contador == 500) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          contador = 0;
        }
      }

      if (contador > 0) await batch.commit();

      _notificar("Sucesso! ${_selecionados.length} itens vinculados.", Colors.green);
      _selecionados.clear();
      await _buscarProtocolosDisponiveis(); 
    } catch (e) {
      _notificar("Erro ao vincular: $e", Colors.red);
    } finally {
      setState(() => _estaCarregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: _estaCarregando 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho padronizado igual ao Importar XML
                const Text('Vinculação de Protocolos', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const Text('Carga de dados e atribuição de motoristas', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),

                Row(
                  children: [
                    _buildSummaryCard("Disponíveis", "${_protocolosDisponiveis.length} itens", Icons.list_alt, Colors.blue),
                    const SizedBox(width: 16),
                    _buildSummaryCard("Selecionados", "${_selecionados.length} itens", Icons.qr_code_scanner, Colors.green),
                  ],
                ),
                const SizedBox(height: 24),

                _buildScannerInput(),
                const SizedBox(height: 32),

                Text("Itens Disponíveis para Vínculo", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                const SizedBox(height: 16),

                _buildDataTable(),
              ],
            ),
          ),
      bottomNavigationBar: _selecionados.isNotEmpty ? _buildActionPanel() : null,
    );
  }

  Widget _buildScannerInput() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.qr_code_2, size: 40, color: Colors.grey.shade400),
          const SizedBox(width: 15),
          Expanded(
            child: TextField(
              controller: _leitorController,
              focusNode: _focoLeitor,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "Bipe o código de barras ou digite o protocolo aqui...",
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
              onSubmitted: _processarBipagem,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200)
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(primaryColor),
          headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          columns: const [
            DataColumn(label: Text('STATUS')),
            DataColumn(label: Text('PROTOCOLO')),
            DataColumn(label: Text('DEVEDOR')),
            DataColumn(label: Text('CÓD. BARRAS')),
          ],
          rows: _protocolosDisponiveis.map((item) {
            final isSelecionado = _selecionados.contains(item['id']);
            return DataRow(
              selected: isSelecionado,
              cells: [
                DataCell(Icon(
                  isSelecionado ? Icons.check_circle : Icons.radio_button_unchecked, 
                  color: isSelecionado ? Colors.green : Colors.grey
                )),
                DataCell(Text(item['protocolo'] ?? '')),
                DataCell(Text(item['devedor'] ?? '')),
                DataCell(Text(item['barra'] ?? '')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActionPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _diligenteIdSelecionado,
              decoration: InputDecoration(
                labelText: "Selecione o Motorista", 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              items: _listaDiligentes.map((d) => DropdownMenuItem(
                value: d['id'] as String, 
                child: Text(d['nome'] as String))
              ).toList(),
              onChanged: (val) => setState(() => _diligenteIdSelecionado = val),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _vincularProtocolos, // Chamada corrigida
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor, 
              foregroundColor: Colors.white, 
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("VINCULAR ITENS", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _notificar(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c));
}