// lib/models/disciplina_notas.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'prova_agendada.dart'; // Importante

enum StatusDisciplina { aprovado, reprovado, emCurso }

class AvaliacaoNota {
  final String nome;
  final double? nota;
  final double peso; // Adicionado
  final String data; // Adicionado (string formatada)

  AvaliacaoNota({
    required this.nome, 
    this.nota, 
    this.peso = 1.0, 
    this.data = ''
  });
}

class DisciplinaNotas {
  final String id;
  final String turmaId;
  final String nome;
  final String codigo;
  final String professor;
  final double media;
  final StatusDisciplina status;
  final List<AvaliacaoNota> avaliacoes;
  final ProvaAgendada? proximaProva;

  DisciplinaNotas({
    required this.id,
    required this.turmaId,
    required this.nome,
    this.codigo = '',
    this.professor = '',
    this.media = 0.0,
    this.status = StatusDisciplina.emCurso,
    required this.avaliacoes,
    this.proximaProva,
  });

  factory DisciplinaNotas.fromMap(Map<String, dynamic> map, String id) {
    return DisciplinaNotas(
      id: id,
      turmaId: map['turmaId'] ?? '',
      nome: map['disciplinaNome'] ?? '',
      codigo: map['codigo'] ?? '',
      professor: map['professorNome'] ?? '',
      media: (map['media'] as num?)?.toDouble() ?? 0.0,
      status: StatusDisciplina.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'emCurso'),
        orElse: () => StatusDisciplina.emCurso
      ),
      avaliacoes: [
        AvaliacaoNota(
          nome: map['avaliacaoNome'] ?? 'Avaliação',
          nota: (map['nota'] as num?)?.toDouble(),
          data: map['dataLancamento'] != null 
              ? (map['dataLancamento'] as Timestamp).toDate().toString() 
              : '',
        )
      ],
    );
  }
}