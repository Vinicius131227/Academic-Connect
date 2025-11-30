// lib/models/aluno_info.dart

/// Modelo que agrupa as informações acadêmicas específicas de um aluno.
class AlunoInfo {
  final String nomeCompleto;
  final String ra; // Registro Acadêmico
  final String curso;
  final double cr; // Coeficiente de Rendimento
  final String status; // Ex: Regular, Trancado
  final DateTime? dataNascimento;

  AlunoInfo({
    required this.nomeCompleto,
    required this.ra,
    required this.curso,
    required this.cr,
    required this.status,
    this.dataNascimento,
  });

  /// Converte para Mapa (Salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      'nomeCompleto': nomeCompleto,
      'ra': ra,
      'curso': curso,
      'cr': cr,
      'status': status,
      'dataNascimento': dataNascimento?.toIso8601String(),
    };
  }

  /// Cria objeto a partir do Mapa (Ler do Firestore)
  factory AlunoInfo.fromMap(Map<String, dynamic> map) {
    return AlunoInfo(
      nomeCompleto: map['nomeCompleto'] ?? '',
      ra: map['ra'] ?? '',
      curso: map['curso'] ?? '',
      cr: (map['cr'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Regular',
      dataNascimento: map['dataNascimento'] != null 
          ? DateTime.tryParse(map['dataNascimento']) 
          : null,
    );
  }
}