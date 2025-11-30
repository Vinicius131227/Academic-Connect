// lib/models/solicitacao_aluno.dart
enum StatusSolicitacao { pendente, aprovada, recusada }

class SolicitacaoAluno {
  final String id;
  final String nomeAluno;
  final String ra;
  final String disciplina;
  final String tipo; // "Adaptação", "Revisão"
  final DateTime data;
  final String descricao;
  final String? anexo;
  final StatusSolicitacao status;
  final String alunoId;
  final String professorId;
  final String turmaId;
  final String? respostaProfessor;

  SolicitacaoAluno({
    required this.id,
    required this.nomeAluno,
    required this.ra,
    required this.disciplina,
    required this.tipo,
    required this.data,
    required this.descricao,
    this.anexo,
    required this.status,
    required this.alunoId,
    required this.professorId,
    required this.turmaId,
    this.respostaProfessor,
  });

  Map<String, dynamic> toMap() {
    return {
      'nomeAluno': nomeAluno,
      'ra': ra,
      'disciplina': disciplina,
      'tipo': tipo,
      'data': data.toIso8601String(),
      'descricao': descricao,
      'anexo': anexo,
      'status': status.name,
      'alunoId': alunoId,
      'professorId': professorId,
      'turmaId': turmaId,
      'respostaProfessor': respostaProfessor,
    };
  }

  factory SolicitacaoAluno.fromMap(Map<String, dynamic> map, String id) {
    return SolicitacaoAluno(
      id: id,
      nomeAluno: map['nomeAluno'] ?? '',
      ra: map['ra'] ?? '',
      disciplina: map['disciplina'] ?? '',
      tipo: map['tipo'] ?? '',
      data: DateTime.parse(map['data']),
      descricao: map['descricao'] ?? '',
      anexo: map['anexo'],
      status: StatusSolicitacao.values.firstWhere(
          (e) => e.name == map['status'], orElse: () => StatusSolicitacao.pendente),
      alunoId: map['alunoId'] ?? '',
      professorId: map['professorId'] ?? '',
      turmaId: map['turmaId'] ?? '',
      respostaProfessor: map['respostaProfessor'],
    );
  }
}