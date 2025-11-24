// lib/models/dica_aluno.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DicaAluno {
  final String id;
  final String texto;
  final String alunoId; 
  final DateTime dataPostagem;
  final int upvotes;

  DicaAluno({
    required this.id,
    required this.texto,
    required this.alunoId,
    required this.dataPostagem,
    this.upvotes = 0,
  });

  factory DicaAluno.fromMap(Map<String, dynamic> data, String documentId) {
    return DicaAluno(
      id: documentId,
      texto: data['texto'] ?? '',
      alunoId: data['alunoId'] ?? '',
      dataPostagem: (data['dataPostagem'] as Timestamp).toDate(),
      upvotes: data['upvotes'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'texto': texto,
      'alunoId': alunoId,
      'dataPostagem': Timestamp.fromDate(dataPostagem),
      'upvotes': upvotes,
    };
  }
}