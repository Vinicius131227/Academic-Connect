// lib/telas/professor/tela_historico_chamadas.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../models/turma_professor.dart';
import '../../services/servico_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';
import '../comum/widget_carregamento.dart';

/// Caso de uso para o Widgetbook.
@UseCase(
  name: 'Histórico de Chamadas',
  type: TelaHistoricoChamadas,
)
Widget buildTelaHistoricoChamadas(BuildContext context) {
  return ProviderScope(
    child: TelaHistoricoChamadas(
      turma: TurmaProfessor(
        id: 'mock', nome: 'Mock', horario: '', local: '', 
        professorId: '', turmaCode: '', creditos: 4, alunosInscritos: []
      )
    ),
  );
}

/// Provedor que carrega a lista de datas (IDs dos documentos) de chamadas da turma.
final historicoDatasProvider = StreamProvider.family<List<String>, String>((ref, turmaId) {
  return ref.watch(servicoFirestoreProvider).getDatasChamadas(turmaId);
});

/// Tela que lista o histórico de chamadas realizadas.
/// Ao clicar em uma data, exibe um modal com os detalhes.
class TelaHistoricoChamadas extends ConsumerWidget {
  final TurmaProfessor turma;
  const TelaHistoricoChamadas({super.key, required this.turma});

  /// Abre um diálogo com os detalhes da chamada daquele dia.
  void _mostrarDetalhesChamada(BuildContext context, WidgetRef ref, String dataId) async {
    final t = AppLocalizations.of(context)!;
    
    // Carrega dados sob demanda
    final dados = await ref.read(servicoFirestoreProvider).getDadosChamada(turma.id, dataId);
    
    final inicio = List.from(dados['presentes_inicio'] ?? []).length;
    final fim = List.from(dados['presentes_fim'] ?? []).length;
    
    // Formata a data para exibição
    DateTime data;
    try {
       data = DateFormat('yyyy-MM-dd').parse(dataId);
    } catch (e) {
       data = DateTime.now();
    }
    final dataFormatada = DateFormat('dd/MM/yyyy').format(data);

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            title: Text("${t.t('prof_presenca')} - $dataFormatada"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(t.t('prof_chamada_tipo_inicio'), "$inicio ${t.t('prof_presenca_presentes')}"),
                const SizedBox(height: 8),
                _buildDetailRow(t.t('prof_chamada_tipo_fim'), "$fim ${t.t('prof_presenca_presentes')}"),
                const Divider(height: 24),
                Text(
                  "Total inscritos na turma: ${turma.alunosInscritos.length}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                )
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx), 
                child: Text(t.t('fechar').toUpperCase())
              )
            ],
          );
        }
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final asyncDatas = ref.watch(historicoDatasProvider(turma.id));
    
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          t.t('prof_historico'), 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: asyncDatas.when(
        loading: () => const WidgetCarregamento(),
        error: (e, s) => Center(child: Text("${t.t('erro_generico')}: $e")),
        data: (datas) {
          if (datas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text("Nenhuma chamada registrada.", style: TextStyle(color: textColor?.withOpacity(0.7))),
                ],
              ),
            );
          }
          
          // Ordena datas (mais recentes primeiro)
          datas.sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: datas.length,
            itemBuilder: (context, index) {
              final dataString = datas[index];
              // Formata para pt-BR
              String labelData = dataString;
              try {
                final dt = DateFormat('yyyy-MM-dd').parse(dataString);
                labelData = DateFormat('dd ' 'MMMM' ' yyyy', 'pt_BR').format(dt);
              } catch (_) {}

              return Card(
                color: cardColor,
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.calendar_today, color: AppColors.primaryPurple),
                  ),
                  title: Text(labelData.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () => _mostrarDetalhesChamada(context, ref, dataString),
                ),
              );
            },
          );
        },
      ),
    );
  }
}