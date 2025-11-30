// lib/telas/professor/tela_adicionar_material.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../models/material_aula.dart';
import '../../services/servico_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';

/// Caso de uso para o Widgetbook.
/// Simula a tela de adição de material.
@UseCase(
  name: 'Adicionar Material',
  type: TelaAdicionarMaterial,
)
Widget buildTelaAdicionarMaterial(BuildContext context) {
  return const ProviderScope(
    child: TelaAdicionarMaterial(
      turmaId: 'mock_id',
      nomeDisciplina: 'Cálculo 1',
    ),
  );
}

/// Tela de formulário para o professor adicionar materiais de estudo.
///
/// Campos:
/// - Título
/// - Descrição
/// - URL (Link/Vídeo)
/// - Tipo (Link, Vídeo, Prova, Outro)
class TelaAdicionarMaterial extends ConsumerStatefulWidget {
  final String turmaId;
  final String nomeDisciplina; // Necessário para indexação global de provas antigas
  
  const TelaAdicionarMaterial({
    super.key, 
    required this.turmaId, 
    required this.nomeDisciplina
  });

  @override
  ConsumerState<TelaAdicionarMaterial> createState() => _TelaAdicionarMaterialState();
}

class _TelaAdicionarMaterialState extends ConsumerState<TelaAdicionarMaterial> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _urlController = TextEditingController();
  
  // Estado
  TipoMaterial _tipoSelecionado = TipoMaterial.link;
  bool _isLoading = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _urlController.dispose();
    super.dispose();
  }
  
  /// Helper para normalizar o nome da disciplina (Ex: "Cálculo 1" -> "Cálculo").
  /// Isso ajuda a agrupar provas antigas de diferentes anos/turmas.
  String _getNomeBase(String nome) {
    // Remove números soltos no final se necessário, ou usa o nome completo.
    // Para este exemplo, usamos o nome completo limpo.
    return nome.trim();
  }

  /// Valida e salva o material no Firestore.
  Future<void> _salvarMaterial() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    final t = AppLocalizations.of(context)!;
    
    // Gera o nome base para indexação
    final nomeBase = _getNomeBase(widget.nomeDisciplina);

    final novoMaterial = MaterialAula(
      id: '', // Firestore gera o ID
      titulo: _tituloController.text.trim(),
      descricao: _descricaoController.text.trim(),
      url: _urlController.text.trim(),
      tipo: _tipoSelecionado,
      dataPostagem: DateTime.now(),
      nomeBaseDisciplina: nomeBase, 
    );

    try {
      // Chama o serviço
      await ref.read(servicoFirestoreProvider).adicionarMaterial(
        widget.turmaId, 
        novoMaterial, 
        nomeBase
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.t('materiais_add_sucesso')), // "Material salvo!"
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Fecha a tela
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t.t('erro_generico')}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    
    // Configuração de Tema
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    final inputFill = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.black12;

    // Estilo dos inputs
    InputDecoration inputDecor(String label, {String? hint}) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16), 
            borderSide: BorderSide(color: borderColor)
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          t.t('materiais_add_titulo'), // "Adicionar Material"
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Título
              TextFormField(
                controller: _tituloController,
                style: TextStyle(color: textColor),
                decoration: inputDecor(t.t('materiais_add_titulo_label')), // "Título"
                validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              
              // 2. Descrição
              TextFormField(
                controller: _descricaoController,
                style: TextStyle(color: textColor),
                decoration: inputDecor(t.t('materiais_add_desc')), // "Descrição"
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // 3. URL
              TextFormField(
                controller: _urlController,
                style: TextStyle(color: textColor),
                decoration: inputDecor(t.t('materiais_add_url'), hint: 'https://...'), // "Link (URL)"
                keyboardType: TextInputType.url,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obrigatório';
                  final uri = Uri.tryParse(v);
                  if (uri == null || !uri.isAbsolute) {
                    return 'Insira um link válido (ex: https://...)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // 4. Tipo (Dropdown)
              DropdownButtonFormField<TipoMaterial>(
                value: _tipoSelecionado,
                dropdownColor: inputFill,
                style: TextStyle(color: textColor),
                decoration: inputDecor(t.t('materiais_add_tipo')), // "Tipo"
                items: [
                  DropdownMenuItem(
                    value: TipoMaterial.link,
                    child: Text(t.t('materiais_tipo_link')),
                  ),
                  DropdownMenuItem(
                    value: TipoMaterial.video,
                    child: Text(t.t('materiais_tipo_video')),
                  ),
                  DropdownMenuItem(
                    value: TipoMaterial.prova,
                    child: Text(t.t('materiais_tipo_prova')),
                  ),
                  DropdownMenuItem(
                    value: TipoMaterial.outro,
                    child: Text(t.t('materiais_tipo_outro')),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _tipoSelecionado = v);
                },
              ),
              
              const SizedBox(height: 32),
              
              // 5. Botão Salvar
              ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save, color: Colors.white),
                label: Text(
                  _isLoading ? t.t('carregando') : t.t('materiais_add_salvar'), // "Salvar Material"
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                ),
                onPressed: _isLoading ? null : _salvarMaterial,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}