import 'package:cloud_firestore/cloud_firestore.dart';
import 'prova_agendada.dart';

enum StatusDisciplina { aprovado, emCurso, reprovado }

/// Um sub-modelo, representa uma única avaliação dentro de [DisciplinaNotas].
class Avaliacao {
  final String nome; // Ex: "P1"
  final String data; // Data da avaliação (como String para simplicidade)
  final double peso;
  final double? nota; // Nulo se for "Pendente"

  Avaliacao({
    required this.nome,
    required this.data,
    required this.peso,
    this.nota,
  });

  /// Construtor de fábrica para criar a partir de um [Map] (lido do Firestore)
  factory Avaliacao.fromMap(Map<String, dynamic> data) {
    return Avaliacao(
      nome: data['nome'] ?? '',
      data: data['data'] ?? '',
      peso: (data['peso'] ?? 0.0).toDouble(),
      nota: (data['nota'] as num?)?.toDouble(), 
    );
  }

  /// Converte este objeto para um [Map] (para salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'data': data,
      'peso': peso,
      'nota': nota,
    };
  }
}

/// Representa o conjunto de notas de um aluno para uma disciplina.
/// Armazenado na coleção 'notas'.
class DisciplinaNotas {
  final String id; // ID do documento do Firestore
  final String turmaId;
  final String alunoId; // Adicionado para consulta
  final String disciplinaNome; // Denormalizado
  final String professor;
  final double media; // Média calculada
  final StatusDisciplina status;
  final List<Avaliacao> avaliacoes;
  final ProvaAgendada? proximaProva; // Objeto aninhado

  DisciplinaNotas({
    required this.id,
    required this.turmaId,
    required this.alunoId,
    required this.disciplinaNome,
    required this.professor,
    required this.media,
    required this.status,
    required this.avaliacoes,
    this.proximaProva,
  });

  // Alias para 'disciplinaNome'
  String get nome => disciplinaNome;
  // Alias para 'turmaId' (ou pode ser um código de turma)
  String get codigo => turmaId;


  /// Construtor de fábrica para criar a partir de um [Map] (lido do Firestore)
  factory DisciplinaNotas.fromMap(Map<String, dynamic> data, String documentId) {
    // Converte a lista de Maps do Firestore em Lista<Avaliacao>
    var avaliacoesList = data['avaliacoes'] as List<dynamic>? ?? [];
    List<Avaliacao> avaliacoesObj = avaliacoesList
        .map((avaMap) => Avaliacao.fromMap(avaMap as Map<String, dynamic>))
        .toList();

    return DisciplinaNotas(
      id: documentId,
      turmaId: data['turmaId'] ?? '',
      alunoId: data['alunoId'] ?? '',
      disciplinaNome: data['disciplinaNome'] ?? '',
      professor: data['professor'] ?? '',
      media: (data['media'] ?? 0.0).toDouble(),
      // Converte a string do banco para o Enum
      status: StatusDisciplina.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => StatusDisciplina.emCurso,
      ),
      avaliacoes: avaliacoesObj,
      // Se 'proximaProva' existir, converte do Map
      proximaProva: data['proximaProva'] != null
          ? ProvaAgendada.fromMap(data['proximaProva'], '') // ID não é relevante aqui
          : null,
    );
  }

  /// Converte este objeto para um [Map] (para salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      'turmaId': turmaId,
      'alunoId': alunoId,
      'disciplinaNome': disciplinaNome,
      'professor': professor,
      'media': media,
      'status': status.name, // Salva o Enum como string
      'avaliacoes': avaliacoes.map((ava) => ava.toMap()).toList(),
      'proximaProva': proximaProva?.toMap(),
    };
  }
}