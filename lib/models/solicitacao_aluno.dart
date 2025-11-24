import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum para os estados possíveis de uma solicitação
enum StatusSolicitacao { pendente, aprovada, recusada }

/// Representa uma solicitação de adaptação feita por um aluno.
/// Armazenado na coleção 'solicitacoes'.
class SolicitacaoAluno {
  final String id;
  final String alunoId; // UID do aluno que solicitou
  final String professorId; // UID do professor responsável
  final String turmaId; // ID da turma
  
  final String nomeAluno; // Denormalizado para fácil exibição
  final String ra; // Denormalizado para fácil exibição
  final String disciplina; // Denormalizado para fácil exibição
  
  final String tipo; // Ex: "Tempo extra", "Material adaptado"
  final DateTime data; // Data da solicitação
  final String descricao;
  final String? anexo; // Nome do arquivo (simulação de upload)
  final StatusSolicitacao status;
  final String? respostaProfessor; // Motivo da aprovação/recusa

  SolicitacaoAluno({
    required this.id,
    required this.alunoId,
    required this.professorId,
    required this.turmaId,
    required this.nomeAluno,
    required this.ra,
    required this.disciplina,
    required this.tipo,
    required this.data,
    required this.descricao,
    this.anexo,
    required this.status,
    this.respostaProfessor,
  });

  /// Construtor de fábrica para criar a partir de um [Map] (lido do Firestore)
  factory SolicitacaoAluno.fromMap(Map<String, dynamic> data, String documentId) {
    return SolicitacaoAluno(
      id: documentId,
      alunoId: data['alunoId'] ?? '',
      professorId: data['professorId'] ?? '',
      turmaId: data['turmaId'] ?? '',
      nomeAluno: data['nomeAluno'] ?? '',
      ra: data['ra'] ?? '',
      disciplina: data['disciplina'] ?? '',
      tipo: data['tipo'] ?? '',
      data: (data['data'] as Timestamp).toDate(),
      descricao: data['descricao'] ?? '',
      anexo: data['anexo'],
      // Converte a string salva no banco de volta para um Enum
      status: StatusSolicitacao.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => StatusSolicitacao.pendente,
      ),
      respostaProfessor: data['respostaProfessor'],
    );
  }

  /// Converte este objeto para um [Map] (para salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      'alunoId': alunoId,
      'professorId': professorId,
      'turmaId': turmaId,
      'nomeAluno': nomeAluno,
      'ra': ra,
      'disciplina': disciplina,
      'tipo': tipo,
      'data': Timestamp.fromDate(data),
      'descricao': descricao,
      'anexo': anexo,
      'status': status.name, // Salva o Enum como uma string (ex: 'pendente')
      'respostaProfessor': respostaProfessor,
    };
  }

  /// Cria uma cópia do [SolicitacaoAluno] com valores atualizados.
  SolicitacaoAluno copyWith({
    StatusSolicitacao? status,
    String? respostaProfessor,
  }) {
    return SolicitacaoAluno(
      id: id,
      alunoId: alunoId,
      professorId: professorId,
      turmaId: turmaId,
      nomeAluno: nomeAluno,
      ra: ra,
      disciplina: disciplina,
      tipo: tipo,
      data: data,
      descricao: descricao,
      anexo: anexo,
      status: status ?? this.status,
      respostaProfessor: respostaProfessor ?? this.respostaProfessor,
    );
  }
}