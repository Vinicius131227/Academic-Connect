import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa uma avaliação (prova, trabalho) agendada.
/// Armazenado na coleção 'provas'.
class ProvaAgendada {
  final String id; // ID do documento no Firestore
  final String turmaId; // ID da turma (para filtrar)
  final String titulo; // Ex: "P1", "Trabalho Final"
  final String disciplina; // Nome da disciplina (para exibição)
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

  /// Construtor de fábrica para criar a partir de um [Map] (lido do Firestore)
  factory ProvaAgendada.fromMap(Map<String, dynamic> data, String documentId) {
    return ProvaAgendada(
      id: documentId,
      turmaId: data['turmaId'] ?? '',
      titulo: data['titulo'] ?? '',
      disciplina: data['disciplina'] ?? '',
      // Converte o Timestamp do Firestore para DateTime do Dart
      dataHora: (data['dataHora'] as Timestamp).toDate(),
      predio: data['predio'] ?? '',
      sala: data['sala'] ?? '',
      conteudo: data['conteudo'] ?? '',
    );
  }

  /// Converte este objeto para um [Map] (para salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      'turmaId': turmaId,
      'titulo': titulo,
      'disciplina': disciplina,
      // Converte o DateTime do Dart para Timestamp do Firestore
      'dataHora': Timestamp.fromDate(dataHora),
      'predio': predio,
      'sala': sala,
      'conteudo': conteudo,
    };
  }
}