// lib/providers/provedor_autenticacao.dart
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
      erro: erro ?? this.erro,
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

  Future<void> _checarStatusAutenticacao() async {
    await Future.delayed(const Duration(seconds: 1)); 
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        final usuarioApp =
            await _ref.read(servicoFirestoreProvider).getUsuario(user.uid);

        if (usuarioApp != null) {
          state = EstadoAutenticacao(
            status: StatusAutenticacao.autenticado,
            usuario: usuarioApp,
          );
        } else {
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
        state = EstadoAutenticacao(status: StatusAutenticacao.naoAutenticado);
      }
    });
  }

  Future<void> login(String email, String password) async {
    try {
      state = state.copyWith(erro: null, carregando: true);
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(carregando: false, erro: _traduzirErroAuth(e.code));
    } catch (e) {
      state = state.copyWith(carregando: false, erro: 'Um erro inesperado ocorreu.');
    }
  }

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
      throw Exception(_traduzirErroAuth(e.code));
    } catch (e) {
      state = state.copyWith(carregando: false, erro: 'Um erro inesperado ocorreu.');
      throw Exception('Um erro inesperado ocorreu.');
    }
  }
  
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
            ra: identificacao, // Pode ser vazio
            curso: '',
            cr: 0.0,
            status: '',
          ),
          nfcCardId: null,
          tipoIdentificacao: tipoIdentificacao,
        );

        await _ref.read(servicoFirestoreProvider).criarDocumentoUsuario(novoUsuario);
      }
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(carregando: false, erro: _traduzirErroAuth(e.code));
      throw Exception(_traduzirErroAuth(e.code));
    } catch (e) {
      state = state.copyWith(carregando: false, erro: 'Um erro inesperado ocorreu.');
      throw Exception('Um erro inesperado ocorreu.');
    }
  }

  Future<void> loginComGoogle() async {
    try {
      state = state.copyWith(erro: null, carregando: true);
      UserCredential? userCredential;
      
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(provider);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) { 
          state = state.copyWith(carregando: false);
          return;
        }
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        if (googleAuth.idToken == null) {
          state = state.copyWith(
              carregando: false,
              erro: "Falha ao obter credenciais do Google.");
          return;
        }
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      if (userCredential.user != null) {
        final user = userCredential.user!;
        final servico = _ref.read(servicoFirestoreProvider);
        final usuarioExistente = await servico.getUsuario(user.uid);
        
        if (usuarioExistente == null) {
          await _criarDocumentoUsuarioPadrao(
            uid: user.uid,
            email: user.email ?? '',
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(carregando: false, erro: _traduzirErroAuth(e.code));
    } catch (e) {
      state = state.copyWith(
          carregando: false, erro: 'Erro no login com Google: ${e.toString()}');
    }
  }

  Future<void> salvarPerfilAluno(AlunoInfo info) async {
    final user = state.usuario;
    if (user == null) return;
    
    try {
      await _ref.read(servicoFirestoreProvider).salvarPerfilAluno(user.uid, info);
      final usuarioAtualizado = user.copyWith(alunoInfo: info);
      state = state.copyWith(usuario: usuarioAtualizado);
    } catch (e) {
      debugPrint("Erro ao salvar perfil: $e");
      throw Exception("Erro ao salvar perfil");
    }
  }

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

  Future<void> logout() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }

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
      papel: '', 
      alunoInfo: info, 
      nfcCardId: null,
      tipoIdentificacao: null,
    );
    
    await _ref.read(servicoFirestoreProvider).criarDocumentoUsuario(novoUsuario);
    return novoUsuario;
  }
  
  String _traduzirErroAuth(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'E-mail ou senha inválidos.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'weak-password':
        return 'A senha é muito fraca (mínimo 6 caracteres).';
      case 'invalid-email':
        return 'O formato do e-mail é inválido.';
      default:
        debugPrint('Erro Auth não traduzido: $code');
        return 'Erro de autenticação. Tente novamente.';
    }
  }
}

final provedorNotificadorAutenticacao =
    StateNotifierProvider<NotificadorAutenticacao, EstadoAutenticacao>((ref) {
  return NotificadorAutenticacao(ref);
});