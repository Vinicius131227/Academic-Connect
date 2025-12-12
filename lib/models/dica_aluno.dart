// lib/models/dica_aluno.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DicaAluno {
  final String id;
  final String texto;
  final String alunoId;
  final String autorNome; // Nome para exibir (ex: "João")
  final DateTime dataPostagem;
  final int upvotes;
  final String materia; // A Tag (ex: "Cálculo 1")
  final String? nomeBaseDisciplina; // Para busca global

  DicaAluno({
    required this.id,
    required this.texto,
    required this.alunoId,
    this.autorNome = 'Anônimo',
    required this.dataPostagem,
    this.upvotes = 0,
    required this.materia,
    this.nomeBaseDisciplina,
  });

  Map<String, dynamic> toMap() {
    return {
      'texto': texto,
      'alunoId': alunoId,
      'autorNome': autorNome,
      'dataPostagem': Timestamp.fromDate(dataPostagem),
      'upvotes': upvotes,
      'materia': materia,
      'nomeBaseDisciplina': nomeBaseDisciplina,
    };
  }

  factory DicaAluno.fromMap(Map<String, dynamic> map, String id) {
    return DicaAluno(
      id: id,
      texto: map['texto'] ?? '',
      alunoId: map['alunoId'] ?? '',
      autorNome: map['autorNome'] ?? 'Anônimo',
      dataPostagem: (map['dataPostagem'] as Timestamp).toDate(),
      upvotes: map['upvotes'] ?? 0,
      materia: map['materia'] ?? 'Geral',
      nomeBaseDisciplina: map['nomeBaseDisciplina'],
    );
  }
}