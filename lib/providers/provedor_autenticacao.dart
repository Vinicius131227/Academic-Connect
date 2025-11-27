import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/usuario.dart';
import '../models/aluno_info.dart';
import '../services/servico_firestore.dart';

enum StatusAutenticacao { desconhecido, autenticado, naoAutenticado }

class EstadoAutenticacao {
  final StatusAutenticacao status;
  final UsuarioApp? usuario;
  final bool carregando;
  final String? erro;

  EstadoAutenticacao({
    this.status = StatusAutenticacao.desconhecido,
    this.usuario,
    this.carregando = false,
    this.erro,
  });

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
      erro: erro, // Se passar null, limpa o erro
    );
  }
}

class NotificadorAutenticacao extends StateNotifier<EstadoAutenticacao> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Ref _ref;

  NotificadorAutenticacao(this._ref)
      : super(EstadoAutenticacao(status: StatusAutenticacao.desconhecido)) {
    _checarStatusAutenticacao();
  }

  // Monitora o estado do usuário no Firebase (Persistência)
  Future<void> _checarStatusAutenticacao() async {
    await Future.delayed(const Duration(seconds: 1)); // Pequeno delay para evitar flash
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        // Usuário logado, busca dados no Firestore
        final usuarioApp = await _ref.read(servicoFirestoreProvider).getUsuario(user.uid);

        if (usuarioApp != null) {
          state = EstadoAutenticacao(
            status: StatusAutenticacao.autenticado,
            usuario: usuarioApp,
          );
        } else {
          // Usuário existe no Auth mas não no Firestore (ex: primeiro login Google)
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
        // Usuário deslogado
        state = EstadoAutenticacao(status: StatusAutenticacao.naoAutenticado);
      }
    });
  }

  // Login com Email e Senha
  Future<void> login(String email, String password) async {
    try {
      state = state.copyWith(erro: null, carregando: true);
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // O listener _checarStatusAutenticacao vai atualizar o estado automaticamente
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(carregando: false, erro: _traduzirErroAuth(e.code));
      throw e; // Relança para a UI saber que falhou
    } catch (e) {
      state = state.copyWith(carregando: false, erro: 'Erro inesperado: $e');
      throw e;
    }
  }

  // Cadastro de Aluno
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
      final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      
      if (userCredential.user != null) {
        final user = userCredential.user!;
        
        final info = AlunoInfo(
          nomeCompleto: nomeCompleto,
          ra: ra,
          curso: curso,
          dataNascimento: dataNascimento,
          cr: 0.0,
          status: 'Regular',
        );
        
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
  
  // Cadastro de Professor ou CA (Com Identificação Específica)
  Future<void> signUpComIdentificacao({
    required String email,
    required String password,
    required String papel,
    required String nomeCompleto,
    required String identificacao,
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
            ra: identificacao, // Usa o campo RA para armazenar a ID
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

  // Login com Google
  Future<void> loginComGoogle() async {
    try {
      state = state.copyWith(erro: null, carregando: true);
      
      if (kIsWeb) {
        // Web
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(googleProvider);
        if (userCredential.user != null) {
          await _processarLoginSucesso(userCredential.user!);
        }
      } else {
        // Mobile
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        
        if (googleUser == null) { 
          // Usuário cancelou o login
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

  // Helper para login social
  Future<void> _processarLoginSucesso(User user) async {
    final servico = _ref.read(servicoFirestoreProvider);
    final usuarioExistente = await servico.getUsuario(user.uid);
    
    if (usuarioExistente == null) {
      // Se é novo, cria doc padrão
      await _criarDocumentoUsuarioPadrao(
        uid: user.uid,
        email: user.email ?? '',
      );
    }
  }

  // Atualizar Perfil
  Future<void> salvarPerfilAluno(AlunoInfo info) async {
    final user = state.usuario;
    if (user == null) return;
    
    try {
      await _ref.read(servicoFirestoreProvider).salvarPerfilAluno(user.uid, info);
      // Atualiza o estado local
      final usuarioAtualizado = user.copyWith(alunoInfo: info);
      state = state.copyWith(usuario: usuarioAtualizado);
    } catch (e) {
      debugPrint("Erro ao salvar perfil: $e");
      throw Exception("Erro ao salvar perfil");
    }
  }

  // Definir Papel (Aluno/Prof/CA)
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
      
      // Recarrega o usuário completo
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

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      // Ignora se não estava logado com Google
    }
    // O listener _checarStatusAutenticacao vai mudar o estado para naoAutenticado
  }

  // Cria doc vazio no Firestore
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
  
  // Tradutor de Erros do Firebase
  String _traduzirErroAuth(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential': // Código novo
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'E-mail ou senha inválidos.';
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

final provedorNotificadorAutenticacao =
    StateNotifierProvider<NotificadorAutenticacao, EstadoAutenticacao>((ref) {
  return NotificadorAutenticacao(ref);
});