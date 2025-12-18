// lib/models/aluno_chamada.dart

class AlunoChamada {
  final String id;
  final String nome;
  final String ra;
  final String? fotoUrl;
  final String? hora;

  AlunoChamada({
    required this.id,
    required this.nome,
    required this.ra,
    this.fotoUrl,
    this.hora,
  });

  // Factory para criar a partir do Map do Firestore
  factory AlunoChamada.fromMap(Map<String, dynamic> map, String idDoc) {
    return AlunoChamada(
      id: idDoc, // Ou map['uid'] dependendo de como você salva
      nome: map['nome'] ?? 'Sem Nome',
      ra: map['ra'] ?? '',
      fotoUrl: map['fotoUrl'],
    );
  }
}