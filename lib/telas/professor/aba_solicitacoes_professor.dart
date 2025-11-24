import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/solicitacao_aluno.dart';
import '../../providers/provedores_app.dart';
import '../../services/servico_firestore.dart';
import '../comum/widget_carregamento.dart';
import 'package:intl/intl.dart';
import 'dialog_detalhes_solicitacao.dart';
import '../../l10n/app_localizations.dart';
import '../comum/animacao_fadein_lista.dart'; 

class AbaSolicitacoesProfessor extends ConsumerWidget {
  const AbaSolicitacoesProfessor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final asyncSolicitacoes = ref.watch(provedorStreamSolicitacoesProfessor);

    return asyncSolicitacoes.when(
      loading: () => const WidgetCarregamento(),
      error: (err, st) => Center(child: Text('Erro ao carregar solicitações: $err')),
      data: (solicitacoes) {
        final pendentes = solicitacoes.where((s) => s.status == StatusSolicitacao.pendente).length;
        
        // Separa as listas para mostrar pendentes primeiro
        final listaPendentes = solicitacoes.where((s) => s.status == StatusSolicitacao.pendente).toList();
        final listaRespondidas = solicitacoes.where((s) => s.status != StatusSolicitacao.pendente).toList();
        
        final widgets = [
          ...listaPendentes.map((s) => _buildCardSolicitacao(context, t, ref, s)),
          ...listaRespondidas.map((s) => _buildCardSolicitacao(context, t, ref, s)),
        ];

        return Column(
          children: [
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '$pendentes ${t.t('prof_solicitacoes_pendentes')}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold
                    ),
              ),
            ),
            if (solicitacoes.isEmpty)
              const Expanded(
                child: Center(child: Text('Nenhuma solicitação encontrada.')),
              )
            else
              Expanded(child: FadeInListAnimation(children: widgets)),
          ],
        );
      },
    );
  }

  Widget _buildCardSolicitacao(BuildContext context, AppLocalizations t, WidgetRef ref, SolicitacaoAluno s) {
    final theme = Theme.of(context);
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
        statusTexto = 'Recusada'; // Adicionar tradução se necessário
        break;
    }

    return Card(
      color: s.status == StatusSolicitacao.pendente ? null : theme.colorScheme.surface.withOpacity(0.5),
      elevation: s.status == StatusSolicitacao.pendente ? 1 : 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.nomeAluno, style: theme.textTheme.titleMedium),
                Text(DateFormat('dd/MM/yyyy').format(s.data), style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('RA: ${s.ra}', style: theme.textTheme.bodySmall),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusTexto,
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text('${t.t('prof_solicitacoes_dialog_disciplina')}: ${s.disciplina}', style: theme.textTheme.bodySmall),
            Text('${t.t('prof_solicitacoes_dialog_tipo')}: ${s.tipo}', style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(
              s.descricao,
              style: theme.textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (s.anexo != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file, size: 16),
                    const SizedBox(width: 4),
                    Text(s.anexo!, style: TextStyle(color: theme.colorScheme.primary, fontSize: 14)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            
            _buildBotoesLinha(context, t, ref, s),
          ],
        ),
      ),
    );
  }

  Widget _buildBotoesLinha(BuildContext context, AppLocalizations t, WidgetRef ref, SolicitacaoAluno s) {
    // Função para mostrar o diálogo de recusa
    void _mostrarDialogRecusa() {
      final motivoController = TextEditingController();
      final formKey = GlobalKey<FormState>();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.t('prof_solicitacoes_recusar')),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: motivoController,
              decoration: const InputDecoration(
                labelText: 'Motivo da recusa *',
                hintText: 'Explique o motivo para o aluno...',
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
              maxLines: 3,
            ),
          ),
          actions: [
            TextButton(
              child: Text(t.t('config_sair_dialog_cancelar')),
              onPressed: () => Navigator.pop(ctx),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Confirmar Recusa'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  ref.read(servicoFirestoreProvider).atualizarSolicitacao(
                        s.id,
                        StatusSolicitacao.recusada,
                        motivoController.text, // Passa o motivo
                      );
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
      );
    }

    // Função para aprovar 
    void _aprovar() {
       ref.read(servicoFirestoreProvider).atualizarSolicitacao(
             s.id,
             StatusSolicitacao.aprovada,
             'Sua solicitação foi aprovada.', // Resposta padrão
           );
    }
    
    return Row(
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.visibility_outlined, size: 16),
          label: Text(t.t('prof_solicitacoes_ver_detalhes')),
          onPressed: () {
            mostrarDialogDetalhesSolicitacao(context, s);
          },
        ),
        const Spacer(),
        if (s.status == StatusSolicitacao.pendente) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: t.t('prof_solicitacoes_aprovar'),
            style: IconButton.styleFrom(
              backgroundColor: Colors.green.withOpacity(0.1),
              foregroundColor: Colors.green,
            ),
            onPressed: _aprovar,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: t.t('prof_solicitacoes_recusar'),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              foregroundColor: Colors.red,
            ),
            onPressed: _mostrarDialogRecusa, 
          ),
        ],
      ],
    );
  }
}