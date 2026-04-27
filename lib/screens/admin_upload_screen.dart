import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUploadScreen extends StatefulWidget {
  const AdminUploadScreen({super.key});

  @override
  State<AdminUploadScreen> createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends State<AdminUploadScreen> {
  bool _processando = false;
  String _status = "Aguardando seleção de arquivo...";

  Future<void> _importarDados() async {
    try {
      // 1. Chamada corrigida para evitar o erro 'Member not found: platform'
      // Usamos FilePicker.platform ou FilePicker.instance dependendo da versão, 
      // mas o mais seguro no Web é o Singleton direto.
      final result = await FilePicker.pickFiles(
        type: FileType.any,
        withData: true, // Crucial para Web ler os bytes
      );

      if (result != null) {
        setState(() {
          _processando = true;
          _status = "Arquivo detectado. Enviando teste para o Firebase...";
        });

        // 2. Teste de conexão com Firestore
        await FirebaseFirestore.instance.collection('entregas').add({
          'protocolo': 'WEB-AUTO-${DateTime.now().millisecondsSinceEpoch}',
          'unidade': 'MAX ENTREGADORA',
          'cartorio': 'Importação via Portal',
          'status': 'pendente',
          'data_importacao': FieldValue.serverTimestamp(),
        });

        setState(() {
          _status = "Sucesso! O registro de teste foi criado no banco.";
          _processando = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Importação de teste realizada com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status = "Erro na importação: $e";
        _processando = false;
      });
      print("Erro detalhado: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text("Portal Admin - Axis Solutions", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B2C57),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          width: 450,
          padding: const Offset(0, 0) == const Offset(0, 0) ? const EdgeInsets.all(40) : EdgeInsets.zero,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 25,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.upload_file_rounded, size: 80, color: Color(0xFF1B2C57)),
              const SizedBox(height: 25),
              const Text(
                "Alimentação de Banco",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B2C57)),
              ),
              const SizedBox(height: 10),
              Text(
                "Substituição Rota Exata - Service Express",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                ),
              ),
              const SizedBox(height: 35),
              if (_processando)
                const CircularProgressIndicator(color: Color(0xFF1B2C57))
              else
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _importarDados,
                    icon: const Icon(Icons.add_to_photos_rounded, color: Colors.white),
                    label: const Text("SELECIONAR XML", 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B2C57),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}