// lib/models/prova_agendada.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa um evento no calendário (Prova ou Trabalho).
class ProvaAgendada {
  final String id;
  final String turmaId;
  final String titulo;     // Ex: P1
  final String disciplina; // Nome da matéria para exibição rápida
  final DateTime dataHora;
  final String predio;
  final String sala;
  final String conteudo;

  ProvaAgendada({
    required this.id,
    required this.turmaId,
    required this.titulo,
    required this.disciplina,
    required this.dataHora,
    required this.predio,
    required this.sala,
    required this.conteudo,
  });

  Map<String, dynamic> toMap() {
    return {
      'turmaId': turmaId,
      'titulo': titulo,
      'disciplina': disciplina,
      'dataHora': Timestamp.fromDate(dataHora),
      'predio': predio,
      'sala': sala,
      'conteudo': conteudo,
    };
  }

  factory ProvaAgendada.fromMap(Map<String, dynamic> map, String id) {
    return ProvaAgendada(
      id: id,
      turmaId: map['turmaId'] ?? '',
      titulo: map['titulo'] ?? '',
      disciplina: map['disciplina'] ?? '',
      dataHora: (map['dataHora'] as Timestamp).toDate(),
      predio: map['predio'] ?? '',
      sala: map['sala'] ?? '',
      conteudo: map['conteudo'] ?? '',
    );
  }
}