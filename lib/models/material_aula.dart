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
  // Importante para a busca global de provas antigas
  final String? nomeBaseDisciplina; 

  MaterialAula({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.url,
    required this.tipo,
    required this.dataPostagem,
    this.nomeBaseDisciplina,
  });

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'descricao': descricao,
      'url': url,
      'tipo': tipo.name,
      'dataPostagem': Timestamp.fromDate(dataPostagem),
      'nomeBaseDisciplina': nomeBaseDisciplina,
    };
  }

  factory MaterialAula.fromMap(Map<String, dynamic> map, String id) {
    return MaterialAula(
      id: id,
      titulo: map['titulo'] ?? '',
      descricao: map['descricao'] ?? '',
      url: map['url'] ?? '',
      tipo: TipoMaterial.values.firstWhere(
          (e) => e.name == map['tipo'], orElse: () => TipoMaterial.outro),
      dataPostagem: (map['dataPostagem'] as Timestamp).toDate(),
      nomeBaseDisciplina: map['nomeBaseDisciplina'],
    );
  }
}