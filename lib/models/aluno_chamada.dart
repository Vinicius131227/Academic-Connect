// lib/models/aluno_chamada.dart

/// Modelo simples usado apenas em tempo de execução para listas de presença.
class AlunoChamada {
  final String id;
  final String nome;
  final String ra;
  bool isPresente; // Estado local (checkbox)

  AlunoChamada({
    required this.id,
    required this.nome,
    required this.ra,
    this.isPresente = false,
  });
  
  AlunoChamada copyWith({bool? isPresente}) {
    return AlunoChamada(
      id: id,
      nome: nome,
      ra: ra,
      isPresente: isPresente ?? this.isPresente
    );
  }
}