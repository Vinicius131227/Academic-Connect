// lib/models/atividade_evento.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AtividadeEvento {
  final String id;
  final String nome; // "Palestra 1", "Minicurso A"
  final DateTime dataHora;
  final String local;
  final List<String> presentes; // UIDs dos alunos presentes

  AtividadeEvento({
    required this.id,
    required this.nome,
    required this.dataHora,
    required this.local,
    required this.presentes,
  });

  factory AtividadeEvento.fromMap(Map<String, dynamic> data, String id) {
    return AtividadeEvento(
      id: id,
      nome: data['nome'] ?? '',
      dataHora: (data['dataHora'] as Timestamp).toDate(),
      local: data['local'] ?? '',
      presentes: List<String>.from(data['presentes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'dataHora': Timestamp.fromDate(dataHora),
      'local': local,
      'presentes': presentes,
    };
  }
}