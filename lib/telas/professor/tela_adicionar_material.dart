// lib/telas/professor/tela_adicionar_material.dart

import 'dart:io'; // Necessário para File
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import 'package:file_picker/file_picker.dart'; // PACOTE NOVO

// Importações internas
import '../../models/material_aula.dart';
import '../../services/servico_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';

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
  
  // Variáveis para Arquivo
  File? _arquivoSelecionado;
  String? _nomeArquivo;

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

  // Verifica se o tipo atual exige upload de arquivo
  bool get _ehTipoArquivo {
    return _tipoSelecionado == TipoMaterial.prova || 
           _tipoSelecionado == TipoMaterial.outro; 
           // Adicione 'slide' aqui se criar esse tipo no Enum futuramente
  }

  // Função para pegar arquivo do celular
  Future<void> _selecionarArquivo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _arquivoSelecionado = File(result.files.single.path!);
        _nomeArquivo = result.files.single.name;
      });
    }
  }

  /// Valida e salva o material no Firestore.
  Future<void> _salvarMaterial() async {
    final t = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;

    // Validação extra para arquivo
    if (_ehTipoArquivo && _arquivoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione um arquivo.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final servico = ref.read(servicoFirestoreProvider);
      final nomeBase = _getNomeBase(widget.nomeDisciplina);
      String urlFinal = '';

      // Lógica de Upload vs Link
      if (_ehTipoArquivo && _arquivoSelecionado != null) {
        // Upload do arquivo para o Storage e pega a URL de download
        // Nota: Certifique-se que seu ServicoFirestore tem o método 'uploadArquivoMaterial'
        // Se não tiver, use o genérico de upload ou crie um.
        urlFinal = await servico.uploadArquivoSolicitacao(_arquivoSelecionado!, 'materiais/${widget.turmaId}');
        // Obs: Acima usei um método existente do seu código anterior, adapte o nome se necessário.
      } else {
        // Usa o texto digitado
        urlFinal = _urlController.text.trim();
      }

      final novoMaterial = MaterialAula(
        id: '', 
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim(),
        url: urlFinal, // URL do Link ou do Arquivo no Storage
        tipo: _tipoSelecionado,
        dataPostagem: DateTime.now(),
        nomeBaseDisciplina: nomeBase, 
      );

      await servico.adicionarMaterial(widget.turmaId, novoMaterial, nomeBase);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.t('materiais_add_sucesso')), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t.t('erro_generico')}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    final inputFill = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.black12;

    InputDecoration inputDecor(String label, {String? hint}) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: inputFill,
        labelStyle: TextStyle(color: textColor?.withOpacity(0.7)),
        hintStyle: TextStyle(color: textColor?.withOpacity(0.5)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primaryPurple)),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.t('materiais_add_titulo'), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
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
              // 1. Tipo (Dropdown) - MOVIDO PARA O TOPO para definir o fluxo
              DropdownButtonFormField<TipoMaterial>(
                value: _tipoSelecionado,
                dropdownColor: inputFill,
                style: TextStyle(color: textColor),
                decoration: inputDecor(t.t('materiais_add_tipo')), 
                items: [
                  DropdownMenuItem(value: TipoMaterial.link, child: Text(t.t('materiais_tipo_link'))),
                  DropdownMenuItem(value: TipoMaterial.video, child: Text(t.t('materiais_tipo_video'))),
                  DropdownMenuItem(value: TipoMaterial.prova, child: Text(t.t('materiais_tipo_prova'))), // Prova Antiga
                  DropdownMenuItem(value: TipoMaterial.outro, child: Text("Slides / PDF")), // Use Outro para Slides
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _tipoSelecionado = v;
                      // Limpa campos ao trocar tipo para evitar confusão
                      _arquivoSelecionado = null;
                      _nomeArquivo = null;
                      _urlController.clear();
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // 2. Título
              TextFormField(
                controller: _tituloController,
                style: TextStyle(color: textColor),
                decoration: inputDecor(t.t('materiais_add_titulo_label')), 
                validator: (v) => (v == null || v.isEmpty) ? t.t('erro_obrigatorio') : null,
              ),
              const SizedBox(height: 16),
              
              // 3. Descrição
              TextFormField(
                controller: _descricaoController,
                style: TextStyle(color: textColor),
                decoration: inputDecor(t.t('materiais_add_desc')), 
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // 4. CAMPO DINÂMICO (URL ou ARQUIVO)
              if (_ehTipoArquivo) ...[
                // --- MODO ARQUIVO ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: inputFill,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.upload_file, size: 40, color: textColor?.withOpacity(0.5)),
                      const SizedBox(height: 8),
                      Text(
                        _nomeArquivo ?? "Nenhum arquivo selecionado",
                        style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _selecionarArquivo,
                        icon: const Icon(Icons.folder_open, size: 18),
                        label: const Text("Selecionar PDF/Imagem"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                          foregroundColor: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // --- MODO LINK/VIDEO ---
                TextFormField(
                  controller: _urlController,
                  style: TextStyle(color: textColor),
                  decoration: inputDecor(t.t('materiais_add_url'), hint: 'https://youtube.com/...'), 
                  keyboardType: TextInputType.url,
                  validator: (v) {
                    if (!_ehTipoArquivo) { // Só valida URL se for tipo Link/Video
                      if (v == null || v.isEmpty) return t.t('erro_obrigatorio');
                      final uri = Uri.tryParse(v);
                      if (uri == null || !uri.isAbsolute) return t.t('materiais_erro_link');
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 32),
              
              // 5. Botão Salvar
              ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save, color: Colors.white),
                label: Text(
                  _isLoading ? t.t('carregando') : t.t('materiais_add_salvar'),
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