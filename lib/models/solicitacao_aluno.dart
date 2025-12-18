// lib/models/solicitacao_aluno.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum StatusSolicitacao { pendente, aprovada, recusada }

class SolicitacaoAluno {
  final String id;
  final String nomeAluno;
  final String ra;
  final String disciplina;
  final String tipo; 
  final DateTime data;
  final String descricao;
  final String? anexo;
  final StatusSolicitacao status;
  final String alunoId;
  final String professorId;
  final String turmaId;
  final String? resposta; 

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
    this.resposta,
  });

  Map<String, dynamic> toMap() {
    return {
      'nomeAluno': nomeAluno,
      'ra': ra,
      'disciplina': disciplina,
      'tipo': tipo,
      'data': Timestamp.fromDate(data), // Salva como Timestamp no Firestore
      'descricao': descricao,
      'anexo': anexo,
      'status': status.name,
      'alunoId': alunoId,
      'professorId': professorId,
      'turmaId': turmaId,
      'resposta': resposta, // Salva com a chave 'resposta'
    };
  }

  factory SolicitacaoAluno.fromMap(Map<String, dynamic> map, String id) {
    // --- LÓGICA SEGURA DE DATA ---
    DateTime dataObj = DateTime.now();
    if (map['data'] is Timestamp) {
      dataObj = (map['data'] as Timestamp).toDate();
    } else if (map['data'] is String) {
      dataObj = DateTime.tryParse(map['data']) ?? DateTime.now();
    }
    // ----------------------------

    return SolicitacaoAluno(
      id: id,
      nomeAluno: map['nomeAluno'] ?? '',
      ra: map['ra'] ?? '',
      disciplina: map['disciplina'] ?? '',
      tipo: map['tipo'] ?? '',
      data: dataObj,
      descricao: map['descricao'] ?? '',
      anexo: map['anexo'],
      status: StatusSolicitacao.values.firstWhere(
          (e) => e.name == map['status'], orElse: () => StatusSolicitacao.pendente),
      alunoId: map['alunoId'] ?? '',
      professorId: map['professorId'] ?? '',
      turmaId: map['turmaId'] ?? '',
      resposta: map['resposta'] ?? map['respostaProfessor'], // Tenta ler ambos por compatibilidade
    );
  }
}