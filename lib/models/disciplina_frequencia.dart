// lib/models/disciplina_frequencia.dart

class DisciplinaFrequencia {
  final String nome;
  final int faltas;
  final int totalAulas;
  final String linkMateria;

  DisciplinaFrequencia({
    required this.nome,
    required this.faltas,
    required this.totalAulas,
    required this.linkMateria,
  });

  // Getters inteligentes para a UI
  double get porcentagem {
    if (totalAulas == 0) return 100.0;
    int presencas = totalAulas - faltas;
    return (presencas / totalAulas) * 100;
  }

  bool get estaAprovado {
    return porcentagem >= 75.0;
  }
}