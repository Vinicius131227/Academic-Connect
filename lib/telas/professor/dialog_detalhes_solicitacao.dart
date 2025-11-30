// lib/telas/professor/dialog_detalhes_solicitacao.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../models/solicitacao_aluno.dart';
import '../../services/servico_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';

/// Caso de uso para o Widgetbook.
/// Mostra o diálogo de detalhes de solicitação.
@UseCase(
  name: 'Detalhes Solicitação',
  type: DialogDetalhesSolicitacao,
)
Widget buildDialogDetalhesSolicitacao(BuildContext context) {
  return ProviderScope(
    child: DialogDetalhesSolicitacao(
      solicitacao: SolicitacaoAluno(
        id: '1', 
        nomeAluno: 'João Silva', 
        ra: '123456', 
        disciplina: 'Cálculo 1', 
        tipo: 'Adaptação', 
        data: DateTime.now(), 
        descricao: 'Preciso de tempo extra.', 
        status: StatusSolicitacao.pendente, 
        alunoId: 'aluno1', 
        professorId: 'prof1', 
        turmaId: 'turma1'
      ),
    ),
  );
}

/// Diálogo que exibe os detalhes de uma solicitação de aluno e permite
/// ao professor Aprovar ou Recusar.
class DialogDetalhesSolicitacao extends ConsumerStatefulWidget {
  final SolicitacaoAluno solicitacao;

  const DialogDetalhesSolicitacao({
    super.key, 
    required this.solicitacao
  });

  @override
  ConsumerState<DialogDetalhesSolicitacao> createState() => _DialogDetalhesSolicitacaoState();
}

class _DialogDetalhesSolicitacaoState extends ConsumerState<DialogDetalhesSolicitacao> {
  bool _isProcessing = false;

  /// Atualiza o status da solicitação no Firebase.
  Future<void> _atualizarStatus(StatusSolicitacao novoStatus) async {
    setState(() => _isProcessing = true);
    final t = AppLocalizations.of(context)!;
    
    try {
      // Chama o serviço para atualizar
      // A resposta aqui é fixa para o MVP, mas poderia ser um campo de texto
      String resposta = novoStatus == StatusSolicitacao.aprovada 
          ? "Sua solicitação foi aprovada." 
          : "Sua solicitação foi recusada.";

      await ref.read(servicoFirestoreProvider).atualizarSolicitacao(
        widget.solicitacao.id, 
        novoStatus, 
        resposta
      );

      if (mounted) {
        Navigator.pop(context); // Fecha o diálogo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.t('sucesso')), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t.t('erro_generico')}: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Cores do Diálogo
    final bgColor = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = theme.textTheme.bodyLarge?.color;

    return AlertDialog(
      backgroundColor: bgColor,
      title: Text(t.t('prof_solicitacoes_dialog_titulo'), style: TextStyle(color: textColor)), // "Detalhes da Solicitação"
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow(t.t('prof_solicitacoes_dialog_aluno'), widget.solicitacao.nomeAluno, textColor),
            _buildRow(t.t('prof_solicitacoes_dialog_ra'), widget.solicitacao.ra, textColor),
            _buildRow(t.t('prof_solicitacoes_dialog_tipo'), widget.solicitacao.tipo, textColor),
            _buildRow(t.t('prof_solicitacoes_dialog_data'), DateFormat('dd/MM/yyyy').format(widget.solicitacao.data), textColor),
            const Divider(),
            Text(t.t('prof_solicitacoes_dialog_descricao'), style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 4),
            Text(widget.solicitacao.descricao, style: TextStyle(color: textColor)),
            
            if (widget.solicitacao.anexo != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.attach_file, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      "${t.t('prof_solicitacoes_dialog_anexo')}: ${widget.solicitacao.anexo}", 
                      style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blue),
                      overflow: TextOverflow.ellipsis
                    ),
                  ),
                ],
              )
            ]
          ],
        ),
      ),
      actions: [
        if (_isProcessing)
          const Center(child: CircularProgressIndicator())
        else ...[
          // Botão Recusar
          TextButton(
            onPressed: () => _atualizarStatus(StatusSolicitacao.recusada),
            child: Text(
              t.t('prof_solicitacoes_recusar'), 
              style: const TextStyle(color: AppColors.error)
            ),
          ),
          // Botão Aprovar
          ElevatedButton(
            onPressed: () => _atualizarStatus(StatusSolicitacao.aprovada),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(
              t.t('prof_solicitacoes_aprovar'), 
              style: const TextStyle(color: Colors.white)
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildRow(String label, String value, Color? color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          Expanded(child: Text(value, style: TextStyle(color: color))),
        ],
      ),
    );
  }
}