// lib/telas/aluno/tela_notas_avaliacoes.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../providers/provedores_app.dart';
import '../../providers/provedor_autenticacao.dart';
import '../comum/widget_carregamento.dart';
import '../../models/disciplina_notas.dart'; // Modelo de notas
import '../../models/prova_agendada.dart'; // Modelo de provas
import '../../providers/provedor_mapas.dart'; // Para abrir mapa
import '../../l10n/app_localizations.dart'; // Traduções
import '../../themes/app_theme.dart'; // Cores

/// Caso de uso para o Widgetbook.
@UseCase(
  name: 'Notas e Avaliações',
  type: TelaNotasAvaliacoes,
)
Widget buildTelaNotasAvaliacoes(BuildContext context) {
  return const ProviderScope(
    child: TelaNotasAvaliacoes(),
  );
}

/// Tela que exibe as notas e as próximas avaliações do aluno.
class TelaNotasAvaliacoes extends ConsumerWidget {
  /// Se fornecido, a lista de notas já abre expandida nesta disciplina.
  final String? disciplinaInicial;
  
  const TelaNotasAvaliacoes({super.key, this.disciplinaInicial});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            t.t('notas_titulo'), // "Minhas Notas"
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
          bottom: TabBar(
            labelColor: AppColors.primaryPurple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primaryPurple,
            tabs: [
              Tab(text: t.t('notas_tab_notas')), // "Notas por Disciplina"
              Tab(text: t.t('notas_tab_provas')), // "Próximas Provas"
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

  // --- ABA 1: NOTAS POR DISCIPLINA ---
  Widget _buildTabNotas(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final asyncNotas = ref.watch(provedorStreamNotasAluno);
    final crGeral = ref.watch(provedorNotificadorAutenticacao).usuario?.alunoInfo?.cr ?? 0.0;
    
    // Cores
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = theme.textTheme.bodyLarge?.color;

    return asyncNotas.when(
      loading: () => const WidgetCarregamento(),
      error: (e,s) => Center(child: Text('${t.t('erro_generico')}: $e')),
      data: (notas) {
        // Cálculos estatísticos
        final aprovadas = notas.where((n) => n.status == StatusDisciplina.aprovado).length;
        final emCurso = notas.where((n) => n.status == StatusDisciplina.emCurso).length;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              // Card de Estatísticas
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context, 
                      t.t('notas_cr_geral'), // "CR Geral"
                      crGeral.toStringAsFixed(2), 
                      AppColors.primaryPurple, 
                      true
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context, 
                      t.t('notas_aprovado'), // "Aprovado"
                      aprovadas.toString(), 
                      Colors.green
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context, 
                      t.t('notas_em_curso'), // "Em Curso"
                      emCurso.toString(), 
                      Colors.orange
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (notas.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      t.t('notas_vazio'), // "Nenhuma nota lançada"
                      style: TextStyle(color: textColor?.withOpacity(0.6))
                    ),
                  )
                ),
                
              // Lista de Disciplinas (ExpansionTile)
              ...notas.map((disciplina) {
                final bool expandir = disciplina.nome.startsWith(disciplinaInicial ?? '');
                return Card(
                  color: cardColor,
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1, 
                                overflow: TextOverflow.ellipsis, 
                              ),
                            ),
                            const SizedBox(width: 8), 
                            if (disciplina.status == StatusDisciplina.aprovado)
                              Chip(
                                label: Text(t.t('notas_aprovado')), 
                                backgroundColor: Colors.green.withOpacity(0.2), 
                                labelStyle: TextStyle(color: Colors.green[800], fontSize: 10), 
                                padding: EdgeInsets.zero, 
                                visualDensity: VisualDensity.compact
                              ),
                          ],
                        ),
                        Text(
                          '${disciplina.codigo} • ${disciplina.professor}', 
                          style: theme.textTheme.bodySmall
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${t.t('notas_media')}: ${disciplina.media.toStringAsFixed(1)}', 
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.primaryPurple, 
                          fontWeight: FontWeight.bold
                        )
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          children: [
                            // Cabeçalho da Tabela
                            Row(
                              children: [
                                Expanded(flex: 2, child: Text(t.t('notas_avaliacao'), style: theme.textTheme.bodySmall)),
                                Expanded(flex: 2, child: Text(t.t('notas_data'), style: theme.textTheme.bodySmall)),
                                Expanded(flex: 1, child: Text(t.t('notas_peso'), style: theme.textTheme.bodySmall, textAlign: TextAlign.center)),
                                Expanded(flex: 1, child: Text(t.t('notas_nota'), style: theme.textTheme.bodySmall, textAlign: TextAlign.right)),
                              ],
                            ),
                            const Divider(),
                            
                            // Lista de Avaliações
                            ...disciplina.avaliacoes.map((av) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  Expanded(flex: 2, child: Text(av.nome, style: TextStyle(color: textColor))),
                                  Expanded(flex: 2, child: Text(av.data, style: theme.textTheme.bodySmall)),
                                  Expanded(flex: 1, child: Text(av.peso.toString(), textAlign: TextAlign.center, style: TextStyle(color: textColor))),
                                  Expanded(flex: 1, child: Text(
                                    av.nota?.toStringAsFixed(1) ?? t.t('notas_pendente'),
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold, 
                                      color: av.nota == null ? Colors.grey : AppColors.primaryPurple
                                    ),
                                  )),
                                ],
                              ),
                            )),

                            // Alerta de Próxima Prova
                            if (disciplina.proximaProva != null) ...[
                              const Divider(height: 24),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange.withOpacity(0.3))
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${t.t('notas_proxima_prova')} ${disciplina.proximaProva!.titulo}', 
                                            style: TextStyle(fontWeight: FontWeight.bold, color: textColor)
                                          ),
                                          Text(
                                            DateFormat('dd/MM/yyyy \'às\' HH:mm').format(disciplina.proximaProva!.dataHora), 
                                            style: TextStyle(color: textColor?.withOpacity(0.7), fontSize: 12)
                                          ),
                                          Text(
                                            '${t.t('notas_conteudo')}: ${disciplina.proximaProva!.conteudo}', 
                                            style: TextStyle(color: textColor?.withOpacity(0.7), fontSize: 12)
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      }
    );
  }

  // --- ABA 2: PRÓXIMAS PROVAS ---
  Widget _buildTabProvas(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final asyncProvas = ref.watch(provedorStreamCalendario);
    
    final formatoMes = DateFormat.MMM(Localizations.localeOf(context).toString());
    final formatoDia = DateFormat.d(Localizations.localeOf(context).toString());
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = theme.textTheme.bodyLarge?.color;

    return asyncProvas.when(
      loading: () => const WidgetCarregamento(),
      error: (e,s) => Center(child: Text('${t.t('erro_generico')}: $e')),
      data: (provas) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              // Aviso de Quantidade
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
                Center(child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    t.t('provas_vazio'), // "Nenhuma prova agendada"
                    style: TextStyle(color: textColor?.withOpacity(0.6))
                  ),
                )),
                
              // Lista Cronológica
              ...provas.map((prova) => Card(
                color: cardColor,
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Data (Bloco Colorido)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              formatoMes.format(prova.dataHora).replaceAll('.', '').toUpperCase(),
                              style: const TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              formatoDia.format(prova.dataHora),
                              style: TextStyle(
                                fontSize: 20, 
                                fontWeight: FontWeight.bold, 
                                color: textColor
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Detalhes
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(prova.titulo, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(prova.disciplina, style: TextStyle(color: textColor?.withOpacity(0.7))),
                            const SizedBox(height: 8),
                            _buildInfoProva(
                              context, 
                              Icons.schedule, 
                              '${prova.dataHora.hour.toString().padLeft(2, '0')}:${prova.dataHora.minute.toString().padLeft(2, '0')}',
                              textColor
                            ),
                            _buildInfoProva(
                              context, 
                              Icons.location_on_outlined, 
                              '${prova.predio} - ${prova.sala}',
                              textColor,
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
            ],
          ),
        );
      }
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildStatCard(BuildContext context, String label, String value, Color color, [bool isPrimary = false]) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Adapta a cor do texto se o fundo for claro
    final textCol = isPrimary ? Colors.white : (isDark ? Colors.white : Colors.black87);

    return Card(
      elevation: 0,
      color: isPrimary ? color : color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: textCol.withOpacity(0.8))),
            const SizedBox(height: 4),
            Text(
              value, 
              style: theme.textTheme.titleLarge?.copyWith(
                color: textCol,
                fontWeight: FontWeight.bold,
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoProva(BuildContext context, IconData icon, String text, Color? color, {bool isLink = false, VoidCallback? onTap}) {
    final style = TextStyle(
      fontSize: 12,
      color: isLink ? AppColors.primaryPurple : color?.withOpacity(0.7),
      decoration: isLink ? TextDecoration.underline : TextDecoration.none,
    );
    
    final row = Row(
      children: [
        Icon(icon, size: 14, color: style.color),
        const SizedBox(width: 4),
        Text(text, style: style),
      ],
    );
    
    if (isLink) {
      return InkWell(onTap: onTap, child: row);
    }
    return row;
  }
}