class Diligente {
  String nome;
  String placaDoVeiculo;
  String status;

  Diligente({required this.nome, required this.placaDoVeiculo, required this.status});

  String resumo() {
    return 'Nome: $nome\nPlaca do Veículo: $placaDoVeiculo\nStatus: $status';
  }
}

void main() {
  List<Diligente> diligentes = [
    Diligente(nome: 'Maria', placaDoVeiculo: 'ABC123', status: 'em rota'),
    Diligente(nome: 'João', placaDoVeiculo: 'XYZ789', status: 'disponível'),
    Diligente(nome: 'Ana', placaDoVeiculo: 'DEF456', status: 'disponível')
  ];

  for (var dil in diligentes) {
    if (dil.status == 'disponível') {
      print(dil.resumo());
    }
  }
}