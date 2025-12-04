// lib/models/aluno_info.dart
import 'package:cloud_firestore/cloud_firestore.dart'; // Necessário para Timestamp

class AlunoInfo {
  final String nomeCompleto;
  final String ra;
  final String curso;
  final double cr;
  final String status;
  final DateTime? dataNascimento;

  AlunoInfo({
    required this.nomeCompleto,
    required this.ra,
    required this.curso,
    required this.cr,
    required this.status,
    this.dataNascimento,
  });

  Map<String, dynamic> toMap() {
    return {
      'nomeCompleto': nomeCompleto,
      'ra': ra,
      'curso': curso,
      'cr': cr,
      'status': status,
      'dataNascimento': dataNascimento != null ? Timestamp.fromDate(dataNascimento!) : null,
    };
  }

  factory AlunoInfo.fromMap(Map<String, dynamic> map) {
    // --- CORREÇÃO DE DATA (TIMESTAMP vs STRING) ---
    DateTime? dataNasc;
    if (map['dataNascimento'] != null) {
      if (map['dataNascimento'] is Timestamp) {
        dataNasc = (map['dataNascimento'] as Timestamp).toDate();
      } else if (map['dataNascimento'] is String) {
        dataNasc = DateTime.tryParse(map['dataNascimento']);
      }
    }
    // ----------------------------------------------

    return AlunoInfo(
      nomeCompleto: map['nomeCompleto'] ?? '',
      ra: map['ra'] ?? '',
      curso: map['curso'] ?? '',
      cr: (map['cr'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Regular',
      dataNascimento: dataNasc,
    );
  }
}