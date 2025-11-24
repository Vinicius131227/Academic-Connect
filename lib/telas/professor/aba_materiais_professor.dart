// lib/telas/professor/aba_materiais_professor.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/turma_professor.dart';
import '../../models/material_aula.dart';
import '../../l10n/app_localizations.dart';
import '../../services/servico_firestore.dart';
import '../comum/widget_carregamento.dart';
import 'tela_adicionar_material.dart';
import '../comum/tela_webview.dart'; // Importe a WebView
import 'package:intl/intl.dart'; 

class AbaMateriaisProfessor extends ConsumerWidget {
  final TurmaProfessor turma;
  const AbaMateriaisProfessor({super.key, required this.turma});

  IconData _getIconForType(TipoMaterial tipo) {
    switch (tipo) {
      case TipoMaterial.link:
        return Icons.link;
      case TipoMaterial.video:
        return Icons.videocam_outlined;
      case TipoMaterial.prova:
        return Icons.description_outlined;
      case TipoMaterial.outro:
        return Icons.attachment;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final streamMateriais = ref.watch(streamMateriaisProvider(turma.id));
    final theme = Theme.of(context);

    return Scaffold(
      body: streamMateriais.when(
        loading: () => const WidgetCarregamento(),
        error: (err, st) => Center(child: Text('Erro ao carregar materiais: $err')),
        data: (materiais) {
          if (materiais.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      t.t('materiais_vazio_prof'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: materiais.length,
            itemBuilder: (context, index) {
              final material = materiais[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Icon(_getIconForType(material.tipo), color: theme.colorScheme.primary),
                  ),
                  title: Text(material.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (material.descricao.isNotEmpty)
                        Text(material.descricao, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(material.dataPostagem),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.open_in_new),
                        tooltip: 'Abrir Link',
                        onPressed: () {
                            // Abre dentro do app
                            Navigator.push(context, MaterialPageRoute(builder: (_) => TelaWebView(url: material.url, titulo: material.titulo)));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Remover',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirmar Exclusão'),
                              content: Text('Deseja realmente remover "${material.titulo}"?'),
                              actions: [
                                TextButton(
                                  child: Text(t.t('config_sair_dialog_cancelar')),
                                  onPressed: () => Navigator.pop(ctx),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () {
                                    ref.read(servicoFirestoreProvider).removerMaterial(turma.id, material.id);
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('Remover'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => TelaWebView(url: material.url, titulo: material.titulo)));
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TelaAdicionarMaterial(
                turmaId: turma.id, 
                nomeDisciplina: turma.nome
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(t.t('materiais_add_titulo')),
      ),
    );
  }
}