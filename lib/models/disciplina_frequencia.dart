/// Um modelo de *visualização* (View Model) usado para exibir a
/// frequência calculada de um aluno em uma disciplina.
/// **Este objeto não é salvo no Firebase.**
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

  /// Getter calculado para a porcentagem de frequência.
  double get porcentagem {
    if (totalAulas == 0) return 100.0; // Evita divisão por zero
    return ((totalAulas - faltas) / totalAulas) * 100;
  }

  /// Getter calculado para verificar se o aluno está aprovado (>= 75%).
  bool get estaAprovado => porcentagem >= 75.0;
}