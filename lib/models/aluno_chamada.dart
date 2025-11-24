/// Um modelo de *visualização* (View Model) usado apenas na tela
/// de chamada manual (lib/telas/professor/tela_chamada_manual.dart).
/// **Este objeto não é salvo no Firebase.**
class AlunoChamada {
  final String id; // UID do aluno
  final String nome;
  final String ra;
  final bool isPresente;

  AlunoChamada({
    required this.id,
    required this.nome,
    required this.ra,
    this.isPresente = false,
  });

  /// Cria uma cópia do objeto, permitindo alterar o status de presença.
  AlunoChamada copyWith({bool? isPresente}) {
    return AlunoChamada(
      id: id,
      nome: nome,
      ra: ra,
      isPresente: isPresente ?? this.isPresente,
    );
  }
}