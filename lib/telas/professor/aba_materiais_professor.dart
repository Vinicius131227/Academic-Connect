// lib/telas/professor/aba_materiais_professor.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/turma_professor.dart';
import '../../models/material_aula.dart';
import '../../providers/provedores_app.dart';
import '../../services/servico_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../comum/widget_carregamento.dart';
import '../comum/tela_webview.dart';
import 'tela_adicionar_material.dart';
import '../../themes/app_theme.dart';

/// Caso de uso para o Widgetbook.
@UseCase(
  name: 'Materiais (Professor)',
  type: AbaMateriaisProfessor,
)
Widget buildAbaMateriaisProfessor(BuildContext context) {
  return ProviderScope(
    child: Scaffold(
      body: AbaMateriaisProfessor(
        turma: TurmaProfessor(
          id: 'mock', 
          nome: 'Cálculo 1', 
          horario: '', 
          local: '', 
          professorId: '', 
          turmaCode: '', 
          creditos: 4, 
          alunosInscritos: []
        ),
      ),
    ),
  );
}

/// Aba que lista os materiais postados pelo professor e permite adicionar novos.
class AbaMateriaisProfessor extends ConsumerWidget {
  final TurmaProfessor turma;
  
  const AbaMateriaisProfessor({
    super.key, 
    required this.turma
  });

  /// Retorna o ícone adequado ao tipo de material.
  IconData _getIconForType(TipoMaterial tipo) {
    switch (tipo) {
      case TipoMaterial.link: return Icons.link;
      case TipoMaterial.video: return Icons.play_circle_fill;
      case TipoMaterial.prova: return Icons.assignment;
      case TipoMaterial.outro: return Icons.attach_file;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    
    // Stream de materiais da turma
    final streamMateriais = ref.watch(streamMateriaisProvider(turma.id));
    
    // Configuração de Tema
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.black12;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      
      // Corpo com lista de materiais
      body: streamMateriais.when(
        loading: () => const WidgetCarregamento(texto: "Carregando materiais..."),
        error: (e, s) => Center(child: Text('${t.t('erro_generico')}: $e', style: TextStyle(color: textColor))),
        data: (materiais) {
          // Lista vazia
          if (materiais.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    t.t('materiais_vazio'), // "Nenhum material postado"
                    style: TextStyle(color: textColor?.withOpacity(0.7))
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.t('materiais_ajuda_add'),
                    style: TextStyle(color: textColor?.withOpacity(0.5), fontSize: 12),
                  )
                ],
              ),
            );
          }

          // Lista de Cards
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: materiais.length,
            itemBuilder: (context, index) {
              final material = materiais[index];
              
              // Cartão do Material com Dismissible para Excluir
              return Dismissible(
                key: Key(material.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                   // Exclui do banco
                   ref.read(servicoFirestoreProvider).removerMaterial(turma.id, material.id);
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text(t.t('materiais_removido')))
                   );
                },
                child: Card(
                  color: cardColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: borderColor)
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    // Ícone do tipo
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_getIconForType(material.tipo), color: AppColors.primaryPurple),
                    ),
                    // Título e Data
                    title: Text(material.titulo, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (material.descricao.isNotEmpty)
                          Text(material.descricao, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: textColor?.withOpacity(0.7))),
                        Text(
                          DateFormat('dd/MM/yyyy').format(material.dataPostagem),
                          style: TextStyle(fontSize: 11, color: textColor?.withOpacity(0.5))
                        ),
                      ],
                    ),
                    trailing: Icon(Icons.open_in_new, color: textColor?.withOpacity(0.3), size: 18),
                    // Ação de clique (Abrir)
                    onTap: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => TelaWebView(url: material.url, titulo: material.titulo))
                        );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      
      // Botão Flutuante para Adicionar Material
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TelaAdicionarMaterial(turmaId: turma.id, nomeDisciplina: turma.nome)),
          );
        },
        backgroundColor: AppColors.primaryPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}