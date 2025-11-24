// lib/telas/aluno/tela_editar_perfil.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../models/aluno_info.dart';
import '../../l10n/app_localizations.dart';
import '../comum/overlay_carregamento.dart';

class TelaEditarPerfil extends ConsumerStatefulWidget {
  final bool isFromSignUp; 
  const TelaEditarPerfil({super.key, this.isFromSignUp = false});

  @override
  ConsumerState<TelaEditarPerfil> createState() => _TelaEditarPerfilState();
}

class _TelaEditarPerfilState extends ConsumerState<TelaEditarPerfil> {
  final _formKey = GlobalKey<FormState>();
  late final AlunoInfo _alunoInfoOriginal;

  final _nomeController = TextEditingController();
  final _raController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  
  String? _cursoSelecionado; // Para o Dropdown
  DateTime? _dataNascimento;
  final List<String> _statusOpcoes = ['Regular', 'Trancado', 'Jubilado', 'Concluído'];
  String? _statusSelecionado;

  @override
  void initState() {
    super.initState();
    // Carrega os dados do usuário logado
    final alunoInfo = ref.read(provedorNotificadorAutenticacao).usuario?.alunoInfo;
    
    // Prevenção de erro: Se não tiver info, volta
    if (alunoInfo == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.of(context).pop());
      return;
    }
    
    _alunoInfoOriginal = alunoInfo;
    _nomeController.text = alunoInfo.nomeCompleto;
    _raController.text = alunoInfo.ra;
    
    // --- CORREÇÃO DO ERRO DO DROPDOWN ---
    // Verifica se o curso salvo existe na lista oficial. Se não, deixa null ou define um padrão.
    final cursosValidos = AppLocalizations.cursos;
    if (cursosValidos.contains(alunoInfo.curso)) {
      _cursoSelecionado = alunoInfo.curso;
    } else {
      _cursoSelecionado = null; // Obriga o usuário a selecionar novamente se estiver inválido
    }
    // ------------------------------------

    _dataNascimento = alunoInfo.dataNascimento;
    if (_dataNascimento != null) {
      _dataNascimentoController.text = DateFormat('dd/MM/yyyy').format(_dataNascimento!);
    }

    _statusSelecionado = _statusOpcoes.contains(alunoInfo.status) ? alunoInfo.status : 'Regular';
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _raController.dispose();
    _dataNascimentoController.dispose();
    super.dispose();
  }

  void _selecionarDataNascimento() async {
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: _dataNascimento ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(), 
    );
    if (data != null) {
      setState(() {
        _dataNascimento = data;
        _dataNascimentoController.text = DateFormat('dd/MM/yyyy').format(data);
      });
    }
  }

  Future<void> _salvarPerfil() async {
    if (!_formKey.currentState!.validate() || _dataNascimento == null || _statusSelecionado == null || _cursoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos.'), backgroundColor: Colors.red),
      );
      return;
    }

    ref.read(provedorCarregando.notifier).state = true;
    final t = AppLocalizations.of(context)!;

    final novoAlunoInfo = AlunoInfo(
      nomeCompleto: _nomeController.text.trim(),
      ra: _raController.text.trim(),
      curso: _cursoSelecionado!,
      dataNascimento: _dataNascimento,
      cr: _alunoInfoOriginal.cr,
      status: _statusSelecionado!,
    );

    try {
      await ref.read(provedorNotificadorAutenticacao.notifier).salvarPerfilAluno(novoAlunoInfo);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.t('aluno_perfil_edit_sucesso')), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        ref.read(provedorCarregando.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final estaCarregando = ref.watch(provedorCarregando);

    return Scaffold(
      appBar: AppBar(title: Text(t.t('editar_perfil_titulo'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nomeController,
                    decoration: InputDecoration(labelText: t.t('cadastro_nome_label'), border: const OutlineInputBorder()),
                    validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
                    enabled: !estaCarregando,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _raController,
                    decoration: InputDecoration(labelText: t.t('cadastro_ra_label'), border: const OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    enabled: !estaCarregando,
                  ),
                  const SizedBox(height: 16),
                  
                  // --- DROPDOWN CORRIGIDO ---
                  DropdownButtonFormField<String>(
                    value: _cursoSelecionado,
                    isExpanded: true, // Evita overflow de texto
                    decoration: InputDecoration(labelText: t.t('cadastro_curso_label'), border: const OutlineInputBorder()),
                    items: AppLocalizations.cursos.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: estaCarregando ? null : (v) => setState(() => _cursoSelecionado = v),
                    validator: (v) => v == null ? 'Campo obrigatório' : null,
                  ),
                  // ---------------------------

                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dataNascimentoController,
                    decoration: InputDecoration(labelText: t.t('cadastro_data_nasc_label'), border: const OutlineInputBorder(), suffixIcon: const Icon(Icons.calendar_today)),
                    readOnly: true, 
                    onTap: _selecionarDataNascimento,
                    enabled: !estaCarregando,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: Text(t.t('aluno_perfil_salvar')),
                    onPressed: estaCarregando ? null : _salvarPerfil,
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