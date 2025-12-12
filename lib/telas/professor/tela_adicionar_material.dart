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
class TelaAdicionarMaterial extends ConsumerStatefulWidget {
  final String turmaId;
  final String nomeDisciplina; 
  
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
  
  String _getNomeBase(String nome) {
    return nome.trim();
  }

  /// Valida e salva o material no Firestore.
  Future<void> _salvarMaterial() async {
    final t = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    
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
            content: Text(t.t('materiais_add_sucesso')), // TRADUZIDO: "Material salvo!"
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
        labelStyle: TextStyle(color: textColor?.withOpacity(0.7)),
        hintStyle: TextStyle(color: textColor?.withOpacity(0.5)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16), 
            borderSide: BorderSide(color: borderColor)
        ),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16), 
            borderSide: const BorderSide(color: AppColors.primaryPurple)
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        // TRADUZIDO: "Adicionar Material"
        title: Text(
          t.t('materiais_add_titulo'), 
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
                // TRADUZIDO: "Título"
                decoration: inputDecor(t.t('materiais_add_titulo_label')), 
                validator: (v) => (v == null || v.isEmpty) ? t.t('erro_obrigatorio') : null,
              ),
              const SizedBox(height: 16),
              
              // 2. Descrição
              TextFormField(
                controller: _descricaoController,
                style: TextStyle(color: textColor),
                // TRADUZIDO: "Descrição"
                decoration: inputDecor(t.t('materiais_add_desc')), 
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // 3. URL
              TextFormField(
                controller: _urlController,
                style: TextStyle(color: textColor),
                // TRADUZIDO: "Link (URL)"
                decoration: inputDecor(t.t('materiais_add_url'), hint: 'https://...'), 
                keyboardType: TextInputType.url,
                validator: (v) {
                  if (v == null || v.isEmpty) return t.t('erro_obrigatorio');
                  final uri = Uri.tryParse(v);
                  if (uri == null || !uri.isAbsolute) {
                    // TRADUZIDO: "Insira um link válido..."
                    return t.t('materiais_erro_link');
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
                // TRADUZIDO: "Tipo"
                decoration: inputDecor(t.t('materiais_add_tipo')), 
                // Itens traduzidos
                items: [
                  DropdownMenuItem(
                    value: TipoMaterial.link,
                    child: Text(t.t('materiais_tipo_link')), // "Link" / "Enlace"
                  ),
                  DropdownMenuItem(
                    value: TipoMaterial.video,
                    child: Text(t.t('materiais_tipo_video')), // "Vídeo"
                  ),
                  DropdownMenuItem(
                    value: TipoMaterial.prova,
                    child: Text(t.t('materiais_tipo_prova')), // "Prova Antiga" / "Examen Antiguo"
                  ),
                  DropdownMenuItem(
                    value: TipoMaterial.outro,
                    child: Text(t.t('materiais_tipo_outro')), // "Outro" / "Otro"
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
                  _isLoading ? t.t('carregando') : t.t('materiais_add_salvar'), // TRADUZIDO: "Salvar Material"
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