// lib/models/turma_professor.dart
class TurmaProfessor {
  final String id; // ID do Documento do Firestore
  final String nome;
  final String horario;
  final String local;
  final String professorId; // UID do professor que criou a turma
  final List<String> alunosInscritos; // Lista de UIDs dos alunos
  final String turmaCode; // Código de 6 dígitos para entrar na turma
  final int creditos; // (NOVO) 2 ou 4 créditos

  TurmaProfessor({
    required this.id,
    required this.nome,
    required this.horario,
    required this.local,
    required this.professorId,
    required this.alunosInscritos,
    required this.turmaCode,
    required this.creditos,
  });

  // Getter para contagem de alunos, usado pela UI
  int get alunosCount => alunosInscritos.length;
  int get totalAlunos => alunosInscritos.length;

  /// Construtor de fábrica para criar de um [Map] (lido do Firestore)
  factory TurmaProfessor.fromMap(Map<String, dynamic> data, String documentId) {
    return TurmaProfessor(
      id: documentId, // O ID vem do próprio documento
      nome: data['nome'] ?? '',
      horario: data['horario'] ?? '',
      local: data['local'] ?? '',
      professorId: data['professorId'] ?? '',
      // Converte a lista dinâmica do Firestore para List<String>
      alunosInscritos: List<String>.from(data['alunosInscritos'] ?? []),
      turmaCode: data['turmaCode'] ?? '',
      creditos: data['creditos'] ?? 4, // Padrão 4
    );
  }

  /// Converte este objeto para um [Map] (para salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'horario': horario,
      'local': local,
      'professorId': professorId,
      'alunosInscritos': alunosInscritos,
      'turmaCode': turmaCode,
      'creditos': creditos,
    };
  }
}