// lib/telas/login/tela_cadastro_usuario.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../models/aluno_info.dart';
import '../../l10n/app_localizations.dart';
import '../comum/overlay_carregamento.dart';

class TelaCadastroUsuario extends ConsumerStatefulWidget {
  final bool isInitialSetup; 
  final String email;
  final String password;

  const TelaCadastroUsuario({
    super.key, 
    this.isInitialSetup = false,
    this.email = '', 
    this.password = ''
  });

  @override
  ConsumerState<TelaCadastroUsuario> createState() => _TelaCadastroUsuarioState();
}

class _TelaCadastroUsuarioState extends ConsumerState<TelaCadastroUsuario> {
  final _formKey = GlobalKey<FormState>();

  String _papelSelecionado = 'aluno'; 
  final _nomeController = TextEditingController();
  final _raOuIdController = TextEditingController();
  final _cursoController = TextEditingController();
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  
  DateTime? _dataNascimento;
  String? _universidadeSelecionada;
  
  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
    _passwordController = TextEditingController(text: widget.password);
    _confirmPasswordController = TextEditingController(text: widget.password);
    
    if (widget.isInitialSetup) {
       final user = ref.read(provedorNotificadorAutenticacao).usuario;
       if (user != null) {
         _emailController.text = user.email;
       }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _raOuIdController.dispose();
    _cursoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  void _selecionarDataNascimento() async {
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: _dataNascimento ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 5)), 
    );
    if (data != null) {
      setState(() => _dataNascimento = data);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_papelSelecionado == 'aluno' && _dataNascimento == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A data de nascimento é obrigatória.'), backgroundColor: Colors.red),
      );
      return;
    }

    ref.read(provedorCarregando.notifier).state = true;
    final t = AppLocalizations.of(context)!;
    
    try {
      if (widget.isInitialSetup) {
        // ATUALIZAR PERFIL (Google Login)
        if (_papelSelecionado == 'aluno') {
           final info = AlunoInfo(
            nomeCompleto: _nomeController.text.trim(),
            ra: _raOuIdController.text.trim(),
            curso: _cursoController.text.trim(), 
            dataNascimento: _dataNascimento!,
            cr: 0.0,
            status: 'Regular',
          );
          await ref.read(provedorNotificadorAutenticacao.notifier).salvarPerfilAluno(info);
          await ref.read(provedorNotificadorAutenticacao.notifier).selecionarPapel('aluno');
        } else {
           // Professor/CA - Identificação nula/vazia
           await ref.read(provedorNotificadorAutenticacao.notifier).selecionarPapel(
            _papelSelecionado,
            tipoIdentificacao: 'N/A',
            numIdentificacao: '',
           );
        }
      } else {
        // CRIAR NOVA CONTA (Email/Senha)
        if (_papelSelecionado == 'aluno') {
          await ref.read(provedorNotificadorAutenticacao.notifier).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            nomeCompleto: _nomeController.text.trim(),
            ra: _raOuIdController.text.trim(),
            curso: _cursoController.text.trim(),
            dataNascimento: _dataNascimento!,
          );
        } else {
          // Professor/CA - Cadastro simplificado sem ID
          await ref.read(provedorNotificadorAutenticacao.notifier).signUpComIdentificacao(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            papel: _papelSelecionado,
            nomeCompleto: _nomeController.text.trim(),
            identificacao: '', // Vazio
            tipoIdentificacao: 'N/A', // Vazio
          );
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.t('cadastro_sucesso')), backgroundColor: Colors.green),
        );
        if (!widget.isInitialSetup) Navigator.pop(context);
      }

    } catch (e) {
      if (mounted) {
        ref.read(provedorCarregando.notifier).state = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
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
      appBar: AppBar(
        title: Text(t.t('cadastro_titulo')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.isInitialSetup) ...[
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: t.t('login_email'), border: const OutlineInputBorder()),
                    enabled: !estaCarregando,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(labelText: t.t('login_senha'), border: const OutlineInputBorder()),
                    enabled: !estaCarregando,
                  ),
                  const SizedBox(height: 16),
              ],

              // UNIVERSIDADE (FIXO)
              DropdownButtonFormField<String>(
                value: 'UFSCar - Campus Sorocaba',
                decoration: InputDecoration(
                  labelText: t.t('cadastro_universidade'),
                  border: const OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'UFSCar - Campus Sorocaba', child: Text('UFSCar - Campus Sorocaba')),
                ],
                onChanged: estaCarregando ? null : (v) {},
              ),
              const SizedBox(height: 16),

              // SELEÇÃO DE PAPEL
              DropdownButtonFormField<String>(
                value: _papelSelecionado,
                decoration: InputDecoration(
                  labelText: t.t('cadastro_papel_label'),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'aluno', child: Text(t.t('papel_aluno'))),
                  DropdownMenuItem(value: 'professor', child: Text(t.t('papel_professor'))),
                  DropdownMenuItem(value: 'ca_projeto', child: Text(t.t('papel_ca'))),
                ],
                onChanged: estaCarregando ? null : (v) {
                  if (v != null) {
                    setState(() {
                      _papelSelecionado = v;
                      _raOuIdController.clear();
                      _dataNascimento = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // NOME COMPLETO
              TextFormField(
                controller: _nomeController,
                decoration: InputDecoration(
                  labelText: t.t('cadastro_nome_label'),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
                enabled: !estaCarregando,
              ),
              const SizedBox(height: 16),
              
              // CAMPOS APENAS PARA ALUNO
              if (_papelSelecionado == 'aluno') ...[
                DropdownButtonFormField<String>(
                   decoration: InputDecoration(
                    labelText: t.t('cadastro_curso'),
                    border: const OutlineInputBorder(),
                  ),
                  items: AppLocalizations.cursos.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: estaCarregando ? null : (v) {
                    if (v != null) _cursoController.text = v;
                  },
                  validator: (v) => (v == null) ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _raOuIdController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: t.t('cadastro_ra_label'), border: const OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
                  enabled: !estaCarregando,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_dataNascimento == null
                      ? t.t('cadastro_data_nasc_label')
                      : DateFormat('dd/MM/yyyy').format(_dataNascimento!)),
                  onPressed: estaCarregando ? null : _selecionarDataNascimento,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ],
              
              // PARA PROFESSOR E CA: NÃO MOSTRA MAIS CAMPOS DE ID

              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: estaCarregando 
                  ? Container(width: 20, height: 20, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.person_add),
                label: Text(estaCarregando ? t.t('cadastro_carregando') : t.t('cadastro_finalizar')),
                onPressed: estaCarregando ? null : _submit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}