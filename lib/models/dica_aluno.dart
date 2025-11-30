// lib/models/dica_aluno.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DicaAluno {
  final String id;
  final String texto;
  final String alunoId;
  final DateTime dataPostagem;
  final int upvotes;
  final String? nomeBaseDisciplina; // Para busca global

  DicaAluno({
    required this.id,
    required this.texto,
    required this.alunoId,
    required this.dataPostagem,
    this.upvotes = 0,
    this.nomeBaseDisciplina,
  });

  Map<String, dynamic> toMap() {
    return {
      'texto': texto,
      'alunoId': alunoId,
      'dataPostagem': Timestamp.fromDate(dataPostagem),
      'upvotes': upvotes,
      'nomeBaseDisciplina': nomeBaseDisciplina,
    };
  }

  factory DicaAluno.fromMap(Map<String, dynamic> map, String id) {
    return DicaAluno(
      id: id,
      texto: map['texto'] ?? '',
      alunoId: map['alunoId'] ?? '',
      dataPostagem: (map['dataPostagem'] as Timestamp).toDate(),
      upvotes: map['upvotes'] ?? 0,
      nomeBaseDisciplina: map['nomeBaseDisciplina'],
    );
  }
}