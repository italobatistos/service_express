import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:xml/xml.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImportXmlScreen extends StatefulWidget {
  const ImportXmlScreen({super.key});

  @override
  State<ImportXmlScreen> createState() => _ImportXmlScreenState();
}

class _ImportXmlScreenState extends State<ImportXmlScreen> {
  final Color primaryColor = const Color(0xFF1B2C57);
  bool _processando = false;
  List<Map<String, dynamic>> _intimacoesParaSubir = [];

  void _msg(String texto, Color cor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: cor, behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _importarXml() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xml'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final bytes = result.files.first.bytes;
        if (bytes == null) return;

        setState(() => _processando = true);
        
        final rawXml = utf8.decode(bytes);
        final document = XmlDocument.parse(rawXml);
        
        final rootElements = document.findAllElements('intimacoes');
        if (rootElements.isEmpty) throw "Tag <intimacoes> não encontrada.";

        final root = rootElements.first;
        final cartorio = root.getAttribute('cartorio') ?? "";
        final nodes = document.findAllElements('intimacao');

        List<Map<String, dynamic>> temp = [];
        for (var node in nodes) {
          temp.add({
            'protocolo': node.getAttribute('protocolo') ?? "",
            'devedor': node.getAttribute('devedor') ?? "",
            'barra': node.getAttribute('barra') ?? "",
            'endereco': node.getAttribute('endereco') ?? "",
            'cep': node.getAttribute('cep') ?? "",
            'tipodocumento': node.getAttribute('tipodocumento') ?? "",
            'documento': node.getAttribute('documento') ?? "",
            'cartorio_origem': cartorio,
            'status_entrega': 'pendente',
          });
        }
        
        setState(() => _intimacoesParaSubir = temp);
        _msg("${temp.length} registros lidos com sucesso!", primaryColor);
      }
    } catch (e) {
      _msg("Erro: $e", Colors.red);
    } finally {
      setState(() => _processando = false);
    }
  }

  Future<void> _salvarNoBanco() async {
    setState(() => _processando = true);
    int novos = 0;
    try {
      final firestore = FirebaseFirestore.instance;
      // Usando lotes (Batches) para eficiência em arquivos grandes
      var batch = firestore.batch();
      int count = 0;

      for (var data in _intimacoesParaSubir) {
        String id = "${data['protocolo']}_${data['documento']}_${data['cep']}";
        final docRef = firestore.collection('intimacoes').doc(id);
        
        batch.set(docRef, data);
        count++;
        novos++;

        // O Firebase aceita até 500 operações por batch
        if (count == 500) {
          await batch.commit();
          batch = firestore.batch();
          count = 0;
        }
      }
      
      if (count > 0) await batch.commit();
      
      _msg("Sucesso! $novos registros processados.", Colors.green);
      setState(() => _intimacoesParaSubir.clear());
    } catch (e) {
      _msg("Erro ao salvar: $e", Colors.red);
    } finally {
      setState(() => _processando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          if (_processando) const LinearProgressIndicator(),
          Expanded(
            child: _intimacoesParaSubir.isEmpty 
              ? _buildEmptyState() 
              : _buildTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.assignment_turned_in_rounded, size: 32, color: primaryColor),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Carga de Dados Logísticos", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text("${_intimacoesParaSubir.length} registros pendentes no buffer", style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _processando ? null : _importarXml,
            icon: const Icon(Icons.file_upload_outlined),
            label: const Text("SELECIONAR XML"),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18)),
          ),
          if (_intimacoesParaSubir.isNotEmpty) ...[
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _processando ? null : _salvarNoBanco,
              icon: const Icon(Icons.cloud_done),
              label: const Text("SALVAR NO BANCO"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18)),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storage_rounded, size: 60, color: Colors.grey[200]),
          const SizedBox(height: 10),
          const Text("Nenhum dado carregado para processamento", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.grey[100]),
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
            headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
            dataRowHeight: 55,
            columns: const [
              DataColumn(label: Text("Protocolo")),
              DataColumn(label: Text("Devedor")),
              DataColumn(label: Text("Documento")),
              DataColumn(label: Text("CEP")),
              DataColumn(label: Text("Endereço")),
            ],
            rows: _intimacoesParaSubir.map((item) {
              return DataRow(cells: [
                DataCell(Text(item['protocolo'], style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(item['devedor'])),
                DataCell(Text(item['documento'])),
                DataCell(Text(item['cep'])),
                DataCell(SizedBox(width: 300, child: Text(item['endereco'], overflow: TextOverflow.ellipsis))),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}