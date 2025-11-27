import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../../models/material_aula.dart';
import '../../services/servico_firestore.dart';
import '../../themes/app_theme.dart';
import '../comum/widget_carregamento.dart';
import '../comum/tela_webview.dart';

// Provedor para buscar TODAS as provas do sistema
final driveProvasProvider = StreamProvider<List<MaterialAula>>((ref) {
  return ref.watch(servicoFirestoreProvider).getTodosMateriaisTipoProva();
});

class TelaDriveProvas extends ConsumerStatefulWidget {
  const TelaDriveProvas({super.key});

  @override
  ConsumerState<TelaDriveProvas> createState() => _TelaDriveProvasState();
}

class _TelaDriveProvasState extends ConsumerState<TelaDriveProvas> {
  final _buscaController = TextEditingController();
  String _termoBusca = '';

  @override
  Widget build(BuildContext context) {
    final asyncProvas = ref.watch(driveProvasProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;

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
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            onPressed: () => _exibirDialogoUpload(context),
            tooltip: "Contribuir",
          )
        ],
      ),
      body: Column(
        children: [
          // Barra de Busca
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _buscaController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: "Buscar disciplina ou ano...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _termoBusca = v.toLowerCase()),
            ),
          ),

          // Lista
          Expanded(
            child: asyncProvas.when(
              loading: () => const WidgetCarregamento(texto: "Carregando provas..."),
              error: (e, s) {
                 // Log do erro para você clicar no link do terminal
                 debugPrint("ERRO NO FIREBASE (DRIVE): $e");
                 
                 return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 48, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(
                          "Índice necessário", 
                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold)
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Olhe o terminal (debug console) e clique no link para criar o índice no Firebase.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
              data: (materiais) {
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
                    return Card(
                      color: cardColor,
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      child: ListTile(
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
                              Text(material.descricao, style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12)),
                            const SizedBox(height: 4),
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

  void _exibirDialogoUpload(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: const Text("Enviar Prova"),
        content: const Text("O upload de arquivos será liberado em breve pelo C.A."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
        ],
      ),
    );
  }
}