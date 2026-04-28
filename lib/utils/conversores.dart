import 'package:flutter/material.dart';

class Conversores {
  // Retorna a cor baseada no status
  static Color corStatus(String status) {
    return status.toLowerCase() == 'ativo' ? Colors.green : Colors.red;
  }

  // Retorna o texto formatado (ex: ativo -> Ativo)
  static String formatarStatus(String status) {
    if (status.isEmpty) return "Inativo";
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }
}