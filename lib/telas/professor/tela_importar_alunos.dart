// lib/telas/professor/tela_importar_alunos.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import '../../services/servico_firestore.dart';
import '../../themes/app_theme.dart';
import '../comum/widget_carregamento.dart';

@UseCase(name: 'Importar Alunos', type: TelaImportarAlunos)
Widget buildTelaImportarAlunos(BuildContext context) {
  return const ProviderScope(child: TelaImportarAlunos(turmaId: 'mock', nomeDisciplina: 'Teste'));
}

class TelaImportarAlunos extends ConsumerStatefulWidget {
  final String turmaId;
  final String nomeDisciplina;

  const TelaImportarAlunos({super.key, required this.turmaId, required this.nomeDisciplina});

  @override
  ConsumerState<TelaImportarAlunos> createState() => _TelaImportarAlunosState();
}

class _TelaImportarAlunosState extends ConsumerState<TelaImportarAlunos> {
  bool _isLoading = false;
  String? _resultado;

  Future<void> _selecionarEImportar() async {
    try {
      // 1. Selecionar Arquivo
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        setState(() => _isLoading = true);
        
        File file = File(result.files.single.path!);

        // 2. Processar Importação
        final stats = await ref.read(servicoFirestoreProvider).importarAlunosCSV(widget.turmaId, file);

        setState(() {
          _isLoading = false;
          _resultado = "${stats['comConta']} alunos vinculados automaticamente.\n${stats['semConta']} alunos pré-cadastrados (sem conta).";
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Importação concluída!"), backgroundColor: Colors.green));
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
      }
    }
  }
  
  Future<void> _baixarModelo() async {
     // Aqui você poderia gerar um CSV de exemplo simples
     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Crie um CSV com colunas: Nome, Email")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Importar Alunos")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.upload_file, size: 80, color: AppColors.primaryPurple),
            const SizedBox(height: 24),
            const Text(
              "Selecione um arquivo .CSV contendo\nNome e E-mail dos alunos.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: _baixarModelo, child: const Text("Como deve ser o arquivo?")),
            const SizedBox(height: 32),
            
            if (_isLoading)
              const WidgetCarregamento(texto: "Processando planilha...")
            else ...[
              ElevatedButton.icon(
                onPressed: _selecionarEImportar,
                icon: const Icon(Icons.folder_open, color: Colors.white),
                label: const Text("Selecionar Arquivo CSV", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              if (_resultado != null) ...[
                 const SizedBox(height: 24),
                 Container(
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                   child: Text(_resultado!, style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                 )
              ]
            ]
          ],
        ),
      ),
    );
  }
}