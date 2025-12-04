// lib/telas/aluno/tela_drive_provas.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart'; // Adicione no pubspec.yaml se não tiver
import 'dart:typed_data';

import '../../models/material_aula.dart';
import '../../services/servico_firestore.dart';
import '../../themes/app_theme.dart';
import '../comum/widget_carregamento.dart';
import '../comum/tela_webview.dart';

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

  // Simulação de upload
  String? _nomeArquivoUpload;
  Uint8List? _bytesArquivoUpload;

  Future<void> _selecionarArquivo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png'],
        withData: true,
      );

      if (result != null) {
        setState(() {
          _nomeArquivoUpload = result.files.single.name;
          _bytesArquivoUpload = result.files.single.bytes;
        });
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Arquivo selecionado! (Simulação)"), backgroundColor: Colors.green)
           );
           Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint("Erro ao selecionar: $e");
    }
  }

  void _exibirDialogoUpload(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Contribuir com Prova"),
        content: const Text("O upload será liberado em breve."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("OK")
          ),
        ],
      ),
    );
  }

  // Função para extrair o link do erro e abrir
  Future<void> _abrirLinkIndice(String erro) async {
    final regex = RegExp(r'(https://console\.firebase\.google\.com[^\s]+)');
    final match = regex.firstMatch(erro);
    if (match != null) {
      final url = Uri.parse(match.group(0)!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    }
  }

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
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _buscaController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: "Buscar disciplina...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => _termoBusca = v.toLowerCase()),
            ),
          ),

          Expanded(
            child: asyncProvas.when(
              loading: () => const WidgetCarregamento(texto: "Carregando..."),
              
              // TRATAMENTO DE ERRO MELHORADO
              error: (e, s) {
                 final erroString = e.toString();
                 final ehErroIndice = erroString.contains("failed-precondition") || erroString.contains("index");
                 
                 return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.build, size: 48, color: Colors.orange),
                        const SizedBox(height: 16),
                        Text(
                          ehErroIndice ? "Índice do Firebase Necessário" : "Erro ao carregar", 
                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        if (ehErroIndice) ...[
                          const Text("Clique no botão abaixo para criar o índice automaticamente no console do Firebase.", textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _abrirLinkIndice(erroString),
                            child: const Text("CRIAR ÍNDICE AGORA"),
                          ),
                        ] else
                          Text(erroString, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              },
              
              data: (materiais) {
                final filtrados = materiais.where((m) => m.titulo.toLowerCase().contains(_termoBusca)).toList();

                if (filtrados.isEmpty) {
                  return const Center(child: Text("Nenhuma prova encontrada."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final material = filtrados[index];
                    return Card(
                      color: cardColor,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.description, color: Colors.orange),
                        title: Text(material.titulo, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                        subtitle: Text(DateFormat('dd/MM/yyyy').format(material.dataPostagem)),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaWebView(url: material.url, titulo: material.titulo))),
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
}