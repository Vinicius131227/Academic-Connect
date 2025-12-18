import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'provedor_tts.dart';
import '../services/servico_firestore.dart';
import 'provedor_autenticacao.dart';

// --- LÓGICA DE CADASTRO DE NFC DO ALUNO ---

enum StatusCadastroNFC { idle, scanning, success, error, unsupported }

class EstadoCadastroNFC {
  final StatusCadastroNFC status;
  final String? uid;
  final String? erro;

  EstadoCadastroNFC({
    this.status = StatusCadastroNFC.idle, 
    this.uid, 
    this.erro
  });

  EstadoCadastroNFC copyWith({
    StatusCadastroNFC? status, 
    String? uid, 
    String? erro
  }) {
    return EstadoCadastroNFC(
      status: status ?? this.status, 
      uid: uid ?? this.uid, 
      erro: erro 
    );
  }
}

class NotificadorCadastroNFC extends StateNotifier<EstadoCadastroNFC> {
  final Ref _ref;
  NotificadorCadastroNFC(this._ref) : super(EstadoCadastroNFC());
  
  /// Inicia a varredura por um cartão NFC
  Future<void> iniciarLeitura() async {
    // 1. Verifica disponibilidade
    try {
      NFCAvailability availability = await FlutterNfcKit.nfcAvailability;
      if (availability != NFCAvailability.available) {
        state = state.copyWith(status: StatusCadastroNFC.unsupported, erro: 'NFC não disponível.');
        return;
      }
    } catch(e) {
       state = state.copyWith(status: StatusCadastroNFC.unsupported, erro: 'Erro ao verificar NFC: $e');
       return;
    }

    state = state.copyWith(status: StatusCadastroNFC.scanning, erro: null, uid: null);
    
    NFCTag? tag;
    try {
      // 2. Aguarda o Cartão
      tag = await FlutterNfcKit.poll(
          timeout: const Duration(seconds: 20),
          readIso14443A: true,
          readIso14443B: true,
          readIso15693: true,
        );
        
      HapticFeedback.mediumImpact(); 
      final uidLido = tag.id.replaceAll(' ', ':').toUpperCase(); 

      if (uidLido.isNotEmpty) {
        await _validarDuplicidadeImediata(uidLido);
      } else {
        _ref.read(ttsProvider).speak("Erro na leitura.");
        state = state.copyWith(status: StatusCadastroNFC.error, erro: 'Não foi possível ler o UID.');
      }
    } catch (e) {
        if (e.toString().contains("unavailable")) {
          state = state.copyWith(status: StatusCadastroNFC.unsupported, erro: 'NFC indisponível.');
        } else if (e.toString().contains("timeout")) {
          state = state.copyWith(status: StatusCadastroNFC.idle, erro: 'Tempo esgotado.');
        } else {
          state = state.copyWith(status: StatusCadastroNFC.error, erro: 'Erro: $e');
          _ref.read(ttsProvider).speak("Erro ao processar.");
        }
    } finally {
        await FlutterNfcKit.finish().catchError((_){});
    }
  }

  /// Verifica no banco SE O CARTÃO JÁ EXISTE antes de deixar o usuário prosseguir
  Future<void> _validarDuplicidadeImediata(String uidLido) async {
    try {
      final servico = _ref.read(servicoFirestoreProvider);
      final usuarioAtual = _ref.read(provedorNotificadorAutenticacao).usuario;
      
      // Busca se alguém tem esse cartão
      final usuarioDono = await servico.getAlunoPorNFC(uidLido);

      // Se achou alguém E não sou eu mesmo
      if (usuarioDono != null && usuarioDono.uid != usuarioAtual?.uid) {
         // ERRO: DUPLICADO
         String msgErro = "Este cartão já pertence a outra pessoa.";
         
         // Tenta pegar o nome para ser mais específico
         if (usuarioDono.alunoInfo != null) {
           msgErro = "Cartão já cadastrado para ${usuarioDono.alunoInfo!.nomeCompleto}.";
         }
         
         _ref.read(ttsProvider).speak("Erro. Cartão repetido."); // Fala o erro
         
         state = state.copyWith(
           status: StatusCadastroNFC.error, 
           uid: uidLido,
           erro: msgErro
         );
      } else {
         // SUCESSO: Cartão livre ou é meu mesmo
         _ref.read(ttsProvider).speak("Cartão lido com sucesso.");
         state = state.copyWith(status: StatusCadastroNFC.success, uid: uidLido);
      }
    } catch (e) {
      // Erro de conexão ou outro
      state = state.copyWith(status: StatusCadastroNFC.error, erro: "Erro ao validar cartão: $e");
    }
  }

  /// Salva efetivamente (agora é seguro pois já validamos antes)
  Future<void> salvarCartao(String uidNfc) async {
    final usuarioAtual = _ref.read(provedorNotificadorAutenticacao).usuario;
    if (usuarioAtual == null) return; 

    final servico = _ref.read(servicoFirestoreProvider);
    
    try {
      await servico.salvarCartaoNFC(usuarioAtual.uid, uidNfc);
      
      final usuarioAtualizado = usuarioAtual.copyWith(nfcCardId: uidNfc);
      _ref.read(provedorNotificadorAutenticacao.notifier).state = 
          _ref.read(provedorNotificadorAutenticacao).copyWith(usuario: usuarioAtualizado);
      
      _ref.read(ttsProvider).speak("Salvo com sucesso.");
      
    } catch (e) {
      debugPrint("Erro ao salvar: $e");
      _ref.read(ttsProvider).speak("Erro ao salvar.");
      state = EstadoCadastroNFC(
        status: StatusCadastroNFC.error,
        uid: uidNfc,
        erro: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void reset() {
    FlutterNfcKit.finish().catchError((_) {});
    state = EstadoCadastroNFC();
  }
  
  @override
  void dispose() {
    FlutterNfcKit.finish().catchError((e) {});
    super.dispose();
  }
}

final provedorCadastroNFC =
    StateNotifierProvider<NotificadorCadastroNFC, EstadoCadastroNFC>(
  (ref) => NotificadorCadastroNFC(ref),
);