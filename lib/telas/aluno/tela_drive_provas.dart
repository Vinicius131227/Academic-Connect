// lib/telas/aluno/tela_drive_provas.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Formatação de data
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../models/material_aula.dart';
import '../../services/servico_firestore.dart';
import '../../themes/app_theme.dart'; // Cores
import '../comum/widget_carregamento.dart'; // Loading
import '../comum/tela_webview.dart'; // Visualizador de PDF/Link

/// Caso de uso para o Widgetbook.
/// Simula a tela de Drive de Provas.
@UseCase(
  name: 'Drive de Provas',
  type: TelaDriveProvas,
)
Widget buildTelaDriveProvas(BuildContext context) {
  return const ProviderScope(
    child: TelaDriveProvas(),
  );
}

/// Provedor que busca TODAS as provas do sistema (Query Global).
/// Usa 'collectionGroup' do Firestore para buscar em subcoleções.
final driveProvasProvider = StreamProvider<List<MaterialAula>>((ref) {
  return ref.watch(servicoFirestoreProvider).getTodosMateriaisTipoProva();
});

/// Tela que exibe o banco de provas antigas compartilhadas.
/// 
/// Funcionalidades:
/// - Listagem de provas de todas as disciplinas.
/// - Busca por nome ou descrição.
/// - Visualização do arquivo (PDF/Link).
/// - Botão de contribuição (Upload).
class TelaDriveProvas extends ConsumerStatefulWidget {
  const TelaDriveProvas({super.key});

  @override
  ConsumerState<TelaDriveProvas> createState() => _TelaDriveProvasState();
}

class _TelaDriveProvasState extends ConsumerState<TelaDriveProvas> {
  final _buscaController = TextEditingController();
  String _termoBusca = ''; // Termo digitado na busca

  @override
  Widget build(BuildContext context) {
    // Observa o stream de provas
    final asyncProvas = ref.watch(driveProvasProvider);
    
    // Configurações de Tema
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.black12;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Drive de Provas", 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          // Botão de Upload (Contribuição)
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            onPressed: () => _exibirDialogoUpload(context),
            tooltip: "Contribuir com Prova",
          )
        ],
      ),
      body: Column(
        children: [
          // 1. BARRA DE BUSCA
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _buscaController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: "Buscar disciplina ou ano...",
                hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                prefixIcon: Icon(Icons.search, color: textColor.withOpacity(0.5)),
                filled: true,
                fillColor: cardColor,
                // Bordas arredondadas
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryPurple)),
              ),
              onChanged: (v) => setState(() => _termoBusca = v.toLowerCase()),
            ),
          ),

          // 2. LISTA DE PROVAS
          Expanded(
            child: asyncProvas.when(
              loading: () => const WidgetCarregamento(texto: "Carregando provas..."),
              
              // Tratamento de Erro (Principalmente Índice do Firebase)
              error: (e, s) {
                 debugPrint("ERRO NO FIREBASE (DRIVE): $e");
                 
                 return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 48, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(
                          "Configuração Necessária", 
                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "O índice de pesquisa global ainda não foi criado no banco de dados.\nVerifique o console para o link de criação.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textColor.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ),
                );
              },
              
              // Dados Carregados
              data: (materiais) {
                // Filtra localmente pelo termo de busca
                final filtrados = materiais.where((m) {
                  return m.titulo.toLowerCase().contains(_termoBusca) || 
                         m.descricao.toLowerCase().contains(_termoBusca);
                }).toList();

                if (filtrados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_off, size: 64, color: Colors.grey.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text("Nenhuma prova encontrada.", style: TextStyle(color: textColor.withOpacity(0.7))),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final material = filtrados[index];
                    
                    // Cartão de Arquivo
                    return Card(
                      color: cardColor,
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2, // Sombra suave
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: borderColor)
                      ),
                      child: ListTile(
                        // Ícone Laranja para destacar que é Prova
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.description, color: Colors.orange),
                        ),
                        
                        title: Text(
                          material.titulo, 
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)
                        ),
                        
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (material.descricao.isNotEmpty)
                              Text(
                                material.descricao, 
                                style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12)
                              ),
                            const SizedBox(height: 4),
                            
                            // Data de Postagem
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 12, color: textColor.withOpacity(0.5)),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('dd/MM/yyyy').format(material.dataPostagem),
                                  style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 11),
                                ),
                              ],
                            )
                          ],
                        ),
                        
                        trailing: Icon(Icons.download_rounded, color: textColor.withOpacity(0.5)),
                        
                        // Ação ao clicar: Abrir WebView
                        onTap: () {
                           Navigator.push(
                             context, 
                             MaterialPageRoute(builder: (_) => TelaWebView(url: material.url, titulo: material.titulo))
                           );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Exibe um diálogo simulando o upload de arquivos (Feature futura).
  void _exibirDialogoUpload(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogColor = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = theme.textTheme.bodyLarge?.color;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogColor,
        title: Text("Enviar Prova", style: TextStyle(color: textColor)),
        content: Text(
          "O upload de arquivos será liberado em breve pela moderação do C.A.\nObrigado pelo interesse em contribuir!", 
          style: TextStyle(color: textColor?.withOpacity(0.8))
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("OK")
          ),
        ],
      ),
    );
  }
}