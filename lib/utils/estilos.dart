import 'package:flutter/material.dart';

class EstilosApp {
  // Retorna a cor baseada no perfil
  static Color corPerfil(String perfil) {
    switch (perfil.toLowerCase()) {
      case 'admin': return Colors.purple;
      case 'gestor': return Colors.orange;
      case 'cartorio': return Colors.teal;
      case 'motorista': return Colors.blueGrey;
      default: return Colors.grey;
    }
  }

  // Retorna o nome amigável do perfil
  static String nomePerfil(String perfil) {
    if (perfil.isEmpty) return "Não Definido";
    return perfil[0].toUpperCase() + perfil.substring(1).toLowerCase();
  }
}