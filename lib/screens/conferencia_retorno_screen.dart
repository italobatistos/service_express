import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConferenciaRetornoScreen extends StatefulWidget {
  const ConferenciaRetornoScreen({super.key});

  @override
  State<ConferenciaRetornoScreen> createState() => _ConferenciaRetornoScreenState();
}

class _ConferenciaRetornoScreenState extends State<ConferenciaRetornoScreen> {
  final Color primaryColor = const Color(0xFF1B2C57);
  final TextEditingController _leitorController = TextEditingController();
  final FocusNode _focoLeitor = FocusNode();
  
  String? _motoristaIdFiltro;
  String _tipoDiligencia = 'positiva'; 
  String? _motivoNegativaSelecionado;
  final List<String> _idsBipadosNestaSessao = [];

  final List<String> _motivosNegativa = [
    'Mudou-se', 'Endereço Insuficiente', 'Falecido', 'Ausente 3x', 'Recusou-se', 'Desconhecido'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderComAcao(),
            const SizedBox(height: 24),
            _buildPainelComando(),
            const SizedBox(height: 32),
            _buildListaEstaticaComContadores(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderComAcao() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Conferência de Retorno', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text('Bipe, confira e finalize o lote. Use os ícones laterais para corrigir erros.', style: TextStyle(color: Colors.grey)),
          ],
        ),
        // Sintaxe correta para adição condicional de Widget em listas
        if (_idsBipadosNestaSessao.isNotEmpty)
          ElevatedButton.icon(
            onPressed: _confirmarBaixaEmLote,
            icon: const Icon(Icons.cloud_upload),
            label: Text("FINALIZAR LOTE (${_idsBipadosNestaSessao.length})"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, 
              foregroundColor: Colors.white, 
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            ),
          ),
      ],
    );
  }

  Widget _buildPainelComando() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Configuração da Baixa:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text("Positiva"), 
                        value: 'positiva', 
                        groupValue: _tipoDiligencia, 
                        onChanged: (v) {
                          setState(() { 
                            _tipoDiligencia = v!; 
                            _motivoNegativaSelecionado = null; 
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text("Negativa"), 
                        value: 'negativa', 
                        groupValue: _tipoDiligencia, 
                        onChanged: (v) {
                          setState(() => _tipoDiligencia = v!);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _motivoNegativaSelecionado,
                  decoration: InputDecoration(
                    labelText: "Motivo (se Negativa)", 
                    filled: true, 
                    fillColor: _tipoDiligencia == 'negativa' ? Colors.white : Colors.grey.shade100, 
                    border: const OutlineInputBorder(),
                  ),
                  items: _motivosNegativa.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: _tipoDiligencia == 'negativa' ? (val) {
                    setState(() => _motivoNegativaSelecionado = val);
                  } : null,
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Entrada de Dados:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _leitorController, 
                  focusNode: _focoLeitor, 
                  autofocus: true, 
                  decoration: const InputDecoration(
                    hintText: "Bipe o Protocolo ou Barra...", 
                    prefixIcon: Icon(Icons.qr_code_scanner), 
                    border: OutlineInputBorder(),
                  ), 
                  onSubmitted: _adicionarAoLote,
                ),
                const SizedBox(height: 20),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('usuarios')
                      .where('perfil', isEqualTo: 'motorista')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator();
                    }
                    return DropdownButtonFormField<String>(
                      value: _motoristaIdFiltro,
                      decoration: const InputDecoration(labelText: "Selecionar Motorista", border: OutlineInputBorder()),
                      items: snapshot.data!.docs.map((d) => DropdownMenuItem(value: d.id, child: Text(d['nome'] ?? ''))).toList(),
                      onChanged: (val) {
                        setState(() { 
                          _motoristaIdFiltro = val; 
                          _idsBipadosNestaSessao.clear(); 
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaEstaticaComContadores() {
    if (_motoristaIdFiltro == null) {
      return const Center(child: Text("Selecione um motorista"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('intimacoes')
          .where('diligente_id', isEqualTo: _motoristaIdFiltro)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LinearProgressIndicator();
        }
        final docs = snapshot.data!.docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final s = data['status'];
          return s == 'Vinculado' || s == 'Concluído';
        }).toList();
        
        return Column(
          children: [
            Row(children: [
              _cardContador("Total Carga", docs.length.toString(), Colors.blue), 
              const SizedBox(width: 16), 
              _cardContador("Bipados Agora", _idsBipadosNestaSessao.length.toString(), Colors.orange), 
              const SizedBox(width: 16), 
              _cardContador("Concluídos", docs.where((d) => d['status'] == 'Concluído').length.toString(), Colors.green),
            ]),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(primaryColor),
                  headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  columns: const [
                    DataColumn(label: Text('PROTOCOLO')), 
                    DataColumn(label: Text('DEVEDOR')), 
                    DataColumn(label: Text('STATUS')), 
                    DataColumn(label: Text('AÇÕES')),
                  ],
                  rows: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    bool foiBaixado = data['status'] == 'Concluído';
                    bool estaNoLote = _idsBipadosNestaSessao.contains(doc.id);
                    
                    return DataRow(
                      color: WidgetStateProperty.resolveWith((states) => foiBaixado ? Colors.green.withOpacity(0.05) : (estaNoLote ? Colors.orange.withOpacity(0.1) : null)),
                      cells: [
                        DataCell(Text(data['protocolo'] ?? '')),
                        DataCell(Text(data['devedor'] ?? '')),
                        DataCell(Icon(
                          foiBaixado ? Icons.check_circle : (estaNoLote ? Icons.playlist_add_check : Icons.directions_run), 
                          color: foiBaixado ? Colors.green : (estaNoLote ? Colors.orange : Colors.grey),
                        )),
                        DataCell(
                          estaNoLote 
                          ? IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.red), onPressed: () => setState(() => _idsBipadosNestaSessao.remove(doc.id)))
                          : (foiBaixado ? TextButton.icon(onPressed: () => _estornarBaixa(doc.id), icon: const Icon(Icons.undo, size: 18), label: const Text("Estornar"), style: TextButton.styleFrom(foregroundColor: Colors.red)) : const SizedBox()),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _adicionarAoLote(String codigo) async {
    String busca = codigo.trim();
    if (busca.isEmpty) {
      return;
    }
    try {
      final snapBarra = await FirebaseFirestore.instance.collection('intimacoes').where('barra', isEqualTo: busca).limit(1).get();
      DocumentSnapshot? doc;
      if (snapBarra.docs.isNotEmpty) {
        doc = snapBarra.docs.first;
      } else {
        final snapProt = await FirebaseFirestore.instance.collection('intimacoes').where('protocolo', isEqualTo: busca).limit(1).get();
        if (snapProt.docs.isNotEmpty) {
          doc = snapProt.docs.first;
        }
      }

      if (doc != null) {
        final data = doc.data() as Map<String, dynamic>;
        final String docId = doc.id; // Promoção de tipo segura após o check de nulidade
        
        if (data['status'] == 'Concluído') {
          _notificar("Este protocolo já foi baixado!", Colors.blue);
        } else if (_idsBipadosNestaSessao.contains(docId)) {
          _notificar("Já está na lista!", Colors.orange);
        } else {
          setState(() => _idsBipadosNestaSessao.add(docId));
        }
      } else {
        _notificar("Não encontrado!", Colors.red);
      }
    } catch (e) { 
      _notificar("Erro: $e", Colors.red); 
    }
    _leitorController.clear();
    _focoLeitor.requestFocus();
  }

  Future<void> _confirmarBaixaEmLote() async {
    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (String id in _idsBipadosNestaSessao) {
      batch.update(FirebaseFirestore.instance.collection('intimacoes').doc(id), {
        'status': 'Concluído', 
        'resultado_final': _tipoDiligencia, 
        'motivo_final': _tipoDiligencia == 'negativa' ? _motivoNegativaSelecionado : null, 
        'data_baixa': FieldValue.serverTimestamp(),
      });
    }
    try { 
      await batch.commit(); 
      _notificar("Lote finalizado!", Colors.green); 
      setState(() => _idsBipadosNestaSessao.clear()); 
    } catch (e) { 
      _notificar("Erro ao processar lote: $e", Colors.red); 
    }
  }

  Future<void> _estornarBaixa(String docId) async {
    bool? confirmar = await showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar Estorno"), 
        content: const Text("Deseja cancelar esta baixa e voltar o protocolo para 'Vinculado'?"), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("NÃO")), 
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("SIM, ESTORNAR", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    
    if (confirmar == true) {
      await FirebaseFirestore.instance.collection('intimacoes').doc(docId).update({
        'status': 'Vinculado',
        'resultado_final': FieldValue.delete(),
        'motivo_final': FieldValue.delete(),
        'data_baixa': FieldValue.delete(),
      });
      _notificar("Baixa estornada com sucesso!", Colors.blue);
    }
  }

  Widget _cardContador(String label, String valor, Color cor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20), 
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(12), 
          border: Border.all(color: cor.withOpacity(0.3)),
        ), 
        child: Column(children: [
          Text(label, style: const TextStyle(color: Colors.grey)), 
          Text(valor, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: cor)),
        ]),
      ),
    );
  }
  
  void _notificar(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: c, duration: const Duration(milliseconds: 800)),
    );
  }
}
