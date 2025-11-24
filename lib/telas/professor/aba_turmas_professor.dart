// lib/telas/professor/aba_turmas_professor.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/turma_professor.dart';
import '../../providers/provedor_professor.dart';
import '../../providers/provedores_app.dart';
import '../comum/widget_carregamento.dart';
import 'tela_criar_turma.dart';
import 'tela_chamada_manual.dart';
import 'tela_presenca_nfc.dart';
import 'tela_lancar_notas.dart';
import 'tela_marcar_prova.dart';
import 'tela_cadastro_nfc_manual.dart';
import 'tela_detalhes_disciplina_prof.dart';
import 'tela_historico_chamadas.dart';
import 'tela_editar_turma.dart'; // NOVO
import 'tela_visualizar_alunos.dart'; // NOVO
import '../../providers/provedor_mapas.dart';
import '../../l10n/app_localizations.dart';
import '../comum/animacao_fadein_lista.dart'; 

class AbaTurmasProfessor extends ConsumerWidget {
  const AbaTurmasProfessor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final asyncTurmas = ref.watch(provedorStreamTurmasProfessor);
    final chamadaDiaria = ref.watch(provedorChamadaDiaria);

    return Scaffold(
      body: asyncTurmas.when(
        loading: () => const WidgetCarregamento(),
        error: (err, st) => Center(child: Text('Erro: $err')),
        data: (turmas) {
          if (turmas.isEmpty) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Nenhuma turma criada. Clique no botão + para adicionar sua primeira turma.',
                textAlign: TextAlign.center,
                ),
            ));
          }
          
          final widgets = turmas.map((turma) {
            final bool chamadaIniciada = chamadaDiaria.contains(turma.id);
            return _buildCardTurma(context, ref, t, turma, chamadaIniciada);
          }).toList();

          return FadeInListAnimation(children: widgets);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaCriarTurma()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCardTurma(BuildContext context, WidgetRef ref, AppLocalizations t, TurmaProfessor turma, bool chamadaIniciada) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(turma.nome, style: theme.textTheme.titleLarge)),
                // MENU DE OPÇÕES (EDITAR/ALUNOS)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'editar') {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => TelaEditarTurma(turma: turma)));
                    } else if (value == 'alunos') {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => TelaVisualizarAlunos(turma: turma)));
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'editar',
                      child: ListTile(leading: Icon(Icons.edit), title: Text('Editar Turma'), contentPadding: EdgeInsets.zero),
                    ),
                    const PopupMenuItem<String>(
                      value: 'alunos',
                      child: ListTile(leading: Icon(Icons.people), title: Text('Ver Alunos'), contentPadding: EdgeInsets.zero),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            SelectableText(
              "Código: ${turma.turmaCode}",
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoLinha(
              context,
              icone: Icons.group_outlined,
              texto: '${turma.alunosInscritos.length} ${t.t('prof_turmas_alunos')}',
            ),
            _buildInfoLinha(
              context,
              icone: Icons.schedule_outlined,
              texto: turma.horario,
            ),
            _buildInfoLinha(
              context,
              icone: Icons.location_on_outlined,
              texto: turma.local,
              isLink: true,
              onTap: () async {
                try {
                  await ref.read(provedorMapas).abrirLocalizacao(turma.local);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            ),
            const Divider(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: _buildBotaoAcao(
                    context,
                    label: chamadaIniciada ? t.t('prof_turmas_continuar_nfc') : t.t('prof_turmas_presenca_nfc'),
                    icon: Icons.nfc,
                    onTap: () {
                      ref.read(provedorChamadaDiaria.notifier).iniciarChamada(turma.id);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => TelaPresencaNFC(turma: turma)));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBotaoAcao(
                    context,
                    label: chamadaIniciada ? t.t('prof_turmas_continuar_manual') : t.t('prof_turmas_chamada_manual'),
                    icon: Icons.checklist,
                    onTap: () {
                      ref.read(provedorChamadaDiaria.notifier).iniciarChamada(turma.id);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => TelaChamadaManual(turma: turma)));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildBotaoAcao(
                    context,
                    label: t.t('prof_turmas_lancar_notas'),
                    icon: Icons.assignment_outlined,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => TelaLancarNotas(turma: turma)));
                    },
                    isOutlined: true, 
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBotaoAcao(
                    context,
                    label: t.t('prof_turmas_marcar_prova'),
                    icon: Icons.calendar_month_outlined,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => TelaMarcarProva(turma: turma)));
                    },
                    isOutlined: true, 
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildBotaoAcao(
                    context,
                    label: t.t('hub_chat_materiais') ?? 'Chat e Materiais',
                    icon: Icons.hub_outlined,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => TelaDetalhesDisciplinaProf(turma: turma)));
                    },
                    isOutlined: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBotaoAcao(
                    context,
                    label: t.t('prof_acao_cadastrar_nfc') ?? 'Cadastrar NFC',
                    icon: Icons.person_add_alt_1_outlined,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => TelaCadastroNfcManual(turma: turma)));
                    },
                    isOutlined: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildBotaoAcao(
                    context,
                    label: 'Histórico de Chamadas',
                    icon: Icons.history,
                    onTap: () {
                       Navigator.push(context, MaterialPageRoute(builder: (_) => TelaHistoricoChamadas(turma: turma)));
                    },
                    isOutlined: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoLinha(BuildContext context, {required IconData icone, required String texto, bool isLink = false, VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: isLink ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
      decoration: isLink ? TextDecoration.underline : TextDecoration.none,
    );

    final content = Row(
      children: [
        Icon(icone, size: 16, color: style?.color),
        const SizedBox(width: 8),
        Text(texto, style: style),
      ],
    );

    if (isLink) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: content,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: content,
    );
  }

  Widget _buildBotaoAcao(BuildContext context,
      {required String label, required IconData icon, required VoidCallback onTap, bool isOutlined = false}) {
    
    if (isOutlined) {
      return OutlinedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      );
    }
    
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}