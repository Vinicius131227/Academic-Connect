import 'package:cloud_firestore/cloud_firestore.dart';

class PastaDrive {
  final String id;
  final String nome;
  final String? parentId; // ID da pasta pai (null se for raiz)
  final String criadoPor;
  final DateTime dataCriacao;

  PastaDrive({
    required this.id,
    required this.nome,
    this.parentId,
    required this.criadoPor,
    required this.dataCriacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'parentId': parentId,
      'criadoPor': criadoPor,
      'dataCriacao': Timestamp.fromDate(dataCriacao),
    };
  }

  factory PastaDrive.fromMap(Map<String, dynamic> map, String id) {
    return PastaDrive(
      id: id,
      nome: map['nome'] ?? 'Sem Nome',
      parentId: map['parentId'],
      criadoPor: map['criadoPor'] ?? '',
      dataCriacao: (map['dataCriacao'] as Timestamp).toDate(),
    );
  }
}