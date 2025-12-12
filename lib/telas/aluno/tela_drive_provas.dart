// lib/telas/aluno/tela_drive_provas.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/material_aula.dart';
import '../../models/pasta_drive.dart';
import '../../services/servico_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';
import '../comum/widget_carregamento.dart';
import '../comum/tela_webview.dart';
import '../../providers/provedor_autenticacao.dart';

// Providers dinâmicos para buscar conteúdo da pasta atual
final pastasProvider = StreamProvider.family<List<PastaDrive>, String?>((ref, parentId) {
  return ref.watch(servicoFirestoreProvider).getPastasDrive(parentId: parentId);
});

final arquivosProvider = StreamProvider.family<List<MaterialAula>, String>((ref, pastaId) {
  // Se for raiz (null), não busca arquivos, apenas pastas para organização
  if (pastaId == 'root') return Stream.value([]); 
  return ref.watch(servicoFirestoreProvider).getArquivosDrive(pastaId);
});

class TelaDriveProvas extends ConsumerStatefulWidget {
  const TelaDriveProvas({super.key});

  @override
  ConsumerState<TelaDriveProvas> createState() => _TelaDriveProvasState();
}

class _TelaDriveProvasState extends ConsumerState<TelaDriveProvas> {
  // Controle de Navegação (Pilha de pastas)
  // O primeiro item é a raiz (id: null, nome: 'Início')
  List<PastaDrive> _caminho = [PastaDrive(id: 'root', nome: 'root_label', criadoPor: '', dataCriacao: DateTime.now())];
  
  bool _isUploading = false;

  // Retorna a pasta atual (última da lista)
  PastaDrive get _pastaAtual => _caminho.last;
  String? get _currentParentId => _pastaAtual.id == 'root' ? null : _pastaAtual.id;

  // --- AÇÕES ---

  void _navegarParaPasta(PastaDrive pasta) {
    setState(() {
      _caminho.add(pasta);
    });
  }

  void _voltarPasta() {
    if (_caminho.length > 1) {
      setState(() {
        _caminho.removeLast();
      });
    }
  }

  // Criação de Pasta
  Future<void> _criarPastaDialog() async {
    final t = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.t('drive_nova_pasta')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: t.t('drive_nome_pasta')),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.t('cancelar'))),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final uid = ref.read(provedorNotificadorAutenticacao).usuario?.uid ?? 'anon';
                await ref.read(servicoFirestoreProvider).criarPastaDrive(
                  controller.text.trim(), 
                  _currentParentId, 
                  uid
                );
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: Text(t.t('drive_criar')),
          )
        ],
      ),
    );
  }

  // Upload de Arquivo
  Future<void> _fazerUpload() async {
    // Só permite upload dentro de pastas, não na raiz (para organização)
    if (_pastaAtual.id == 'root') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Crie ou entre em uma pasta para adicionar arquivos.")));
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'doc'],
      );

      if (result != null) {
        setState(() => _isUploading = true);
        
        final file = result.files.single;
        final uid = ref.read(provedorNotificadorAutenticacao).usuario?.uid ?? 'anon';

        // MOCK: Em um app real, aqui faríamos upload para o Firebase Storage
        // e pegaríamos a URL. Como não temos Storage configurado no exemplo:
        // Vamos salvar apenas o registro com uma URL fictícia ou link externo.
        
        // Simula delay de upload
        await Future.delayed(const Duration(seconds: 1));

        final novoMaterial = MaterialAula(
          id: '',
          titulo: file.name,
          descricao: 'Enviado por aluno',
          url: 'https://www.google.com', // URL Mock
          tipo: TipoMaterial.prova,
          dataPostagem: DateTime.now(),
          nomeBaseDisciplina: _pastaAtual.id, // VINCULA À PASTA ATUAL
        );

        await ref.read(servicoFirestoreProvider).uploadArquivoDrive(novoMaterial, _pastaAtual.id);

        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Arquivo enviado com sucesso!"), backgroundColor: Colors.green));
        }
      }
    } catch (e) {
      debugPrint("Erro upload: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;

    // Observa pastas e arquivos do nível atual
    final asyncPastas = ref.watch(pastasProvider(_currentParentId));
    final asyncArquivos = ref.watch(arquivosProvider(_pastaAtual.id));

    return WillPopScope(
      onWillPop: () async {
        if (_caminho.length > 1) {
          _voltarPasta();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(t.t('drive_titulo'), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
          leading: _caminho.length > 1 
            ? IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: _voltarPasta)
            : BackButton(color: textColor),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.create_new_folder_outlined, color: textColor),
              tooltip: t.t('drive_nova_pasta'),
              onPressed: _criarPastaDialog,
            ),
            IconButton(
              icon: Icon(Icons.cloud_upload_outlined, color: textColor),
              tooltip: t.t('drive_upload_arquivo'),
              onPressed: _fazerUpload,
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BREADCRUMBS (Caminho: Início > Pasta A > Pasta B)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _caminho.length,
                separatorBuilder: (_,__) => Icon(Icons.chevron_right, size: 16, color: textColor?.withOpacity(0.5)),
                itemBuilder: (context, index) {
                  final pasta = _caminho[index];
                  final isLast = index == _caminho.length - 1;
                  final nomeExibicao = pasta.id == 'root' ? t.t('drive_raiz') : pasta.nome;
                  
                  return GestureDetector(
                    onTap: isLast ? null : () {
                      // Volta até a pasta clicada
                      setState(() {
                        _caminho.removeRange(index + 1, _caminho.length);
                      });
                    },
                    child: Center(
                      child: Text(
                        nomeExibicao,
                        style: TextStyle(
                          color: isLast ? AppColors.primaryPurple : textColor?.withOpacity(0.7),
                          fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),

            if (_isUploading) const LinearProgressIndicator(),

            // LISTA DE CONTEÚDO
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  // Carregamento combinado
                  if (asyncPastas.isLoading || asyncArquivos.isLoading) {
                    return const WidgetCarregamento();
                  }

                  final pastas = asyncPastas.value ?? [];
                  final arquivos = asyncArquivos.value ?? [];

                  if (pastas.isEmpty && arquivos.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open, size: 64, color: Colors.grey.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(t.t('drive_vazio'), style: TextStyle(color: textColor?.withOpacity(0.5))),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // SEÇÃO DE PASTAS
                      if (pastas.isNotEmpty) ...[
                        Text("Pastas", style: TextStyle(color: textColor?.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...pastas.map((p) => Card(
                          color: cardColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.withOpacity(0.2))),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.folder, color: Colors.amber, size: 32),
                            title: Text(p.nome, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () => _navegarParaPasta(p),
                          ),
                        )),
                        const SizedBox(height: 24),
                      ],

                      // SEÇÃO DE ARQUIVOS
                      if (arquivos.isNotEmpty) ...[
                        Text("Arquivos", style: TextStyle(color: textColor?.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...arquivos.map((arq) => Card(
                          color: cardColor,
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.description, color: Colors.redAccent, size: 32),
                            title: Text(arq.titulo, style: TextStyle(color: textColor)),
                            subtitle: Text(
                              DateFormat('dd/MM/yyyy').format(arq.dataPostagem), 
                              style: TextStyle(color: textColor?.withOpacity(0.5), fontSize: 11)
                            ),
                            trailing: const Icon(Icons.download_rounded, color: AppColors.primaryPurple),
                            onTap: () {
                               Navigator.push(context, MaterialPageRoute(builder: (_) => TelaWebView(url: arq.url, titulo: arq.titulo)));
                            },
                          ),
                        )),
                      ]
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}