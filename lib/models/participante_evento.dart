class ParticipanteEvento {
  final String id; // UID do usuário
  final String nome;
  final String ra;
  bool isPresente; // Mutável para o Checkbox

  ParticipanteEvento({
    required this.id,
    required this.nome,
    required this.ra,
    this.isPresente = false,
  });
}