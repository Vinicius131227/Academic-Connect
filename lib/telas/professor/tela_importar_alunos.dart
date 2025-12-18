// lib/telas/professor/tela_importar_alunos.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import '../../services/servico_firestore.dart';
import '../../themes/app_theme.dart';
import '../comum/widget_carregamento.dart';
import '../../l10n/app_localizations.dart';

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
    final t = AppLocalizations.of(context)!;
    
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
          // Constrói a mensagem traduzida com os números
          _resultado = "${stats['comConta']} ${t.t('importar_res_vinculados')}\n${stats['semConta']} ${t.t('importar_res_pendentes')}";
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.t('sucesso')), backgroundColor: Colors.green)
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${t.t('erro_generico')}: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }
  
  Future<void> _baixarModelo() async {
      final t = AppLocalizations.of(context)!;
      // Exibe dica de como deve ser o arquivo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.t('importar_dica_csv')))
      );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('importar_titulo')), // "Importar Alunos"
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.upload_file, size: 80, color: AppColors.primaryPurple),
            const SizedBox(height: 24),
            Text(
              t.t('importar_instrucao'), // "Selecione um arquivo .CSV..."
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _baixarModelo, 
              child: Text(t.t('importar_ajuda')) // "Como deve ser o arquivo?"
            ),
            const SizedBox(height: 32),
            
            if (_isLoading)
              WidgetCarregamento(texto: t.t('importar_processando')) // "Processando planilha..."
            else ...[
              ElevatedButton.icon(
                onPressed: _selecionarEImportar,
                icon: const Icon(Icons.folder_open, color: Colors.white),
                label: Text(t.t('importar_btn_selecionar'), style: const TextStyle(color: Colors.white)), // "Selecionar Arquivo CSV"
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