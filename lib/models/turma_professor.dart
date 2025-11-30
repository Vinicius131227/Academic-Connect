// lib/models/turma_professor.dart

/// Representa uma disciplina/turma criada por um professor.
class TurmaProfessor {
  final String id; // ID do documento no Firestore
  final String nome;
  final String horario; // Texto formatado "Seg 08:00-10:00"
  final String local;
  final String professorId;
  final String turmaCode; // Código único para alunos entrarem
  final int creditos; // 2 ou 4
  final List<String> alunosInscritos; // Lista de UIDs dos alunos
  final String? linkConvite; // Deep link para entrar

  TurmaProfessor({
    required this.id,
    required this.nome,
    required this.horario,
    required this.local,
    required this.professorId,
    required this.turmaCode,
    required this.creditos,
    required this.alunosInscritos,
    this.linkConvite,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'horario': horario,
      'local': local,
      'professorId': professorId,
      'turmaCode': turmaCode,
      'creditos': creditos,
      'alunosInscritos': alunosInscritos,
      'linkConvite': linkConvite,
    };
  }

  factory TurmaProfessor.fromMap(Map<String, dynamic> map, String id) {
    return TurmaProfessor(
      id: id,
      nome: map['nome'] ?? 'Sem Nome',
      horario: map['horario'] ?? '',
      local: map['local'] ?? '',
      professorId: map['professorId'] ?? '',
      turmaCode: map['turmaCode'] ?? '',
      creditos: map['creditos'] ?? 4,
      alunosInscritos: List<String>.from(map['alunosInscritos'] ?? []),
      linkConvite: map['linkConvite'],
    );
  }
}