import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VincularProtocolosScreen extends StatefulWidget {
  const VincularProtocolosScreen({super.key});

  @override
  State<VincularProtocolosScreen> createState() => _VincularProtocolosScreenState();
}

class _VincularProtocolosScreenState extends State<VincularProtocolosScreen> {
  final Color primaryColor = const Color(0xFF1B2C57);
  
  Set<String> _selecionados = {}; 
  
  String? _diligenteIdSelecionado;
  final TextEditingController _leitorController = TextEditingController();
  final FocusNode _focoLeitor = FocusNode();

  final Stream<QuerySnapshot> _usuariosStream = FirebaseFirestore.instance
      .collection('usuarios')
      .where('perfil', isEqualTo: 'motorista')
      .where('status', isEqualTo: 'ativo')
      .snapshots();

  final Stream<QuerySnapshot> _protocolosStream = FirebaseFirestore.instance
      .collection('intimacoes')
      .where('status', isEqualTo: 'Disponível')
      .snapshots();

  @override
  void initState() {
    super.initState();
  }

  void _processarBipagem(String entrada, List<DocumentSnapshot> listaAtual) {
    String busca = entrada.trim(); 
    if (busca.isEmpty) return;

    try {
      final encontrado = listaAtual.firstWhere(
        (doc) {
          var p = doc.data() as Map<String, dynamic>;
          return p['barra'].toString().trim() == busca || 
                 p['protocolo'].toString().trim() == busca;
        }
      );

      setState(() {
        _selecionados.add(encontrado.id);
        _leitorController.clear();
      });
      _focoLeitor.requestFocus(); 
    } catch (e) {
      _notificar("Item '$busca' não encontrado ou já vinculado!", Colors.orange);
      _leitorController.clear();
      _focoLeitor.requestFocus();
    }
  }

  // --- NOVA FUNCIONALIDADE: MODAL DE TRANSFERÊNCIA ---
  void _abrirModalTransferencia() {
    String? novoMotoristaId;
    final TextEditingController _buscaController = TextEditingController();
    bool _encontrou = false;
    Map<String, dynamic>? _dadosDoc;
    String? _docId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text("Transferir Protocolo de Carga"),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _buscaController,
                  decoration: InputDecoration(
                    labelText: "Digite o Protocolo ou Barra",
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () async {
                        // Busca o item independente do status para permitir transferir o que já foi vinculado[cite: 1]
                        final snap = await FirebaseFirestore.instance
                            .collection('intimacoes')
                            .where('protocolo', isEqualTo: _buscaController.text.trim())
                            .limit(1).get();

                        if (snap.docs.isNotEmpty) {
                          setModalState(() {
                            _encontrou = true;
                            _dadosDoc = snap.docs.first.data();
                            _docId = snap.docs.first.id;
                          });
                        } else {
                          _notificar("Protocolo não localizado no banco!", Colors.red);
                        }
                      },
                    ),
                  ),
                ),
                if (_encontrou) ...[
                  const SizedBox(height: 20),
                  Text("Devedor: ${_dadosDoc!['devedor']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text("Motorista Atual: ${_dadosDoc!['diligente_id'] != null ? 'Vinculado' : 'Disponível'}", style: const TextStyle(color: Colors.grey)),
                  const Divider(),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: _usuariosStream, // Reutiliza sua stream de motoristas ativos
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: "Transferir para novo motorista:"),
                        items: snapshot.data!.docs.map((d) => DropdownMenuItem(
                          value: d.id, 
                          child: Text(d['nome'] ?? 'Sem Nome'),
                        )).toList(),
                        onChanged: (val) => novoMotoristaId = val,
                      );
                    },
                  ),
                ]
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR")),
            if (_encontrou)
              ElevatedButton(
                onPressed: () async {
                  if (novoMotoristaId == null) {
                    _notificar("Selecione o novo motorista!", Colors.orange);
                    return;
                  }
                  await FirebaseFirestore.instance.collection('intimacoes').doc(_docId).update({
                    'diligente_id': novoMotoristaId,
                    'status': 'Vinculado',
                    'data_vinculacao': FieldValue.serverTimestamp(),
                  });
                  _notificar("Carga transferida com sucesso!", Colors.green);
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("CONFIRMAR TROCA", style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _protocolosStream,
      builder: (context, snapshotProtocolos) {
        if (snapshotProtocolos.hasError) return const Center(child: Text("Erro ao carregar dados"));
        if (!snapshotProtocolos.hasData) return const Center(child: CircularProgressIndicator());

        final docsProtocolos = snapshotProtocolos.data!.docs;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FB),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Vinculação de Protocolos', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        const Text('Carga de dados e atribuição de motoristas', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    // BOTÕES NO CANTO SUPERIOR DIREITO PADRONIZADOS
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _abrirModalTransferencia,
                          icon: const Icon(Icons.swap_horiz, color: Colors.white),
                          label: const Text("TRANSFERIR CARGA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        if (_selecionados.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selecionados.clear();
                                _leitorController.clear();
                              });
                              _notificar("Carga de bipagem limpa!", Colors.blueGrey);
                            },
                            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                            label: const Text("LIMPAR CARGA", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    _buildSummaryCard("Disponíveis", "${docsProtocolos.length} itens", Icons.list_alt, Colors.blue),
                    const SizedBox(width: 16),
                    _buildSummaryCard("Selecionados", "${_selecionados.length} itens", Icons.qr_code_scanner, Colors.green),
                  ],
                ),
                const SizedBox(height: 24),

                _buildScannerInput(docsProtocolos),
                const SizedBox(height: 32),

                Text("Itens Disponíveis para Vínculo", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                const SizedBox(height: 16),

                _buildDataTable(docsProtocolos),
              ],
            ),
          ),
          bottomNavigationBar: _selecionados.isNotEmpty ? _buildActionPanel() : null,
        );
      }
    );
  }

  // --- MANTIDOS TODOS OS SEUS MÉTODOS ORIGINAIS ---
  Widget _buildScannerInput(List<DocumentSnapshot> lista) {
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
              onSubmitted: (val) => _processarBipagem(val, lista),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<DocumentSnapshot> docs) {
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
          rows: docs.map((doc) {
            var item = doc.data() as Map<String, dynamic>;
            final isSelecionado = _selecionados.contains(doc.id);
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
    return StreamBuilder<QuerySnapshot>(
      stream: _usuariosStream,
      builder: (context, snapshot) {
        List<DropdownMenuItem<String>> items = [];
        if (snapshot.hasData) {
          items = snapshot.data!.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return DropdownMenuItem(
              value: doc.id,
              child: Text(data['nome'] ?? 'Sem Nome'),
            );
          }).toList();
        }

        bool aindaAtivo = items.any((item) => item.value == _diligenteIdSelecionado);
        if (!aindaAtivo) _diligenteIdSelecionado = null;

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
                  items: items,
                  onChanged: (val) => setState(() => _diligenteIdSelecionado = val),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _diligenteIdSelecionado == null ? null : _vincularProtocolos,
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
    );
  }

  Future<void> _vincularProtocolos() async {
    var docMotorista = await FirebaseFirestore.instance.collection('usuarios').doc(_diligenteIdSelecionado).get();
    
    if (!docMotorista.exists || docMotorista.data()?['status'] != 'ativo') {
      _notificar("Este motorista não está mais ativo!", Colors.red);
      setState(() => _diligenteIdSelecionado = null);
      return;
    }

    WriteBatch batch = FirebaseFirestore.instance.batch();
    try {
      for (String id in _selecionados) {
        final ref = FirebaseFirestore.instance.collection('intimacoes').doc(id);
        batch.update(ref, {
          'status': 'Vinculado',
          'diligente_id': _diligenteIdSelecionado,
          'data_vinculacao': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      _notificar("Sucesso! ${_selecionados.length} itens vinculados.", Colors.green);
      _selecionados.clear();
    } catch (e) {
      _notificar("Erro ao vincular: $e", Colors.red);
    }
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