// lib/providers/provedor_aluno.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'provedor_tts.dart';
import '../services/servico_firestore.dart';
import 'provedor_autenticacao.dart';

// --- LÓGICA DE CADASTRO DE NFC DO ALUNO ---

/// Enum para os diferentes estados da tela de cadastro de NFC
enum StatusCadastroNFC { idle, scanning, success, error, unsupported }

/// Classe que armazena o estado da tela de cadastro de NFC
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
      erro: erro ?? this.erro
    );
  }
}

/// Notificador para gerenciar o estado do cadastro de NFC
class NotificadorCadastroNFC extends StateNotifier<EstadoCadastroNFC> {
  final Ref _ref;
  NotificadorCadastroNFC(this._ref) : super(EstadoCadastroNFC());
  
  /// Inicia a varredura por um cartão NFC
  Future<void> iniciarLeitura() async {
    NFCAvailability availability = await FlutterNfcKit.nfcAvailability;
    if (availability != NFCAvailability.available) {
      state = state.copyWith(status: StatusCadastroNFC.unsupported, erro: 'NFC não disponível neste dispositivo.');
      return;
    }

    state = state.copyWith(status: StatusCadastroNFC.scanning, erro: null, uid: null);
    
    NFCTag? tag;
    try {
      tag = await FlutterNfcKit.poll(
          timeout: const Duration(seconds: 20),
          readIso14443A: true,
          readIso14443B: true,
          readIso15693: true,
        );
        
      HapticFeedback.mediumImpact(); 
      final uid = tag.id.replaceAll(' ', ':').toUpperCase(); 

      if (uid.isNotEmpty) {
        _ref.read(ttsProvider).speak("Cartão lido com sucesso.");
        state = state.copyWith(status: StatusCadastroNFC.success, uid: uid);
      } else {
        _ref.read(ttsProvider).speak("Erro na leitura, tente novamente.");
        state = state.copyWith(status: StatusCadastroNFC.error, erro: 'Não foi possível ler o UID do cartão.');
      }
    } catch (e) {
        if (e.toString().contains("unavailable")) {
          state = state.copyWith(status: StatusCadastroNFC.unsupported, erro: 'NFC indisponível. Verifique as configurações.');
        } else if (e.toString().contains("timeout")) {
          state = state.copyWith(status: StatusCadastroNFC.idle, erro: 'Tempo de leitura esgotado.');
        } else {
          state = state.copyWith(status: StatusCadastroNFC.error, erro: 'Erro ao processar: $e');
          _ref.read(ttsProvider).speak("Erro ao processar.");
        }
    } finally {
        await FlutterNfcKit.finish();
    }
  }

  /// Salva o UID do cartão lido no perfil do usuário no Firebase
  Future<void> salvarCartao(String uidNfc) async {
    final usuarioAtual = _ref.read(provedorNotificadorAutenticacao).usuario;
    if (usuarioAtual == null) return; 

    final servico = _ref.read(servicoFirestoreProvider);
    
    try {
      // 1. Salva no banco
      await servico.salvarCartaoNFC(usuarioAtual.uid, uidNfc);
      
      // 2. Cria uma cópia local atualizada do usuário
      final usuarioAtualizado = usuarioAtual.copyWith(nfcCardId: uidNfc);

      // 3. Atualiza o estado de autenticação global com o novo usuário
      _ref.read(provedorNotificadorAutenticacao.notifier).state = 
          _ref.read(provedorNotificadorAutenticacao).copyWith(
            usuario: usuarioAtualizado
          );
      
      _ref.read(ttsProvider).speak("Cartão salvo com sucesso.");
      
    } catch (e) {
      debugPrint("Erro ao salvar cartão: $e");
       _ref.read(ttsProvider).speak("Erro ao salvar o cartão.");
    }
  }

  /// Reseta o estado do provedor para o inicial
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

/// O provedor que a tela [TelaCadastroNFC] vai usar
final provedorCadastroNFC =
    StateNotifierProvider<NotificadorCadastroNFC, EstadoCadastroNFC>(
  (ref) => NotificadorCadastroNFC(ref),
);