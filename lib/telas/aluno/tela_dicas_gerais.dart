// lib/telas/aluno/tela_dicas_gerais.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; 

import '../../models/dica_aluno.dart';
import '../../services/servico_firestore.dart';
import '../../l10n/app_localizations.dart'; 
import '../../themes/app_theme.dart';
import '../comum/widget_carregamento.dart';
import '../../providers/provedor_autenticacao.dart';

// Provider que busca as dicas globais
final dicasGeraisProvider = StreamProvider<List<DicaAluno>>((ref) {
  return ref.watch(servicoFirestoreProvider).getTodasDicasGlobais();
});

// Provider de estado local para o texto da busca
final filtroDicasProvider = StateProvider<String>((ref) => '');

class TelaDicasGerais extends ConsumerStatefulWidget {
  const TelaDicasGerais({super.key});

  @override
  ConsumerState<TelaDicasGerais> createState() => _TelaDicasGeraisState();
}

class _TelaDicasGeraisState extends ConsumerState<TelaDicasGerais> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _abrirLinkIndice(String erro) async {
    final regex = RegExp(r'(https://console\.firebase\.google\.com[^\s]+)');
    final match = regex.firstMatch(erro);
    if (match != null) {
      final url = Uri.parse(match.group(0)!);
      if (await canLaunchUrl(url)) await launchUrl(url);
    }
  }

  void _mostrarModalAdicionar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _FormularioNovaDica(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final asyncDicas = ref.watch(dicasGeraisProvider);
    final filtro = ref.watch(filtroDicasProvider).toLowerCase();
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final searchFill = isDark ? Colors.grey[800] : Colors.grey[200];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          t.t('dicas_titulo'), 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarModalAdicionar(context),
        backgroundColor: AppColors.primaryPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: Column(
        children: [
          // Barra de Pesquisa
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => ref.read(filtroDicasProvider.notifier).state = val,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: t.t('dicas_buscar_hint'),
                hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                prefixIcon: Icon(Icons.search, color: textColor.withOpacity(0.5)),
                filled: true,
                fillColor: searchFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              ),
            ),
          ),

          // Lista
          Expanded(
            child: asyncDicas.when(
              loading: () => const WidgetCarregamento(texto: "Buscando dicas..."),
              error: (error, stack) {
                final erroString = error.toString();
                final ehErroIndice = erroString.contains("failed-precondition") || erroString.contains("index");
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.build_circle, size: 48, color: Colors.orange),
                        const SizedBox(height: 16),
                        Text("Configuração Pendente", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                        if (ehErroIndice) ...[
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => _abrirLinkIndice(erroString),
                              child: const Text("CRIAR ÍNDICE AGORA"),
                            ),
                        ] else 
                            Text(erroString),
                      ],
                    ),
                  ),
                );
              },
              data: (dicas) {
                final dicasFiltradas = dicas.where((d) {
                  final texto = d.texto.toLowerCase();
                  final materia = d.materia.toLowerCase(); 
                  return texto.contains(filtro) || materia.contains(filtro);
                }).toList();

                if (dicasFiltradas.isEmpty) {
                   return Center(
                     child: Text(filtro.isEmpty ? "Nenhuma dica ainda." : "Nenhum resultado.", style: TextStyle(color: textColor.withOpacity(0.6))),
                   );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: dicasFiltradas.length,
                  itemBuilder: (context, index) {
                    final dica = dicasFiltradas[index];
                    return Card(
                      color: cardColor,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryPurple.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  // CAMPO materia AGORA EXISTE
                                  child: Text(
                                    dica.materia.toUpperCase(),
                                    style: const TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold, fontSize: 10),
                                  ),
                                ),
                                Text(
                                  DateFormat('dd/MM/yyyy').format(dica.dataPostagem), 
                                  style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 11)
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(dica.texto, style: TextStyle(color: textColor, fontSize: 14, height: 1.4)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                "por: ${dica.autorNome}",
                                style: TextStyle(color: textColor.withOpacity(0.4), fontSize: 11, fontStyle: FontStyle.italic),
                              ),
                            )
                          ],
                        ),
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

// --- WIDGET DO FORMULÁRIO (BottomSheet) ---
class _FormularioNovaDica extends ConsumerStatefulWidget {
  const _FormularioNovaDica();

  @override
  ConsumerState<_FormularioNovaDica> createState() => _FormularioNovaDicaState();
}

class _FormularioNovaDicaState extends ConsumerState<_FormularioNovaDica> {
  final _formKey = GlobalKey<FormState>();
  final _materiaController = TextEditingController();
  final _textoController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _materiaController.dispose();
    _textoController.dispose();
    super.dispose();
  }

  Future<void> _postarDica() async {
    final t = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final usuario = ref.read(provedorNotificadorAutenticacao).usuario;
      
      final novaDica = DicaAluno(
        id: '',
        texto: _textoController.text.trim(),
        materia: _materiaController.text.trim(),
        dataPostagem: DateTime.now(),
        alunoId: usuario?.uid ?? 'anonimo',
        autorNome: usuario?.alunoInfo?.nomeCompleto.split(' ')[0] ?? 'Aluno',
        nomeBaseDisciplina: _materiaController.text.trim(), // Salva a tag como base para busca
      );

      // Usando o método NOVO específico para comunidade
      await ref.read(servicoFirestoreProvider).adicionarDicaComunidade(novaDica);

      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.t('dicas_postada_sucesso')), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bg = theme.brightness == Brightness.dark ? AppColors.surfaceDark : Colors.white;
    final textColor = theme.textTheme.bodyLarge?.color;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.t('dicas_nova_titulo'), style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _materiaController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: t.t('dicas_nova_materia_label'),
                hintText: t.t('dicas_nova_materia_hint'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v!.isEmpty ? t.t('campo_obrigatorio') : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _textoController,
              style: TextStyle(color: textColor),
              maxLines: 4,
              decoration: InputDecoration(
                labelText: t.t('dicas_nova_conteudo_label'),
                hintText: t.t('dicas_nova_conteudo_hint'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v!.isEmpty ? t.t('campo_obrigatorio') : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _postarDica,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : Text(t.t('dicas_salvar_btn'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}