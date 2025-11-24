// lib/telas/professor/tela_adicionar_material.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/material_aula.dart';
import '../../services/servico_firestore.dart';
import '../../l10n/app_localizations.dart';

class TelaAdicionarMaterial extends ConsumerStatefulWidget {
  final String turmaId;
  final String nomeDisciplina; // Passado para o salvamento de nome base
  const TelaAdicionarMaterial({super.key, required this.turmaId, required this.nomeDisciplina});

  @override
  ConsumerState<TelaAdicionarMaterial> createState() =>
      _TelaAdicionarMaterialState();
}

class _TelaAdicionarMaterialState extends ConsumerState<TelaAdicionarMaterial> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _urlController = TextEditingController();
  TipoMaterial _tipoSelecionado = TipoMaterial.link;
  bool _isLoading = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _urlController.dispose();
    super.dispose();
  }
  
  // Helper para simplificar o nome da disciplina (Ex: "Cálculo 1" -> "Cálculo")
  String _getNomeBase(String nome) {
    // Remove números no final (se existirem)
    final nomeBase = nome.replaceAll(RegExp(r'\s*\d+$'), '');
    return nomeBase.trim();
  }

  Future<void> _salvarMaterial() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    final t = AppLocalizations.of(context)!;
    final nomeBase = _getNomeBase(widget.nomeDisciplina);

    final novoMaterial = MaterialAula(
      id: '', // Firestore vai gerar
      titulo: _tituloController.text.trim(),
      descricao: _descricaoController.text.trim(),
      url: _urlController.text.trim(),
      tipo: _tipoSelecionado,
      dataPostagem: DateTime.now(),
    );

    try {
      // Salva, incluindo o nome base da disciplina (para busca de provas anteriores)
      await ref.read(servicoFirestoreProvider).adicionarMaterial(widget.turmaId, novoMaterial, nomeBase);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.t('materiais_add_sucesso')),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('materiais_add_titulo')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Form(
          key: _formKey,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _tituloController,
                    decoration: InputDecoration(
                      labelText: t.t('materiais_add_titulo_label'),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descricaoController,
                    decoration: InputDecoration(
                      labelText: t.t('materiais_add_desc'),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: t.t('materiais_add_url'),
                      hintText: 'https://...',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Campo obrigatório';
                      
                      // --- CORREÇÃO DO ERRO DE URI ---
                      final uri = Uri.tryParse(v);
                      // Verifica se uri não é nulo E se é absoluto (tem http/https)
                      if (uri == null || !uri.isAbsolute) {
                        return 'Insira um link válido (ex: https://...)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TipoMaterial>(
                    value: _tipoSelecionado,
                    decoration: InputDecoration(
                      labelText: t.t('materiais_add_tipo'),
                      border: const OutlineInputBorder(),
                    ),
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
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: _isLoading
                        ? Container(width: 20, height: 20, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save),
                    label: Text(_isLoading ? 'Salvando...' : t.t('materiais_add_salvar')),
                    onPressed: _isLoading ? null : _salvarMaterial,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}