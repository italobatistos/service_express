import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart'; // Plugin para abrir o Maps
import 'dart:io';

class DeliveryDetailScreen extends StatefulWidget {
  final String protocol;
  const DeliveryDetailScreen({super.key, required this.protocol});

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  bool checkInDone = false;
  bool localDivergente = false;
  String? statusEntrega;
  String? motivoSelecionado;
  File? _fotoAR;
  File? _fotoLocal;

  final List<String> _motivosNegativos = [
    'DESCONHECIDO', 'AUSENTE', 'ENDEREÇO INSUFICIENTE', 'FALECIDO',
    'ENDEREÇO NÃO LOCALIZADO', 'MUDOU-SE', 'SITUAÇÃO DE RISCO', 'RECUSADO'
  ];

  final Map<String, String> _dados = {
    "devedor": "QPC ENGENHARIA LTDA",
    "barra": "20260423558332502",
    "endereco": "AL SALVADOR, 1057, SALA 2213, SALVADOR - BA",
    "cep": "41820790",
    "tipodocumento": "CNPJ",
    "documento": "37292522000114"
  };

  // FUNÇÃO PARA ABRIR O GOOGLE MAPS
  Future<void> _abrirMapa() async {
    final String query = Uri.encodeComponent(_dados["endereco"]!);
    final Uri googleMapsUrl = Uri.parse("google.navigation:q=$query");

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      // Se não tiver Maps instalado, tenta abrir pelo navegador
      final Uri webUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
      await launchUrl(webUrl);
    }
  }

  void _fazerCheckInSimulado() {
    setState(() {
      checkInDone = true;
      localDivergente = true; 
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(backgroundColor: Colors.orange, content: Text("ALERTA: Localização divergente!")),
    );
  }

  Future<void> _capturarFoto(String tipo) async {
    final XFile? photo = await ImagePicker().pickImage(source: ImageSource.camera);
    if (photo != null) setState(() => tipo == 'AR' ? _fotoAR = File(photo.path) : _fotoLocal = File(photo.path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Protocolo ${widget.protocol}"), backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (localDivergente) 
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange)),
                child: Row(children: const [Icon(Icons.warning, color: Colors.orange), SizedBox(width: 10), Text("GPS fora do raio original", style: TextStyle(fontWeight: FontWeight.bold))]),
              ),

            _infoTile("DEVEDOR", _dados["devedor"]!),
            
            // ENDEREÇO COM BOTÃO DE MAPA
            Row(
              children: [
                Expanded(child: _infoTile("ENDEREÇO", _dados["endereco"]!)),
                IconButton(
                  onPressed: _abrirMapa,
                  icon: const Icon(Icons.directions, color: Colors.green, size: 35),
                  tooltip: "Abrir no Maps",
                )
              ],
            ),

            Row(children: [Expanded(child: _infoTile("CEP", _dados["cep"]!)), Expanded(child: _infoTile("BARRA", _dados["barra"]!))]),
            Row(children: [Expanded(child: _infoTile("TIPO", _dados["tipodocumento"]!)), Expanded(child: _infoTile("DOCUMENTO", _dados["documento"]!))]),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: checkInDone ? null : _fazerCheckInSimulado,
                icon: const Icon(Icons.location_on),
                label: Text(checkInDone ? "CHECK-IN REALIZADO" : "FAZER CHECK-IN"),
                style: ElevatedButton.styleFrom(backgroundColor: checkInDone ? Colors.grey : Colors.orange, foregroundColor: Colors.white),
              ),
            ),

            if (checkInDone) ...[
              const Divider(height: 40),
              Row(
                children: [
                  Expanded(child: RadioListTile(title: const Text("Positivo"), value: 'pos', groupValue: statusEntrega, onChanged: (v) => setState(() => statusEntrega = v))),
                  Expanded(child: RadioListTile(title: const Text("Negativo"), value: 'neg', groupValue: statusEntrega, onChanged: (v) => setState(() => statusEntrega = v))),
                ],
              ),
              if (statusEntrega != null) ...[
                if (statusEntrega == 'neg') ...[
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'MOTIVO DA NEGATIVA', border: OutlineInputBorder()),
                    items: _motivosNegativos.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setState(() => motivoSelecionado = v),
                  ),
                  const SizedBox(height: 20),
                ],
                _campoFoto(label: "Foto AR", arquivo: _fotoAR, onTap: () => _capturarFoto('AR')),
                if (statusEntrega == 'neg') ...[
                  const SizedBox(height: 15),
                  _campoFoto(label: "Foto Local/Fachada", arquivo: _fotoLocal, onTap: () => _capturarFoto('Local')),
                ],
              ]
            ],
          ],
        ),
      ),
      bottomNavigationBar: statusEntrega != null 
        ? Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, statusEntrega),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text("FINALIZAR CHECK-OUT"),
            ),
          )
        : null,
    );
  }

  Widget _infoTile(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        Text(valor, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const Divider(color: Colors.black12),
      ]),
    );
  }

  Widget _campoFoto({required String label, required File? arquivo, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120, width: double.infinity,
        decoration: BoxDecoration(border: Border.all(color: Colors.blueAccent), borderRadius: BorderRadius.circular(10),
          image: arquivo != null ? DecorationImage(image: FileImage(arquivo), fit: BoxFit.cover) : null),
        child: arquivo == null ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.camera_alt), Text(label)]) : null,
      ),
    );
  }
}