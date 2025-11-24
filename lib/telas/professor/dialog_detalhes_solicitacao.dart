import 'package:flutter/material.dart';
import '../../models/solicitacao_aluno.dart';
import '../../l10n/app_localizations.dart'; 
import 'package:intl/intl.dart'; // <-- NOVO IMPORT

void mostrarDialogDetalhesSolicitacao(BuildContext context, SolicitacaoAluno s) {
  final t = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  Color statusColor;
  String statusTexto;
  switch (s.status) {
    case StatusSolicitacao.pendente:
      statusColor = Colors.orange;
      statusTexto = 'Pendente';
      break;
    case StatusSolicitacao.aprovada:
      statusColor = Colors.green;
      statusTexto = t.t('notas_aprovado');
      break;
    case StatusSolicitacao.recusada:
      statusColor = Colors.red;
      statusTexto = 'Recusada'; 
      break;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, 
    builder: (context) {
      return Container(
        margin: const EdgeInsets.all(8),
        child: Material(
          borderRadius: BorderRadius.circular(16),
          color: theme.cardTheme.color,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      t.t('prof_solicitacoes_dialog_titulo'),
                      style: theme.textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow(context, t.t('prof_solicitacoes_dialog_aluno'), s.nomeAluno, t.t('prof_solicitacoes_dialog_ra'), s.ra),
                _buildInfoRow(context, t.t('prof_solicitacoes_dialog_disciplina'), s.disciplina, t.t('prof_solicitacoes_dialog_tipo'), s.tipo),
                _buildInfoRow(context, t.t('prof_solicitacoes_dialog_data'), DateFormat('dd/MM/yyyy').format(s.data), t.t('prof_solicitacoes_dialog_status'), statusTexto, value2Color: statusColor),
                const Divider(height: 24),
                Text(t.t('prof_solicitacoes_dialog_descricao'), style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(s.descricao, style: theme.textTheme.bodyMedium),
                ),
                const SizedBox(height: 16),
                
                // --- NOVO: Mostra a resposta do professor se existir ---
                if (s.respostaProfessor != null && s.respostaProfessor!.isNotEmpty) ...[
                  Text('Sua Resposta:', style: theme.textTheme.titleSmall), // TODO: Traduzir
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colorScheme.primary)
                    ),
                    child: Text(s.respostaProfessor!, style: theme.textTheme.bodyMedium),
                  ),
                  const SizedBox(height: 16),
                ],
                // --- FIM DA ATUALIZAÇÃO ---

                if (s.anexo != null) ...[
                  Text(t.t('prof_solicitacoes_dialog_anexo'), style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.download, size: 16),
                    label: Text('${t.t('prof_solicitacoes_dialog_baixar')} ${s.anexo!}'),
                    onPressed: () {
                      // TODO: Lógica para baixar anexo (usar url_launcher)
                    },
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: isDark ? theme.colorScheme.onSurface : theme.colorScheme.surface,
                    foregroundColor: isDark ? theme.colorScheme.surface : theme.colorScheme.onSurface,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(t.t('prof_solicitacoes_dialog_fechar')),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildInfoRow(BuildContext context, String label1, String value1,
    String label2, String value2, {Color? value2Color}) {
  final theme = Theme.of(context);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label1, style: theme.textTheme.bodySmall),
              Text(value1, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label2, style: theme.textTheme.bodySmall),
              Text(
                value2,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: value2Color,
                  fontWeight: value2Color != null ? FontWeight.bold : null,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}