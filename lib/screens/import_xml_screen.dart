import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:xml/xml.dart';
import 'dart:convert';

class ImportXmlScreen extends StatefulWidget {
  const ImportXmlScreen({super.key});

  @override
  State<ImportXmlScreen> createState() => _ImportXmlScreenState();
}

class _ImportXmlScreenState extends State<ImportXmlScreen> {
  final Color primaryColor = const Color(0xFF1B2C57);
  
  List<Map<String, dynamic>> _dadosPreProcessados = [];
  bool _estaCarregando = false;
  String _filtroAtual = 'Todos';

  int get _total => _dadosPreProcessados.length;
  int get _sucesso => _dadosPreProcessados.where((item) => item['temp_status'] == 'Sucesso').length;
  int get _erro => _dadosPreProcessados.where((item) => item['temp_status'] == 'Erro').length;

  void _limparArquivos() {
    setState(() {
      _dadosPreProcessados = [];
      _filtroAtual = 'Todos';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Importação de XML', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const Text('Carga de dados via arquivos de nota fiscal', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),

                Row(
                  children: [
                    _buildSummaryCard("Total Processado", "$_total XMLs", Icons.desktop_windows_outlined, Colors.blue, 
                      onTap: () => setState(() => _filtroAtual = 'Todos')),
                    const SizedBox(width: 16),
                    _buildSummaryCard("Prontos para Importar", "$_sucesso itens", Icons.check_circle_outline, Colors.green, 
                      onTap: () => setState(() => _filtroAtual = 'Sucesso')),
                    const SizedBox(width: 16),
                    _buildSummaryCard("Inconsistências", "$_erro erros", Icons.highlight_off, Colors.red, 
                      onTap: () => setState(() => _filtroAtual = 'Erro')),
                  ],
                ),
                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.cloud_upload_outlined, size: 50, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      const Text("Selecione os arquivos XML para processamento", style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 20),
                      _estaCarregando 
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                            onPressed: _processarLocalmente,
                            icon: const Icon(Icons.search, size: 18),
                            label: const Text("Buscar Arquivos"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Resultados do Processamento ($_filtroAtual)", 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                    if (_sucesso > 0)
                      ElevatedButton(
                        onPressed: () => _confirmarImportacao(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("IMPORTAR PARA O BANCO", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildDataTable(),
              ],
            ),
          ),

          if (_dadosPreProcessados.isNotEmpty)
            Positioned(
              top: 32,
              right: 32,
              child: TextButton.icon(
                onPressed: _limparArquivos,
                icon: const Icon(Icons.delete_sweep, size: 20, color: Colors.redAccent),
                label: const Text("LIMPAR CARGA", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, {required VoidCallback onTap}) {
    bool ativo = (_filtroAtual == 'Todos' && title == "Total Processado") ||
                 (_filtroAtual == 'Sucesso' && title == "Prontos para Importar") ||
                 (_filtroAtual == 'Erro' && title == "Inconsistências");

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: ativo ? Border.all(color: Colors.blue, width: 2) : Border.all(color: Colors.transparent, width: 2),
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
      ),
    );
  }

  Widget _buildDataTable() {
    List<Map<String, dynamic>> dados = _dadosPreProcessados;
    if (_filtroAtual == 'Sucesso') dados = _dadosPreProcessados.where((e) => e['temp_status'] == 'Sucesso').toList();
    if (_filtroAtual == 'Erro') dados = _dadosPreProcessados.where((e) => e['temp_status'] == 'Erro').toList();

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
            DataColumn(label: Text('PROTOCOLO')),
            DataColumn(label: Text('DEVEDOR')),
            DataColumn(label: Text('ENDEREÇO')),
            DataColumn(label: Text('STATUS')),
          ],
          rows: dados.map((item) => DataRow(cells: [
            DataCell(Text(item['protocolo'])),
            DataCell(Text(item['devedor'])),
            DataCell(Text(item['endereco'])),
            DataCell(Text(
              item['temp_status'] == 'Erro' ? "Erro: ${item['motivo']}" : "Sucesso",
              style: TextStyle(
                color: item['temp_status'] == 'Erro' ? Colors.red : Colors.green, 
                fontWeight: FontWeight.bold
              ),
            )),
          ])).toList(),
        ),
      ),
    );
  }

  Future<void> _processarLocalmente() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xml'],
        withData: true,
        allowMultiple: true,
      );

      if (result == null) return;

      setState(() => _estaCarregando = true);
      List<Map<String, dynamic>> listaFinal = [];
      Set<String> chavesUnicasNoArquivo = {}; 
      int contadorDuplicados = 0;

      for (var file in result.files) {
        final content = utf8.decode(file.bytes!);
        final document = XmlDocument.parse(content);
        final items = document.findAllElements('intimacao');

        for (var node in items) {
          String prot = node.getAttribute('protocolo') ?? '';
          String barra = node.getAttribute('barra') ?? '';
          String devedor = node.getAttribute('devedor') ?? '';
          String endereco = node.getAttribute('endereco') ?? '';
          String doc = (node.getAttribute('documento') ?? '').replaceAll(RegExp(r'[^0-9]'), '');
          String tipo = node.getAttribute('tipodocumento') ?? '';

          String chaveIdentidade = "$prot-$barra-$devedor-$endereco-$doc".trim().toLowerCase();

          // LÓGICA DE FILTRAGEM: Se for duplicado, apenas conta e ignora (não adiciona à lista)
          if (chavesUnicasNoArquivo.contains(chaveIdentidade)) {
            contadorDuplicados++;
            continue; // Pula para a próxima intimação
          } 
          
          chavesUnicasNoArquivo.add(chaveIdentidade);

          String motivo = "";
          bool isValido = true;

          // Validações de CPF/CNPJ e Campos
          if (tipo.toUpperCase() == 'CPF' && doc.length != 11) {
            isValido = false;
            motivo = "CPF Inválido";
          } else if (tipo.toUpperCase() == 'CNPJ' && doc.length != 14) {
            isValido = false;
            motivo = "CNPJ Inválido";
          } else if (prot.isEmpty || devedor.isEmpty || endereco.isEmpty) {
            isValido = false;
            motivo = "Dados Incompletos";
          }

          listaFinal.add({
            'protocolo': prot,
            'barra': barra,
            'devedor': devedor,
            'endereco': endereco,
            'cep': node.getAttribute('cep') ?? '',
            'documento': doc,
            'temp_status': isValido ? 'Sucesso' : 'Erro',
            'motivo': motivo,
          });
        }
      }

      setState(() {
        _dadosPreProcessados = listaFinal;
        _estaCarregando = false;
        _filtroAtual = 'Todos';
      });

      // Notifica apenas se houveram duplicados ignorados
      if (contadorDuplicados > 0) {
        _notificar("$contadorDuplicados itens duplicados foram ignorados automaticamente.", Colors.red);
      }

    } catch (e) {
      setState(() => _estaCarregando = false);
      _notificar("Erro ao processar: $e", Colors.red);
    }
  }

  void _confirmarImportacao(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar Importação"),
        content: Text("Deseja subir $_sucesso protocolos válidos para o banco de dados?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () { Navigator.pop(context); _subirAoBanco(); },
            child: const Text("CONFIRMAR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _subirAoBanco() async {
    setState(() => _estaCarregando = true);
    final batch = FirebaseFirestore.instance.batch();
    
    for (var item in _dadosPreProcessados) {
      if (item['temp_status'] == 'Sucesso') {
        final ref = FirebaseFirestore.instance.collection('intimacoes').doc();
        final finalData = Map<String, dynamic>.from(item)..remove('temp_status')..remove('motivo');
        batch.set(ref, {...finalData, 'status': 'Disponível', 'data_importacao': FieldValue.serverTimestamp()});
      }
    }

    await batch.commit();
    setState(() { _dadosPreProcessados = []; _estaCarregando = false; });
    _notificar("Importação concluída!", Colors.green);
  }

  void _notificar(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c));
}