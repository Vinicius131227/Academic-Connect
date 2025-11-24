import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/provedores_app.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../services/servico_firestore.dart';
import '../../models/solicitacao_aluno.dart';
import '../../models/turma_professor.dart';
import '../comum/widget_carregamento.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io'; 
import '../../l10n/app_localizations.dart';
import '../comum/animacao_fadein_lista.dart'; 

class TelaSolicitarAdaptacao extends ConsumerStatefulWidget {
  const TelaSolicitarAdaptacao({super.key});

  @override
  ConsumerState<TelaSolicitarAdaptacao> createState() => _TelaSolicitarAdaptacaoState();
}

class _TelaSolicitarAdaptacaoState extends ConsumerState<TelaSolicitarAdaptacao> {
  final _formKey = GlobalKey<FormState>();
  TurmaProfessor? _turmaSelecionada;
  final _descricaoController = TextEditingController();
  bool _isLoading = false;
  File? _arquivoSelecionado;

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE ENVIO ATUALIZADA (SEM STORAGE) ---
  Future<void> _enviarSolicitacao() async {
    if (!_formKey.currentState!.validate() || _turmaSelecionada == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos obrigatórios.'), backgroundColor: Colors.red),
      );
      return;
    }
    
    final usuario = ref.read(provedorNotificadorAutenticacao).usuario;
    if (usuario == null || usuario.alunoInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Não foi possível identificar o aluno.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    String? nomeAnexo;
    
    try {
      // --- ETAPA DE UPLOAD (SIMULADA) ---
      if (_arquivoSelecionado != null) {
        // 1. Em vez de fazer upload, apenas pegamos o nome do arquivo
        nomeAnexo = _arquivoSelecionado!.path.split(Platform.pathSeparator).last;
      }
      // --- FIM ETAPA DE UPLOAD ---

      // 2. Cria o objeto Solicitação com o NOME do arquivo
      final novaSolicitacao = SolicitacaoAluno(
        id: '', 
        nomeAluno: usuario.alunoInfo!.nomeCompleto,
        ra: usuario.alunoInfo!.ra,
        disciplina: _turmaSelecionada!.nome,
        tipo: 'Adaptação de Prova', 
        data: DateTime.now(),
        descricao: _descricaoController.text,
        anexo: nomeAnexo, // Salva o NOME do arquivo (ex: "laudo.pdf")
        status: StatusSolicitacao.pendente,
        alunoId: usuario.uid,
        professorId: _turmaSelecionada!.professorId, 
        turmaId: _turmaSelecionada!.id,
        respostaProfessor: null, 
      );

      // 3. Salva a solicitação no Firestore
      await ref.read(servicoFirestoreProvider).adicionarSolicitacao(novaSolicitacao);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitação enviada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
       if (mounted) {
         setState(() => _isLoading = false);
       }
    }
  }
  // --- FIM LÓGICA ATUALIZADA ---

  Future<void> _pegarArquivo() async {
     try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png'],
      );
      if (result != null) {
        setState(() {
          _arquivoSelecionado = File(result.files.single.path!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar arquivo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final asyncSolicitacoes = ref.watch(provedorStreamSolicitacoesAluno);
    final asyncTurmas = ref.watch(provedorStreamTurmasAluno);
    final theme = Theme.of(context);

    final widgets = [
      // Aviso
      Card(
        color: theme.colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: theme.colorScheme.onSecondaryContainer, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t.t('adaptacao_aviso'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Formulário
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                asyncTurmas.when(
                  loading: () => const Center(child: Text('Carregando disciplinas...')),
                  error: (e,s) => const Center(child: Text('Erro ao carregar disciplinas')),
                  data: (turmas) {
                    return DropdownButtonFormField<TurmaProfessor>(
                      value: _turmaSelecionada,
                      hint: const Text('Escolha uma disciplina'),
                      decoration: InputDecoration(
                        labelText: t.t('adaptacao_disciplina'),
                      ),
                      items: turmas.map((TurmaProfessor turma) {
                        return DropdownMenuItem<TurmaProfessor>(
                          value: turma,
                          child: Text(turma.nome),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() => _turmaSelecionada = newValue);
                      },
                      validator: (v) => (v == null) ? 'Campo obrigatório' : null,
                    );
                  }
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descricaoController,
                  decoration: InputDecoration(
                    labelText: t.t('adaptacao_descricao'),
                    hintText: 'Explique detalhadamente qual adaptação...',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: Icon(
                    _arquivoSelecionado == null ? Icons.attach_file : Icons.check_circle,
                    size: 18,
                    color: _arquivoSelecionado == null ? null : Colors.green,
                  ),
                  label: Text(
                    _arquivoSelecionado == null 
                      ? t.t('adaptacao_anexar')
                      : _arquivoSelecionado!.path.split(Platform.pathSeparator).last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: _pegarArquivo,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: _arquivoSelecionado == null ? null : Colors.green,
                    side: BorderSide(
                      color: _arquivoSelecionado == null ? theme.colorScheme.outline : Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.t('adaptacao_formatos'),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: _isLoading 
                    ? Container(width: 20, height: 20, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_outlined, size: 18),
                  label: Text(_isLoading ? 'Enviando...' : t.t('adaptacao_enviar')),
                  onPressed: _isLoading ? null : _enviarSolicitacao,
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Text(t.t('adaptacao_anteriores'), style: theme.textTheme.titleLarge),
      ),
      const SizedBox(height: 8),
      
      asyncSolicitacoes.when(
        loading: () => const WidgetCarregamento(),
        error: (e,s) => Text('Erro: $e'),
        data: (solicitacoes) {
          if (solicitacoes.isEmpty) {
            return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('Nenhuma solicitação anterior.')));
          }
          return Column(
            children: solicitacoes.map((s) => _buildCardSolicitacao(context, t, s)).toList(),
          );
        }
      )
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('adaptacao_titulo')),
      ),
      body: FadeInListAnimation(children: widgets),
    );
  }

  Widget _buildCardSolicitacao(BuildContext context, AppLocalizations t, SolicitacaoAluno s) {
    Color cor;
    String textoStatus;
    switch (s.status) {
      case StatusSolicitacao.aprovada:
        cor = Colors.green;
        textoStatus = t.t('notas_aprovado');
        break;
      case StatusSolicitacao.pendente:
        cor = Colors.orange;
        textoStatus = t.t('notas_em_curso'); 
        break;
      case StatusSolicitacao.recusada:
        cor = Colors.red;
        textoStatus = 'Recusada';
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.disciplina, style: Theme.of(context).textTheme.titleMedium),
            Text(s.tipo, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    textoStatus,
                    style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                Text(DateFormat('dd/MM/yyyy').format(s.data), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            
            if (s.status == StatusSolicitacao.recusada && s.respostaProfessor != null) ...[
              const Divider(height: 20),
              Text(
                'Motivo da Recusa:', // TODO: Adicionar tradução
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                s.respostaProfessor!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ]
          ],
        ),
      ),
    );
  }
}