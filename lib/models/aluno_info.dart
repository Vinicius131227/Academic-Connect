// lib/models/aluno_info.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Um modelo de dados para as informações específicas de um aluno.
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

  /// Construtor de fábrica para criar a partir de um [Map] (vindo do Firestore).
  factory AlunoInfo.fromMap(Map<String, dynamic> data) {
    return AlunoInfo(
      nomeCompleto: data['nomeCompleto'] ?? '',
      ra: data['ra'] ?? '',
      curso: data['curso'] ?? '',
      cr: (data['cr'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'Regular',
      dataNascimento: data['dataNascimento'] == null
          ? null
          : (data['dataNascimento'] as Timestamp).toDate(),
    );
  }

  /// Converte este objeto para um [Map] para ser salvo no Firestore.
  Map<String, dynamic> toMap() {
    return {
      'nomeCompleto': nomeCompleto,
      'ra': ra,
      'curso': curso,
      'cr': cr,
      'status': status,
      'dataNascimento': dataNascimento != null
          ? Timestamp.fromDate(dataNascimento!)
          : null,
    };
  }

  /// Cria uma cópia do [AlunoInfo] com valores atualizados.
  AlunoInfo copyWith({
    String? nomeCompleto,
    String? ra,
    String? curso,
    double? cr,
    String? status,
    DateTime? dataNascimento,
  }) {
    return AlunoInfo(
      nomeCompleto: nomeCompleto ?? this.nomeCompleto,
      ra: ra ?? this.ra,
      curso: curso ?? this.curso,
      cr: cr ?? this.cr,
      status: status ?? this.status,
      dataNascimento: dataNascimento ?? this.dataNascimento,
    );
  }
}