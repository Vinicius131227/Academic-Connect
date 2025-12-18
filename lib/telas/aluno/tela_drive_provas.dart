// lib/telas/aluno/tela_drive_provas.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import '../../models/material_aula.dart';
import '../../models/pasta_drive.dart';
import '../../services/servico_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';
import '../comum/widget_carregamento.dart';
import '../comum/tela_webview.dart';
import '../../providers/provedor_autenticacao.dart';

// --- PROVIDERS DINÂMICOS (ESCUTAM O FIREBASE) ---

// 1. Busca PASTAS que estão dentro da pasta atual (parentId)
final pastasProvider = StreamProvider.family<List<PastaDrive>, String?>((ref, parentId) {
  return ref.watch(servicoFirestoreProvider).getPastasDrive(parentId: parentId);
});

// 2. Busca ARQUIVOS que estão dentro da pasta atual
final arquivosProvider = StreamProvider.family<List<MaterialAula>, String>((ref, pastaId) {
  // Regra de Negócio: Não mostrar arquivos na raiz para forçar organização
  if (pastaId == 'root') return Stream.value([]); 
  return ref.watch(servicoFirestoreProvider).getArquivosDrive(pastaId);
});

class TelaDriveProvas extends ConsumerStatefulWidget {
  const TelaDriveProvas({super.key});

  @override
  ConsumerState<TelaDriveProvas> createState() => _TelaDriveProvasState();
}

class _TelaDriveProvasState extends ConsumerState<TelaDriveProvas> {
  // PILHA DE NAVEGAÇÃO: O índice 0 é sempre a Raiz
  List<PastaDrive> _caminho = [
    PastaDrive(id: 'root', nome: 'Início', criadoPor: '', dataCriacao: DateTime.now())
  ];
  
  bool _isUploading = false;

  // --- GETTERS INTELIGENTES ---
  
  // A pasta onde o usuário está "entrando" agora
  PastaDrive get _pastaAtual => _caminho.last;
  
  // O ID que será usado para buscar sub-pastas (null se for raiz)
  String? get _currentParentId => _pastaAtual.id == 'root' ? null : _pastaAtual.id;

  // --- AÇÕES DE NAVEGAÇÃO ---

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

  // --- AÇÕES DE BANCO DE DADOS ---

  // 1. Criar Pasta
  Future<void> _criarPastaDialog() async {
    final t = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.create_new_folder, color: AppColors.primaryPurple),
            const SizedBox(width: 8),
            Text(t.t('drive_nova_pasta')),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: t.t('drive_nome_pasta'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: Text(t.t('cancelar'), style: const TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final uid = ref.read(provedorNotificadorAutenticacao).usuario?.uid ?? 'anon';
                
                // CRIA A PASTA USANDO O ID DA PASTA ATUAL COMO PAI
                await ref.read(servicoFirestoreProvider).criarPastaDrive(
                  controller.text.trim(), 
                  _currentParentId,
                  uid
                );
                
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: Text(t.t('drive_criar'), style: const TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // 2. Upload de Arquivo
  Future<void> _fazerUpload() async {
    final t = AppLocalizations.of(context)!;

    // Bloqueia upload na raiz (opcional, mas bom para organização)
    if (_pastaAtual.id == 'root') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Abra uma pasta para adicionar arquivos."), backgroundColor: Colors.orange)
      );
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'doc', 'docx'],
      );

      if (result != null) {
        setState(() => _isUploading = true);
        
        final file = result.files.single;
        // final uid = ref.read(provedorNotificadorAutenticacao).usuario?.uid ?? 'anon';

        // --- SIMULAÇÃO DE UPLOAD ---
        // (Em produção, aqui você enviaria para o Firebase Storage e pegaria a URL)
        await Future.delayed(const Duration(seconds: 1)); // Delay visual

        final novoMaterial = MaterialAula(
          id: '', // Firestore gera
          titulo: file.name,
          descricao: 'Upload via App',
          url: 'https://www.google.com', // URL Mock (substituir pela real do Storage)
          tipo: TipoMaterial.prova, // Pode ser genérico
          dataPostagem: DateTime.now(),
          nomeBaseDisciplina: _pastaAtual.id, // VINCULA O ARQUIVO À PASTA ATUAL
        );

        await ref.read(servicoFirestoreProvider).uploadArquivoDrive(novoMaterial, _pastaAtual.id);

        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(t.t('sucesso')), backgroundColor: Colors.green)
           );
        }
      }
    } catch (e) {
      debugPrint("Erro upload: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
      }
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

    // --- ESCUTA OS STREAMS COM O ID DA PASTA ATUAL ---
    // Isso garante que ao navegar, o conteúdo mude automaticamente
    final asyncPastas = ref.watch(pastasProvider(_currentParentId));
    final asyncArquivos = ref.watch(arquivosProvider(_pastaAtual.id));

    return WillPopScope(
      onWillPop: () async {
        // Se estiver dentro de uma pasta, volta um nível
        if (_caminho.length > 1) {
          _voltarPasta();
          return false; // Impede fechar a tela
        }
        return true; // Fecha a tela se estiver na raiz
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
            // Botão Nova Pasta
            IconButton(
              icon: Icon(Icons.create_new_folder_outlined, color: textColor),
              tooltip: t.t('drive_nova_pasta'),
              onPressed: _criarPastaDialog,
            ),
            // Botão Upload (só aparece se não estiver na raiz)
            if (_pastaAtual.id != 'root')
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
            
            // 1. BREADCRUMBS (Caminho: Início > Provas > P1)
            Container(
              height: 50,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: isDark ? Colors.black12 : Colors.grey[50],
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _caminho.length,
                separatorBuilder: (_,__) => Icon(Icons.chevron_right, size: 16, color: textColor?.withOpacity(0.5)),
                itemBuilder: (context, index) {
                  final pasta = _caminho[index];
                  final isLast = index == _caminho.length - 1;
                  // Se for root, exibe "Início", senão o nome da pasta
                  final nomeExibicao = pasta.id == 'root' ? t.t('drive_raiz') : pasta.nome;
                  
                  return GestureDetector(
                    onTap: isLast ? null : () {
                      // Volta instantaneamente para o nível clicado
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
                          decoration: isLast ? TextDecoration.none : TextDecoration.underline,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),

            if (_isUploading) const LinearProgressIndicator(color: AppColors.primaryPurple),

            // 2. CONTEÚDO (Pastas e Arquivos misturados ou separados)
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  // Loading Combinado
                  if (asyncPastas.isLoading || asyncArquivos.isLoading) {
                    return const WidgetCarregamento();
                  }

                  final pastas = asyncPastas.value ?? [];
                  final arquivos = asyncArquivos.value ?? [];

                  // Ordenação Alfabética Local para UX melhor
                  pastas.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
                  arquivos.sort((a, b) => a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase()));

                  if (pastas.isEmpty && arquivos.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open, size: 80, color: Colors.grey.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          Text(t.t('drive_vazio'), style: TextStyle(color: textColor?.withOpacity(0.5))),
                          if (_pastaAtual.id == 'root')
                             Padding(
                               padding: const EdgeInsets.only(top: 8.0),
                               child: Text("Crie uma pasta para começar.", style: TextStyle(fontSize: 12, color: textColor?.withOpacity(0.4))),
                             ),
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
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.folder, color: Colors.amber, size: 24),
                            ),
                            title: Text(p.nome, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () => _navegarParaPasta(p), // <--- ENTRA NA PASTA
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
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppColors.primaryPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.insert_drive_file, color: AppColors.primaryPurple, size: 24),
                            ),
                            title: Text(arq.titulo, style: TextStyle(color: textColor)),
                            subtitle: Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(arq.dataPostagem), 
                              style: TextStyle(color: textColor?.withOpacity(0.5), fontSize: 11)
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.open_in_new, color: Colors.grey),
                              onPressed: () {
                                // Abre WebView ou Download
                                Navigator.push(context, MaterialPageRoute(builder: (_) => TelaWebView(url: arq.url, titulo: arq.titulo)));
                              },
                            ),
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