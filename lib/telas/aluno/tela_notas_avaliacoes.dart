import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// --- IMPORTES ATUALIZADOS ---
import '../../providers/provedores_app.dart';
import '../../providers/provedor_autenticacao.dart';
import '../comum/widget_carregamento.dart';
// --- FIM IMPORTES ATUALIZADOS ---
import '../../models/disciplina_notas.dart';
import '../../models/prova_agendada.dart';
import 'package:intl/intl.dart';
import '../../providers/provedor_mapas.dart';
import '../../l10n/app_localizations.dart';

class TelaNotasAvaliacoes extends ConsumerWidget {
  final String? disciplinaInicial;
  
  const TelaNotasAvaliacoes({super.key, this.disciplinaInicial});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.t('notas_titulo')),
          bottom: TabBar(
            tabs: [
              Tab(text: t.t('notas_tab_notas')),
              Tab(text: t.t('notas_tab_provas')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTabNotas(context, ref),
            _buildTabProvas(context, ref),
          ],
        ),
      ),
    );
  }

  // --- Tab 1: Notas por Disciplina (ATUALIZADO) ---
  Widget _buildTabNotas(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final asyncNotas = ref.watch(provedorStreamNotasAluno);
    final crGeral = ref.watch(provedorNotificadorAutenticacao).usuario?.alunoInfo?.cr ?? 0.0;

    return asyncNotas.when(
      loading: () => const WidgetCarregamento(),
      error: (e,s) => Center(child: Text('Erro ao carregar notas: $e')),
      data: (notas) {
        final aprovadas = notas.where((n) => n.status == StatusDisciplina.aprovado).length;
        final emCurso = notas.where((n) => n.status == StatusDisciplina.emCurso).length;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(context, t.t('notas_cr_geral'), crGeral.toStringAsFixed(2), Theme.of(context).colorScheme.primary, true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(context, t.t('notas_aprovado'), aprovadas.toString(), Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(context, t.t('notas_em_curso'), emCurso.toString(), Colors.orange),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (notas.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('Nenhuma nota lançada.'),
                )),
              ...notas.map((disciplina) {
                final bool expandir = disciplina.nome.startsWith(disciplinaInicial ?? '');
                return _buildCardDisciplina(context, t, disciplina, expandir);
              }),
            ],
          ),
        );
      }
    );
  }

  // --- Tab 2: Próximas Provas (ATUALIZADO) ---
  Widget _buildTabProvas(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final asyncProvas = ref.watch(provedorStreamCalendario);
    final formatoMes = DateFormat.MMM('pt_BR');
    final formatoDia = DateFormat.d('pt_BR');
    final theme = Theme.of(context);

    return asyncProvas.when(
      loading: () => const WidgetCarregamento(),
      error: (e,s) => Center(child: Text('Erro ao carregar provas: $e')),
      data: (provas) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Card(
                color: theme.colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: theme.colorScheme.onSecondaryContainer, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${t.t('notas_provas_aviso')} ${provas.length} ${t.t('notas_provas_aviso_plural')}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (provas.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('Nenhuma prova agendada.'),
                )),
              ...provas.map((prova) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              formatoMes.format(prova.dataHora).replaceAll('.', ''),
                              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              formatoDia.format(prova.dataHora),
                              style: theme.textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(prova.titulo, style: theme.textTheme.titleLarge),
                            const SizedBox(height: 8),
                            _buildInfoProva(context, Icons.schedule, '${prova.dataHora.hour.toString().padLeft(2, '0')}:${prova.dataHora.minute.toString().padLeft(2, '0')}'),
                            _buildInfoProva(
                              context, 
                              Icons.location_on_outlined, 
                              '${prova.predio} - ${prova.sala}',
                              isLink: true, 
                              onTap: () async {
                                try {
                                  await ref.read(provedorMapas).abrirLocalizacao(prova.predio);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            ),
                            const Divider(height: 16),
                            Text('${t.t('notas_conteudo')}:', style: theme.textTheme.bodySmall),
                            Text(prova.conteudo, style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
              // Card de Sincronizar
            ],
          ),
        );
      }
    );
  }

  // --- Widgets Auxiliares ---
  Widget _buildStatCard(BuildContext context, String label, String value, Color color, [bool isPrimary = false]) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: isPrimary ? color : color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: isPrimary ? theme.colorScheme.onPrimary : color)),
            Text(value, style: theme.textTheme.titleLarge?.copyWith(
              color: isPrimary ? theme.colorScheme.onPrimary : color,
              fontWeight: FontWeight.bold,
            )),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCardDisciplina(BuildContext context, AppLocalizations t, DisciplinaNotas disciplina, bool expandir) {
    final theme = Theme.of(context);
    return Card(
      child: ExpansionTile(
        initiallyExpanded: expandir,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    disciplina.nome,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis, 
                  ),
                ),
                const SizedBox(width: 8), 
                if (disciplina.status == StatusDisciplina.aprovado)
                  Chip(label: Text(t.t('notas_aprovado')), backgroundColor: Colors.green.withOpacity(0.2), labelStyle: TextStyle(color: Colors.green[800], fontSize: 10), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
              ],
            ),
            Text('${disciplina.codigo} • ${disciplina.professor}', style: theme.textTheme.bodySmall),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text('${t.t('notas_media')}: ${disciplina.media}', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(flex: 2, child: Text(t.t('notas_avaliacao'), style: theme.textTheme.bodySmall)),
                    Expanded(flex: 2, child: Text(t.t('notas_data'), style: theme.textTheme.bodySmall)),
                    Expanded(flex: 1, child: Text(t.t('notas_peso'), style: theme.textTheme.bodySmall, textAlign: TextAlign.center)),
                    Expanded(flex: 1, child: Text(t.t('notas_nota'), style: theme.textTheme.bodySmall, textAlign: TextAlign.right)),
                  ],
                ),
                const Divider(),
                ...disciplina.avaliacoes.map((av) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(av.nome)),
                      Expanded(flex: 2, child: Text(av.data, style: theme.textTheme.bodySmall)),
                      Expanded(flex: 1, child: Text(av.peso.toString(), textAlign: TextAlign.center)),
                      Expanded(flex: 1, child: Text(
                        av.nota?.toStringAsFixed(1) ?? t.t('notas_pendente'),
                        textAlign: TextAlign.right,
                        style: TextStyle(fontWeight: FontWeight.bold, color: av.nota == null ? Colors.grey : theme.colorScheme.primary),
                      )),
                    ],
                  ),
                )),
                // --- CORREÇÃO AQUI: .data -> .dataHora ---
                if (disciplina.proximaProva != null) ...[
                  const Divider(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.yellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${t.t('notas_proxima_prova')} ${disciplina.proximaProva!.titulo}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(DateFormat('dd/MM/yyyy \'às\' HH:mm').format(disciplina.proximaProva!.dataHora), style: theme.textTheme.bodySmall), // <-- CORRIGIDO
                              Text('${t.t('notas_conteudo')}: ${disciplina.proximaProva!.conteudo}', style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // --- FIM DA CORREÇÃO ---
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoProva(BuildContext context, IconData icon, String text, {bool isLink = false, VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: isLink ? theme.colorScheme.primary : theme.textTheme.bodySmall?.color,
      decoration: isLink ? TextDecoration.underline : TextDecoration.none,
    );
    final row = Row(
      children: [
        Icon(icon, size: 14, color: style?.color),
        const SizedBox(width: 4),
        Text(text, style: style),
      ],
    );
    if (isLink) {
      return InkWell(
        onTap: onTap,
        child: row,
      );
    }
    return row;
  }
}