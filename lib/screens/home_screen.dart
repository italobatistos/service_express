import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necessário para as travas (FilteringTextInputFormatter)
import 'delivery_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Mapa para armazenar o status de cada protocolo (pos, neg ou null)
  final Map<String, String?> _statusProtocolos = {};

  // Lista baseada nos protocolos do seu XML
  final List<String> _todosProtocolos = [
    "5583325",
    "5583320",
    "5583326",
    "5583321",
    "5583322",
    "5583323",
    "5583324"
  ];

  List<String> _protocolosFiltrados = [];

  @override
  void initState() {
    super.initState();
    _protocolosFiltrados = _todosProtocolos;
  }

  // Lógica da barra de pesquisa
  void _filtrarBusca(String query) {
    setState(() {
      _protocolosFiltrados = _todosProtocolos
          .where((p) => p.contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        title: const Text("Axis Solutions"),
        elevation: 0,
      ),
      body: Column(
        children: [
          // CABEÇALHO COM PERFIL DO USUÁRIO
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.blueAccent,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.blueAccent),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Ítalo Batista",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Diligente - Max Entregadora",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // BARRA DE PESQUISA COM TRAVAS
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: TextField(
              onChanged: _filtrarBusca,
              keyboardType: TextInputType.number, // Abre o teclado numérico
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, // TRAVA: Aceita apenas dígitos (0-9)
                LengthLimitingTextInputFormatter(10),   // TRAVA: Limita o tamanho (ex: 10 dígitos)
              ],
              decoration: InputDecoration(
                hintText: "Digitar Protocolo...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // LISTAGEM DE PROTOCOLOS
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: _protocolosFiltrados.length,
              itemBuilder: (context, index) {
                String protocolo = _protocolosFiltrados[index];
                String? status = _statusProtocolos[protocolo];

                IconData iconeStatus = Icons.motorcycle;
                Color corStatus = Colors.blueAccent;

                if (status == 'pos') {
                  iconeStatus = Icons.check_circle;
                  corStatus = Colors.green;
                } else if (status == 'neg') {
                  iconeStatus = Icons.cancel;
                  corStatus = Colors.red;
                }

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: corStatus.withOpacity(0.1),
                      child: Icon(iconeStatus, color: corStatus),
                    ),
                    title: Text(
                      "Protocolo #$protocolo",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text("Salvador - BA"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      final resultado = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DeliveryDetailScreen(protocol: protocolo),
                        ),
                      );

                      if (resultado != null) {
                        setState(() {
                          _statusProtocolos[protocolo] = resultado;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}