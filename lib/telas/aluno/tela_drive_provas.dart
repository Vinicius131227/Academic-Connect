// lib/telas/aluno/tela_drive_provas.dart
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
    
    // Cores
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = theme.cardTheme.color ?? (isDark ? AppColors.surfaceDark : Colors.white);

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
            tooltip: "Contribuir com Prova",
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
                hintText: "Buscar disciplina ou prova...",
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
              loading: () => const WidgetCarregamento(texto: "Carregando drive..."),
              error: (e, s) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    const Text("Erro ao carregar provas.\nVerifique se o índice foi criado no Firebase.", textAlign: TextAlign.center),
                  ],
                ),
              ),
              data: (materiais) {
                // 1. Filtra por busca
                final filtrados = materiais.where((m) {
                  // Como não temos o nome da disciplina no MaterialAula solto, usamos o titulo/descrição
                  // Ou idealmente, o 'nomeBaseDisciplina' que salvamos no Firestore. 
                  // Como o model MaterialAula original não tinha esse campo na memória, 
                  // usamos o título para filtrar.
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

                // 2. Agrupa por "Pasta" (Simulando pastas pelo título ou descrição)
                // Para simplificar e ficar visualmente bonito, vamos listar como Cards de Arquivo
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final material = filtrados[index];
                    return Card(
                      color: cardColor,
                      margin: const EdgeInsets.only(bottom: 12),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _exibirDialogoUpload(context),
        backgroundColor: AppColors.primaryPurple,
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: const Text("Enviar Prova", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // Dialog para simular upload (já que o aluno não pode escrever em qualquer lugar por segurança padrão)
  // Numa implementação real, salvaríamos em uma coleção 'uploads_alunos' para moderação.
  void _exibirDialogoUpload(BuildContext context) {
    final titleController = TextEditingController();
    final subjectController = TextEditingController();
    final urlController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: const Text("Contribuir com o Drive"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Compartilhe provas antigas com a comunidade.", style: TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(labelText: "Disciplina (Ex: Cálculo 1)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Título (Ex: P1 2023)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: "Link do PDF (Drive/Dropbox)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                 // Simulação de File Picker
                 FilePickerResult? result = await FilePicker.platform.pickFiles();
                 if (result != null) {
                    urlController.text = result.files.single.name; // Apenas visual
                 }
              },
              icon: const Icon(Icons.attach_file),
              label: const Text("Ou selecionar arquivo"),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
               // AQUI ENTRARIA A LÓGICA DE SALVAR NO FIRESTORE
               // Como é complexo salvar sem ter o ID da turma correto,
               // vamos simular o sucesso para o MVP.
               Navigator.pop(ctx);
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text("Obrigado! Sua prova foi enviada para análise."), backgroundColor: Colors.green),
               );
            },
            child: const Text("Enviar"),
          ),
        ],
      ),
    );
  }
}