/// Modelo de dados simples, usado originalmente no dashboard do aluno.
/// **Atualmente não está sendo usado e pode ser removido.**
class Disciplina {
  final String nome;
  final double frequencia; // Em porcentagem
  final double media;

  Disciplina({
    required this.nome,
    required this.frequencia,
    required this.media,
  });
}