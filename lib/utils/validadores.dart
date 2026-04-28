
class Validadores {
  
  // Criamos uma função estática que pode ser chamada de qualquer lugar
  static String? validarPlaca(String? valor) {
    if (valor == null || valor.isEmpty) {
      return "A placa é obrigatória para motoristas!";
    }

    String placaLimpa = valor.trim().toUpperCase();
    
    // Regex para formato antigo (AAA0000) e Mercosul (AAA0A00)
    final regExpPlaca = RegExp(r'^[A-Z]{3}[0-9][A-Z0-9][0-9]{2}$');

    if (!regExpPlaca.hasMatch(placaLimpa)) {
      return "Placa inválida! Use o formato AAA0000 ou AAA0A00";
    }

    return null; // Retorna null se estiver tudo OK
  }
}