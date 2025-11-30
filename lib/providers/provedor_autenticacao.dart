// lib/providers/provedor_autenticacao.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Importa modelos e serviço de dados
import '../models/usuario.dart';
import '../models/aluno_info.dart';
import '../services/servico_firestore.dart';

/// Estados possíveis da autenticação no aplicativo.
/// - [desconhecido]: App acabou de abrir, ainda verificando.
/// - [autenticado]: Usuário logado e verificado.
/// - [naoAutenticado]: Usuário saiu ou nunca entrou.
enum StatusAutenticacao { desconhecido, autenticado, naoAutenticado }

/// Classe imutável que guarda o estado atual da autenticação.
class EstadoAutenticacao {
  final StatusAutenticacao status;
  final UsuarioApp? usuario; // Dados completos do usuário (incluindo perfil)
  final bool carregando; // Se está processando login/cadastro
  final String? erro; // Mensagem de erro para exibir na UI

  EstadoAutenticacao({
    this.status = StatusAutenticacao.desconhecido,
    this.usuario,
    this.carregando = false,
    this.erro,
  });

  // Método copyWith para facilitar a atualização do estado imutável
  EstadoAutenticacao copyWith({
    StatusAutenticacao? status,
    UsuarioApp? usuario,
    bool? carregando,
    String? erro,
    bool limparUsuario = false,
  }) {
    return EstadoAutenticacao(
      status: status ?? this.status,
      usuario: limparUsuario ? null : (usuario ?? this.usuario),
      carregando: carregando ?? this.carregando,
      erro: erro, // Se passar null, limpa o erro anterior
    );
  }
}

/// Notificador (Controller) que gerencia a lógica de autenticação.
/// Usa o Firebase Auth e conecta com o Firestore para dados extras.
class NotificadorAutenticacao extends StateNotifier<EstadoAutenticacao> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Ref _ref;

  NotificadorAutenticacao(this._ref)
      : super(EstadoAutenticacao(status: StatusAutenticacao.desconhecido)) {
    // Inicia o monitoramento assim que o provedor é criado
    _checarStatusAutenticacao();
  }

  /// Monitora o estado do usuário no Firebase (Persistência de Login).
  /// Se o usuário fechar e abrir o app, isso garante que ele continue logado.
  Future<void> _checarStatusAutenticacao() async {
    await Future.delayed(const Duration(seconds: 1)); // Pequeno delay visual
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        // Usuário está logado no Firebase Auth.
        // Agora buscamos os dados completos (perfil, papel) no Firestore.
        final usuarioApp = await _ref.read(servicoFirestoreProvider).getUsuario(user.uid);

        if (usuarioApp != null) {
          // Usuário já tem cadastro completo
          state = EstadoAutenticacao(
            status: StatusAutenticacao.autenticado,
            usuario: usuarioApp,
          );
        } else {
          // Usuário existe no Auth mas não no Firestore (ex: primeiro login com Google).
          // Criamos um documento padrão para ele preencher depois.
          final novoUsuario = await _criarDocumentoUsuarioPadrao(
            uid: user.uid,
            email: user.email ?? '',
          );
          state = EstadoAutenticacao(
            status: StatusAutenticacao.autenticado,
            usuario: novoUsuario,
          );
        }
      } else {
        // Ninguém logado
        state = EstadoAutenticacao(status: StatusAutenticacao.naoAutenticado);
      }
    });
  }

  /// Realiza o login com E-mail e Senha.
  Future<void> login(String email, String password) async {
    try {
      state = state.copyWith(erro: null, carregando: true);
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // O listener _checarStatusAutenticacao cuidará de atualizar o estado global
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(carregando: false, erro: _traduzirErroAuth(e.code));
      throw e; // Repassa o erro para a tela exibir feedback
    } catch (e) {
      state = state.copyWith(carregando: false, erro: 'Erro inesperado: $e');
      throw e;
    }
  }

  /// Cadastro de Aluno com dados completos.
  Future<void> signUp({
    required String email,
    required String password,
    required String nomeCompleto,
    required String ra,
    required String curso,
    required DateTime dataNascimento,
  }) async {
    try {
      state = state.copyWith(erro: null, carregando: true);
      // 1. Cria usuário no Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      
      if (userCredential.user != null) {
        final user = userCredential.user!;
        
        // 2. Cria o objeto de dados do aluno
        final info = AlunoInfo(
          nomeCompleto: nomeCompleto,
          ra: ra,
          curso: curso,
          dataNascimento: dataNascimento,
          cr: 0.0, // Inicia com CR zero
          status: 'Regular',
        );
        
        // 3. Salva no Firestore
        final novoUsuario = UsuarioApp(
          uid: user.uid,
          email: user.email!,
          papel: 'aluno',
          alunoInfo: info,
          nfcCardId: null,
          tipoIdentificacao: null,
        );

        await _ref.read(servicoFirestoreProvider).criarDocumentoUsuario(novoUsuario);
      }
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(carregando: false, erro: _traduzirErroAuth(e.code));
      throw e;
    } catch (e) {
      state = state.copyWith(carregando: false, erro: 'Erro ao cadastrar: $e');
      throw e;
    }
  }
  
  /// Cadastro de Professor ou CA (Com Identificação Específica).
  /// Diferente do aluno, não pede curso nem data de nascimento no cadastro.
  Future<void> signUpComIdentificacao({
    required String email,
    required String password,
    required String papel,
    required String nomeCompleto,
    required String identificacao, // Matrícula SIAPE ou ID Externo
    required String tipoIdentificacao,
  }) async {
    try {
      state = state.copyWith(erro: null, carregando: true);
      final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      
      if (userCredential.user != null) {
        final user = userCredential.user!;
        
        final novoUsuario = UsuarioApp(
          uid: user.uid,
          email: user.email!,
          papel: papel, 
          alunoInfo: AlunoInfo(
            nomeCompleto: nomeCompleto,
            ra: identificacao, // Reutiliza o campo RA para armazenar a ID
            curso: '',
            cr: 0.0,
            status: '',
            dataNascimento: DateTime.now() // Placeholder
          ),
          nfcCardId: null,
          tipoIdentificacao: tipoIdentificacao,
        );

        await _ref.read(servicoFirestoreProvider).criarDocumentoUsuario(novoUsuario);
      }
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(carregando: false, erro: _traduzirErroAuth(e.code));
      throw e;
    } catch (e) {
      state = state.copyWith(carregando: false, erro: 'Erro ao cadastrar: $e');
      throw e;
    }
  }

  /// Login com Google (Compatível com Web e Mobile).
  Future<void> loginComGoogle() async {
    try {
      state = state.copyWith(erro: null, carregando: true);
      
      if (kIsWeb) {
        // Fluxo Web (Popup)
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(googleProvider);
        if (userCredential.user != null) {
          await _processarLoginSucesso(userCredential.user!);
        }
      } else {
        // Fluxo Mobile (Nativo)
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        
        if (googleUser == null) { 
          // Usuário cancelou a janela de login
          state = state.copyWith(carregando: false);
          return;
        }
        
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        final userCredential = await _auth.signInWithCredential(credential);
        if (userCredential.user != null) {
          await _processarLoginSucesso(userCredential.user!);
        }
      }
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(carregando: false, erro: _traduzirErroAuth(e.code));
    } catch (e) {
      state = state.copyWith(
          carregando: false, erro: 'Erro no login com Google: ${e.toString()}');
    }
  }
  
  /// Helper para verificar se o usuário do Google já existe no banco.
  Future<void> _processarLoginSucesso(User user) async {
    final servico = _ref.read(servicoFirestoreProvider);
    final usuarioExistente = await servico.getUsuario(user.uid);
    
    if (usuarioExistente == null) {
      // Se é novo, cria doc padrão (o papel ficará vazio até ele escolher na tela de cadastro)
      await _criarDocumentoUsuarioPadrao(
        uid: user.uid,
        email: user.email ?? '',
      );
    }
  }

  /// Atualiza o perfil do aluno (usado na tela de edição).
  Future<void> salvarPerfilAluno(AlunoInfo info) async {
    final user = state.usuario;
    if (user == null) return;
    
    try {
      await _ref.read(servicoFirestoreProvider).salvarPerfilAluno(user.uid, info);
      // Atualiza o estado local instantaneamente
      final usuarioAtualizado = user.copyWith(alunoInfo: info);
      state = state.copyWith(usuario: usuarioAtualizado);
    } catch (e) {
      debugPrint("Erro ao salvar perfil: $e");
      throw Exception("Erro ao salvar perfil");
    }
  }

  /// Define o papel do usuário (Aluno, Professor, CA) no primeiro acesso.
  Future<void> selecionarPapel(String papel, {String? tipoIdentificacao, String? numIdentificacao}) async {
    state = state.copyWith(carregando: true);
    final user = state.usuario;
    if (user == null || user.uid.isEmpty) return;
    try {
      await _ref.read(servicoFirestoreProvider).selecionarPapel(
        user.uid, 
        papel, 
        tipoIdentificacao: tipoIdentificacao
      );
      
      // Recarrega o usuário completo do banco para garantir consistência
      final usuarioAtualizado = await _ref.read(servicoFirestoreProvider).getUsuario(user.uid);
      
      state = state.copyWith(
        usuario: usuarioAtualizado,
        carregando: false,
      );
    } catch (e) {
      state = state.copyWith(
          carregando: false, erro: 'Erro ao salvar papel: ${e.toString()}');
    }
  }

  /// Sai da conta (Logout).
  Future<void> logout() async {
    await _auth.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      // Ignora erro se não estava logado com Google
    }
    // O listener _checarStatusAutenticacao vai mudar o estado para naoAutenticado automaticamente
  }

  /// Cria documento vazio no Firestore para novos usuários.
  Future<UsuarioApp> _criarDocumentoUsuarioPadrao({required String uid, required String email}) async {
    final info = AlunoInfo(
      nomeCompleto: '',
      ra: '',
      curso: '',
      cr: 0.0,
      status: '',
      dataNascimento: null,
    );

    final novoUsuario = UsuarioApp(
      uid: uid,
      email: email,
      papel: '', // Papel vazio força ida para tela de cadastro
      alunoInfo: info, 
      nfcCardId: null,
      tipoIdentificacao: null,
    );
    
    await _ref.read(servicoFirestoreProvider).criarDocumentoUsuario(novoUsuario);
    return novoUsuario;
  }
  
  /// Traduz os códigos de erro técnicos do Firebase para mensagens amigáveis em Português.
  String _traduzirErroAuth(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential': // Novo código do Firebase (segurança)
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'E-mail ou senha incorretos.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'weak-password':
        return 'A senha é muito fraca (mínimo 6 caracteres).';
      case 'invalid-email':
        return 'O formato do e-mail é inválido.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      default:
        debugPrint('Erro Auth não traduzido: $code');
        return 'Erro de autenticação. Verifique seus dados.';
    }
  }
}

/// O provedor global que será usado em todo o app.
final provedorNotificadorAutenticacao =
    StateNotifierProvider<NotificadorAutenticacao, EstadoAutenticacao>((ref) {
  return NotificadorAutenticacao(ref);
});