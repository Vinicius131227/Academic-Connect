// lib/models/solicitacao_adaptacao.dart
enum StatusSolicitacao { emAnalise, aprovada, recusada }

class SolicitacaoAdaptacao {
  final String disciplina;
  final String tipo;
  final StatusSolicitacao status;
  final String data;

  SolicitacaoAdaptacao({
    required this.disciplina,
    required this.tipo,
    required this.status,
    required this.data,
  });
}