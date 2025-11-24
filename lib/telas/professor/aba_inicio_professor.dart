// lib/telas/professor/aba_inicio_professor.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Import para formatação de data
import '../../models/turma_professor.dart';
import '../../models/solicitacao_aluno.dart';
import '../comum/animacao_fadein_lista.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../providers/provedores_app.dart';
import '../comum/widget_carregamento.dart';

class AbaInicioProfessor extends ConsumerWidget {
  final ValueSetter<int> onNavigateToTab;

  const AbaInicioProfessor({super.key, required this.onNavigateToTab});

  // --- (NOVO) Helper para filtrar aulas de hoje ---
  String _getDiaSemanaAtual() {
    // Retorna o nome do dia da semana em português (ex: "seg", "ter")
    // para bater com o formato de 'horario' (ex: "Seg 14:00-16:00")
    final int weekday = DateTime.now().weekday;
    switch (weekday) {
      case DateTime.monday:
        return 'seg';
      case DateTime.tuesday:
        return 'ter';
      case DateTime.wednesday:
        return 'qua';
      case DateTime.thursday:
        return 'qui';
      case DateTime.friday:
        return 'sex';
      case DateTime.saturday:
        return 'sab';
      case DateTime.sunday:
        return 'dom';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    // --- LENDO DADOS REAIS DO FIREBASE ---
    final nomeProf = ref.watch(provedorNotificadorAutenticacao).usuario?.alunoInfo?.nomeCompleto ?? 'Professor';
    final asyncTurmas = ref.watch(provedorStreamTurmasProfessor);
    final solicitacoesPendentes = ref.watch(provedorSolicitacoesPendentes);
    // --- FIM DOS DADOS ---

    final widgets = [
      // Card de Boas-Vindas
      Card(
        color: theme.colorScheme.primary,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${t.t('prof_bemvindo')}, $nomeProf!',
                style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                t.t('prof_resumo'),
                style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary.withOpacity(0.9),
                      ),
              ),
            ],
          ),
        ),
      ),
      
      // Botões de Ação Rápida
      Row(
        children: [
          Expanded(
            child: _buildAcaoRapida(
              context,
              icon: Icons.nfc,
              label: t.t('prof_acao_presenca'),
              onTap: () {
                onNavigateToTab(1); // Navega para a aba "Turmas"
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildAcaoRapida(
              context,
              icon: Icons.assignment,
              label: t.t('prof_acao_notas'),
              onTap: () {
                onNavigateToTab(1); // Navega para a aba "Turmas"
              },
            ),
          ),
        ],
      ),
      // --- REMOVIDO: Botão de "Enviar Comunicado" ---

      // Aulas de Hoje
      _buildSecao(
        context,
        t: t,
        titulo: t.t('prof_aulas_hoje'),
        icone: Icons.calendar_today_outlined,
        filhos: [
          asyncTurmas.when(
            loading: () => const WidgetCarregamento(texto: 'Carregando turmas...'),
            error: (err, st) => Text('Erro ao carregar turmas: $err'),
            data: (turmas) {
              
              // --- (IMPLEMENTADO) Lógica de filtro para "hoje" ---
              final diaAtual = _getDiaSemanaAtual();
              final aulasHoje = turmas
                  .where((turma) =>
                      turma.horario.toLowerCase().contains(diaAtual))
                  .toList();
              // --- FIM DA LÓGICA ---
              
              if (aulasHoje.isEmpty) {
                return Center(child: Text(t.t('prof_sem_aulas')));
              }
              return Column(
                children: aulasHoje.map((turma) => _buildCardAulaHoje(context, turma)).toList(),
              );
            },
          ),
        ],
      ),

      // Solicitações Pendentes
      _buildSecao(
        context,
        t: t,
        titulo: t.t('prof_solicitacoes'),
        icone: Icons.inbox_outlined,
        badgeCount: solicitacoesPendentes.length,
        filhos: [
          if (solicitacoesPendentes.isEmpty)
            Text(t.t('prof_sem_solicitacoes'))
          else
            ...solicitacoesPendentes
                .take(2) // Mostra no máximo 2 na dashboard
                .map((s) => _buildCardSolicitacaoPendente(context, s)),
          if (solicitacoesPendentes.length > 2)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextButton(
                onPressed: () {
                  onNavigateToTab(2); // Navega para a aba "Solicitações"
                },
                child: Text(t.t('prof_ver_todas')),
              ),
            ),
        ],
      ),

      // Stats
      _buildSecao(
        context,
        t: t,
        titulo: t.t('prof_visao_geral'),
        icone: Icons.bar_chart_outlined,
        filhos: [
          asyncTurmas.when(
            loading: () => const WidgetCarregamento(texto: ''),
            error: (err, st) => const Text('Erro ao carregar dados'),
            data: (turmas) {
              final int totalAlunos = turmas.fold(0, (prev, turma) => prev + turma.alunosInscritos.length);
              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(context, totalAlunos.toString(), t.t('prof_total_alunos')),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(context, turmas.length.toString(), t.t('prof_turmas_ativas')),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ];
    
    return FadeInListAnimation(children: widgets);
  }

  // --- Widgets Auxiliares ---
  Widget _buildAcaoRapida(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onTap, bool isWide = false}) {
    final theme = Theme.of(context);
    
    if (!isWide) {
      return Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Icon(icon, size: 24, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 12),
                Text(label, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Icon(icon, size: 24, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Text(label, style: theme.textTheme.titleMedium),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, size: 16, color: theme.textTheme.bodySmall?.color),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSecao(BuildContext context,
      {required AppLocalizations t,
      required String titulo,
      required IconData icone,
      int? badgeCount,
      required List<Widget> filhos}) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(titulo, style: theme.textTheme.titleLarge),
                if (badgeCount != null && badgeCount > 0) ...[
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.orange[800],
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            const Divider(height: 24),
            ...filhos,
          ],
        ),
      ),
    );
  }
  
  Widget _buildCardAulaHoje(BuildContext context, TurmaProfessor turma) {
    final theme = Theme.of(context);
    // Extrai a hora do campo 'horario'
    final String hora = turma.horario.split(' ').length > 1 ? turma.horario.split(' ')[1] : turma.horario;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(turma.nome, style: theme.textTheme.bodyLarge)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(hora, style: theme.textTheme.bodySmall),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: theme.colorScheme.secondary),
                  Text(turma.local, style: theme.textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildCardSolicitacaoPendente(BuildContext context, SolicitacaoAluno s) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.nomeAluno, style: theme.textTheme.bodyLarge),
                Text('${s.disciplina} • ${s.tipo}',
                    style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange[600],
                          )),
              ],
            ),
          ),
          Text(DateFormat('dd/MM/yyyy').format(s.data), style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(BuildContext context, String valor, String label) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              valor,
              style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 4),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}