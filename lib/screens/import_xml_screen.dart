import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImportXmlScreen extends StatefulWidget {
  const ImportXmlScreen({super.key});

  @override
  State<ImportXmlScreen> createState() => _ImportXmlScreenState();
}

class _ImportXmlScreenState extends State<ImportXmlScreen> {
  final Color primaryColor = const Color(0xFF1B2C57);
  bool _estaImportando = false;
  double _progressoImportacao = 0.0;
  int _totalXmlsNoBanco = 0;

  @override
  void initState() {
    super.initState();
    _contarXmls();
  }

  void _contarXmls() {
    FirebaseFirestore.instance.collection('importacoes_xml').snapshots().listen((snapshot) {
      if (mounted) {
        setState(() => _totalXmlsNoBanco = snapshot.docs.length);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Retorna um Stack para permitir que o overlay de progresso cubra a tela
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _buildSummaryCard(),
              const SizedBox(height: 30),
              _buildUploadArea(),
              const SizedBox(height: 30),
              const Text(
                "Histórico de Importações", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B2C57))
              ),
              const SizedBox(height: 15),
              Expanded(child: _buildImportHistoryTable()),
            ],
          ),
        ),
        
        // Camada de carregamento (Overlay)
        if (_estaImportando) _buildProgressOverlay(),
      ],
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Importação de XML", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        Text("Carga de dados via arquivos de nota fiscal", style: TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      width: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.inventory_2_outlined, color: Colors.blue),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Total Processado", style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text("$_totalXmlsNoBanco XMLs", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadArea() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.2), width: 2, style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.drive_folder_upload, size: 50, color: primaryColor.withOpacity(0.4)),
          const SizedBox(height: 15),
          const Text("Selecione os arquivos XML para processamento", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.search, size: 18, color: Colors.white),
            label: const Text("Buscar Arquivos", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _simularProcessamento(),
          ),
        ],
      ),
    );
  }

  Widget _buildImportHistoryTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              color: Colors.grey[50],
              child: const Row(
                children: [
                  Expanded(flex: 4, child: Text("ARQUIVO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(flex: 2, child: Text("DATA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(flex: 2, child: Text("STATUS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
              ),
            ),
            _buildHistoryRow("NF_EXEMPLO_001.xml", "28/04/2026", "Sucesso"),
            _buildHistoryRow("NF_EXEMPLO_002.xml", "28/04/2026", "Sucesso"),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryRow(String nome, String data, String status) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(nome, style: const TextStyle(fontSize: 13))),
          Expanded(flex: 2, child: Text(data, style: const TextStyle(fontSize: 13))),
          Expanded(flex: 2, child: Text(status, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildProgressOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: Container(
          width: 220, height: 220,
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(25),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 130, height: 130,
                    child: CircularProgressIndicator(
                      value: _progressoImportacao,
                      strokeWidth: 10,
                      color: primaryColor,
                      backgroundColor: Colors.grey[200]
                    )
                  ),
                  Text(
                    "${(_progressoImportacao * 100).toInt()}%",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor)
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text("Processando...", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  void _simularProcessamento() async {
    setState(() { 
      _estaImportando = true;
      _progressoImportacao = 0.0;
    });

    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (mounted) setState(() => _progressoImportacao = i / 100);
    }

    setState(() => _estaImportando = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Carga efetuada com sucesso!"), backgroundColor: Colors.green)
      );
    }
  }
}