// lib/models/material_aula.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoMaterial { link, video, prova, outro }

class MaterialAula {
  final String id;
  final String titulo;
  final String descricao;
  final String url;
  final TipoMaterial tipo;
  final DateTime dataPostagem;

  MaterialAula({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.url,
    required this.tipo,
    required this.dataPostagem,
  });

  factory MaterialAula.fromMap(Map<String, dynamic> data, String documentId) {
    return MaterialAula(
      id: documentId,
      titulo: data['titulo'] ?? '',
      descricao: data['descricao'] ?? '',
      url: data['url'] ?? '',
      tipo: TipoMaterial.values.firstWhere(
        (e) => e.name == data['tipo'],
        orElse: () => TipoMaterial.outro,
      ),
      dataPostagem: (data['dataPostagem'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'descricao': descricao,
      'url': url,
      'tipo': tipo.name,
      'dataPostagem': Timestamp.fromDate(dataPostagem),
    };
  }
}