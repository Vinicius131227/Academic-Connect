import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Importações de Modelos e Serviços
import '../models/usuario.dart';
import '../models/aluno_info.dart';
import '../services/servico_firestore.dart';

/// Estados possíveis da autenticação no aplicativo.
enum StatusAutenticacao { desconhecido, autenticado, naoAutenticado }

/// Classe imutável que guarda o estado atual da autenticação.
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
  }) {
    return EstadoAutenticacao(
      status: status ?? this.status,
      usuario: usuario ?? this.usuario,
      carregando: carregando ?? this.carregando,
      erro: erro, 
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

  /// Monitora o estado do usuário no Firebase (Persistência).
  Future<void> _checarStatusAutenticacao() async {
    await Future.delayed(const Duration(seconds: 1)); 
    _auth.authStateChanges().listen((User? user) async {
      if (user == null) {
        state = EstadoAutenticacao(status: StatusAutenticacao.naoAutenticado);
      } else {
        // Se o usuário já estiver autenticado no estado local, não faz nada para evitar rebuilds
        if (state.status != StatusAutenticacao.autenticado) {
           final usuarioApp = await _ref.read(servicoFirestoreProvider).getUsuario(user.uid);
           
           if (usuarioApp != null) {
             state = EstadoAutenticacao(
               status: StatusAutenticacao.autenticado, 
               usuario: usuarioApp
             );
           } else {
             // Caso de borda: Usuário no Auth mas sem doc no Firestore
             final novo = await _criarDocumentoUsuarioPadrao(uid: user.uid, email: user.email ?? '');
             state = EstadoAutenticacao(
               status: StatusAutenticacao.autenticado, 
               usuario: novo
             );
           }
        }
      }
    });
  }

  /// Login com E-mail e Senha (Com correção de Race Condition).
  Future<void> login(String email, String password) async {
    // Limpa erros e inicia loading
    state = state.copyWith(carregando: true, erro: null);
    
    try {
      // 1. Autentica no Firebase
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      if (credential.user != null) {
        // 2. Busca dados no Firestore IMEDIATAMENTE (Não espera o listener)
        final usuarioApp = await _ref.read(servicoFirestoreProvider).getUsuario(credential.user!.uid);
        
        // 3. Força o estado para AUTENTICADO agora mesmo
        // Isso garante que a tela de Login saiba que deu certo antes do stream atualizar
        if (usuarioApp != null) {
           state = EstadoAutenticacao(
             status: StatusAutenticacao.autenticado, 
             usuario: usuarioApp,
             carregando: false 
           );
        } else {
           final novo = await _criarDocumentoUsuarioPadrao(uid: credential.user!.uid, email: email);
           state = EstadoAutenticacao(
             status: StatusAutenticacao.autenticado, 
             usuario: novo,
             carregando: false
           );
        }
      }
    } on FirebaseAuthException catch (e) {
      // Atualiza estado com erro traduzido e para loading
      state = state.copyWith(carregando: false, erro: _traduzirErroAuth(e.code));
      throw e; 
    } catch (e) {
      state = state.copyWith(carregando: false, erro: 'Erro: $e');
      throw e;
    }
  }

  /// Cadastro de Aluno.
  Future<void> signUp({
    required String email, 
    required String password, 
    required String nomeCompleto, 
    required String ra, 
    required String curso, 
    required DateTime dataNascimento
  }) async {
    try {
      state = state.copyWith(erro: null, carregando: true);
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      if (cred.user != null) {
        final info = AlunoInfo(
          nomeCompleto: nomeCompleto, 
          ra: ra, 
          curso: curso, 
          dataNascimento: dataNascimento, 
          cr: 0.0, 
          status: 'Regular'
        );
        
        final novoUsuario = UsuarioApp(
          uid: cred.user!.uid, 
          email: email, 
          papel: 'aluno', 
          alunoInfo: info,
          nfcCardId: null,
          tipoIdentificacao: null
        );
        
        await _ref.read(servicoFirestoreProvider).criarDocumentoUsuario(novoUsuario);
        
        // Força estado autenticado
        state = EstadoAutenticacao(
          status: StatusAutenticacao.autenticado, 
          usuario: novoUsuario, 
          carregando: false
        );
      }
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(carregando: false, erro: _traduzirErroAuth(e.code));
      throw e;
    }
  }
  
  /// Cadastro de Professor ou C.A.
  Future<void> signUpComIdentificacao({
    required String email, 
    required String password, 
    required String papel, 
    required String nomeCompleto, 
    required String identificacao, 
    required String tipoIdentificacao
  }) async {
     try {
      state = state.copyWith(erro: null, carregando: true);
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      if (cred.user != null) {
        final novoUsuario = UsuarioApp(
          uid: cred.user!.uid, 
          email: email, 
          papel: papel, 
          alunoInfo: AlunoInfo(
            nomeCompleto: nomeCompleto, 
            ra: identificacao, // Usa campo RA para guardar a ID
            curso: '', 
            cr: 0.0, 
            status: '', 
            dataNascimento: DateTime.now()
          ), 
          tipoIdentificacao: tipoIdentificacao,
          nfcCardId: null
        );
        
        await _ref.read(servicoFirestoreProvider).criarDocumentoUsuario(novoUsuario);
        
        state = EstadoAutenticacao(
          status: StatusAutenticacao.autenticado, 
          usuario: novoUsuario, 
          carregando: false
        );
      }
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(carregando: false, erro: _traduzirErroAuth(e.code));
      throw e;
    }
  }

  /// Login com Google.
  Future<void> loginComGoogle() async {
    state = state.copyWith(carregando: true, erro: null);
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(googleProvider);
        if (userCredential.user != null) await _processarLoginSucesso(userCredential.user!);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        
        if (googleUser == null) {
           state = state.copyWith(carregando: false);
           return;
        }
        
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        final userCredential = await _auth.signInWithCredential(credential);
        if (userCredential.user != null) await _processarLoginSucesso(userCredential.user!);
      }
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(carregando: false, erro: _traduzirErroAuth(e.code));
    } catch (e) {
      state = state.copyWith(carregando: false, erro: 'Erro Google: $e');
      rethrow;
    }
  }
  
  Future<void> _processarLoginSucesso(User user) async {
     final servico = _ref.read(servicoFirestoreProvider);
     final usuarioExistente = await servico.getUsuario(user.uid);
     
     if (usuarioExistente != null) {
        state = EstadoAutenticacao(status: StatusAutenticacao.autenticado, usuario: usuarioExistente, carregando: false);
     } else {
        final novo = await _criarDocumentoUsuarioPadrao(uid: user.uid, email: user.email ?? '');
        state = EstadoAutenticacao(status: StatusAutenticacao.autenticado, usuario: novo, carregando: false);
     }
  }

  /// Atualiza dados do perfil.
  Future<void> salvarPerfilAluno(AlunoInfo info) async {
    final user = state.usuario;
    if (user == null) return;
    
    try {
      await _ref.read(servicoFirestoreProvider).salvarPerfilAluno(user.uid, info);
      state = state.copyWith(usuario: user.copyWith(alunoInfo: info));
    } catch (e) {
      throw Exception("Erro ao salvar perfil");
    }
  }

  /// Define o papel do usuário (Aluno, Prof, CA).
  Future<void> selecionarPapel(String papel, {String? tipoIdentificacao, String? numIdentificacao}) async {
    final user = state.usuario;
    if (user == null) return;
    
    try {
      await _ref.read(servicoFirestoreProvider).selecionarPapel(
        user.uid, 
        papel, 
        tipoIdentificacao: tipoIdentificacao
      );
      final updated = await _ref.read(servicoFirestoreProvider).getUsuario(user.uid);
      state = state.copyWith(usuario: updated);
    } catch (e) {
      state = state.copyWith(erro: 'Erro ao salvar papel: $e');
    }
  }
  
  /// Logout.
  Future<void> logout() async {
    await _auth.signOut();
    try { await GoogleSignIn().signOut(); } catch (_) {}
    state = EstadoAutenticacao(status: StatusAutenticacao.naoAutenticado);
  }

  /// Cria usuário padrão no banco se não existir.
  Future<UsuarioApp> _criarDocumentoUsuarioPadrao({required String uid, required String email}) async {
    final info = AlunoInfo(nomeCompleto: '', ra: '', curso: '', cr: 0.0, status: '', dataNascimento: null);
    final novoUsuario = UsuarioApp(uid: uid, email: email, papel: '', alunoInfo: info, nfcCardId: null, tipoIdentificacao: null);
    await _ref.read(servicoFirestoreProvider).criarDocumentoUsuario(novoUsuario);
    return novoUsuario;
  }

  /// Traduz códigos de erro do Firebase para mensagens amigáveis.
  String _traduzirErroAuth(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential': // Código novo do Firebase (2024)
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'E-mail ou senha incorretos.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'weak-password':
        return 'A senha é muito fraca.';
      case 'invalid-email':
        return 'O formato do e-mail é inválido.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      default:
        debugPrint('Erro Auth não traduzido: $code');
        return 'Erro de autenticação. Verifique seus dados.';
    }
  }
}

final provedorNotificadorAutenticacao = StateNotifierProvider<NotificadorAutenticacao, EstadoAutenticacao>((ref) {
  return NotificadorAutenticacao(ref);
});