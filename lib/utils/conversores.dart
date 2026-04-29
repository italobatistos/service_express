import 'package:flutter/material.dart';

class Conversores {
  static Color corStatus(String status) {
    return status.toLowerCase() == 'ativo' ? Colors.green : Colors.red;
  }

  static String formatarStatus(String status) {
    if (status.isEmpty) return "Inativo";
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  // ADICIONE ESTE MÉTODO AQUI:
  static Widget statusBadge(String status) {
    Color cor = corStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withOpacity(0.5)),
      ),
      child: Text(
        formatarStatus(status),
        style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}