// lib/providers/provedor_aluno.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart'; // Pacote oficial para NFC

// Importa serviços e outros provedores necessários
import 'provedor_tts.dart'; // Text-to-Speech (Voz)
import '../services/servico_firestore.dart'; // Banco de Dados
import 'provedor_autenticacao.dart'; // Usuário Logado

// ===========================================================================
// LÓGICA DE CADASTRO DE CARTÃO NFC (ALUNO)
// ===========================================================================

/// Enum que define os possíveis estados da tela de cadastro.
/// - [idle]: Tela parada, aguardando ação.
/// - [scanning]: Procurando cartão (radar ativo).
/// - [success]: Cartão lido com sucesso.
/// - [error]: Houve um problema na leitura.
/// - [unsupported]: O celular não tem NFC.
enum StatusCadastroNFC { idle, scanning, success, error, unsupported }

/// Classe imutável que guarda o estado atual da tela.
class EstadoCadastroNFC {
  final StatusCadastroNFC status;
  final String? uid; // O ID único do cartão lido (se houver)
  final String? erro; // Mensagem de erro (se houver)

  EstadoCadastroNFC({
    this.status = StatusCadastroNFC.idle, 
    this.uid, 
    this.erro
  });

  // Método auxiliar para criar uma cópia do estado com alterações
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

/// Notificador (Controller) que gerencia a lógica de negócio do cadastro NFC.
class NotificadorCadastroNFC extends StateNotifier<EstadoCadastroNFC> {
  final Ref _ref;
  
  NotificadorCadastroNFC(this._ref) : super(EstadoCadastroNFC());
  
  /// Inicia o processo de varredura (polling) do hardware NFC.
  ///
  /// 1. Verifica se o dispositivo tem NFC.
  /// 2. Ativa o modo de leitura.
  /// 3. Aguarda a aproximação de um cartão.
  /// 4. Lê o ID e atualiza o estado.
  Future<void> iniciarLeitura() async {
    // 1. Verifica disponibilidade
    try {
      NFCAvailability availability = await FlutterNfcKit.nfcAvailability;
      if (availability != NFCAvailability.available) {
        state = state.copyWith(
          status: StatusCadastroNFC.unsupported, 
          erro: 'NFC não disponível ou desativado neste dispositivo.'
        );
        return;
      }
    } catch (e) {
      // Emuladores geralmente não têm NFC, ignoramos o erro para permitir teste visual
      debugPrint("Erro ao verificar NFC (Provável Emulador): $e");
    }

    // 2. Muda estado para "Escaneando"
    state = state.copyWith(status: StatusCadastroNFC.scanning, erro: null, uid: null);
    
    NFCTag? tag;
    try {
      // 3. Inicia a busca (timeout de 20s para economizar bateria)
      tag = await FlutterNfcKit.poll(
          timeout: const Duration(seconds: 20),
          // Lê os padrões mais comuns de cartões (ISO 14443 e 15693)
          readIso14443A: true,
          readIso14443B: true,
          readIso15693: true,
      );
        
      // Feedback tátil (vibração) ao encontrar
      HapticFeedback.mediumImpact(); 
      
      // Formata o UID para ficar legível (Ex: AA:BB:CC:DD)
      final uid = tag.id.replaceAll(' ', ':').toUpperCase(); 

      if (uid.isNotEmpty) {
        _ref.read(ttsProvider).speak("Cartão lido com sucesso.");
        state = state.copyWith(status: StatusCadastroNFC.success, uid: uid);
      } else {
        _ref.read(ttsProvider).speak("Erro na leitura, tente novamente.");
        state = state.copyWith(status: StatusCadastroNFC.error, erro: 'Não foi possível ler o UID do cartão.');
      }
    } catch (e) {
        // Tratamento de erros específicos da biblioteca NFC
        if (e.toString().contains("unavailable")) {
          state = state.copyWith(status: StatusCadastroNFC.unsupported, erro: 'NFC indisponível. Verifique as configurações.');
        } else if (e.toString().contains("timeout")) {
          state = state.copyWith(status: StatusCadastroNFC.idle, erro: 'Tempo de leitura esgotado.');
        } else {
          state = state.copyWith(status: StatusCadastroNFC.error, erro: 'Erro ao processar: $e');
          _ref.read(ttsProvider).speak("Erro ao processar.");
        }
    } finally {
        // Sempre finaliza a sessão NFC para liberar o hardware
        await FlutterNfcKit.finish();
    }
  }

  /// Salva o UID do cartão lido no perfil do usuário logado no Firebase.
  Future<void> salvarCartao(String uidNfc) async {
    // Pega o usuário logado atual do provedor de autenticação
    final authState = _ref.read(provedorNotificadorAutenticacao);
    final usuarioAtual = authState.usuario;
    
    if (usuarioAtual == null) return; 

    final servico = _ref.read(servicoFirestoreProvider);
    
    try {
      // 1. Salva no banco de dados (Firestore)
      await servico.salvarCartaoNFC(usuarioAtual.uid, uidNfc);
      
      // 2. Cria uma cópia local atualizada do objeto usuário
      // Isso é necessário para a UI atualizar instantaneamente sem recarregar
      final usuarioAtualizado = usuarioAtual.copyWith(nfcCardId: uidNfc);

      // 3. Atualiza o estado global de autenticação
      // Isso avisa todo o app que o usuário agora tem um cartão vinculado
      _ref.read(provedorNotificadorAutenticacao.notifier).state = 
          authState.copyWith(usuario: usuarioAtualizado);
      
      _ref.read(ttsProvider).speak("Cartão salvo com sucesso.");
      
    } catch (e) {
      debugPrint("Erro ao salvar cartão: $e");
       _ref.read(ttsProvider).speak("Erro ao salvar o cartão.");
    }
  }

  /// Reseta o estado para o inicial (Idle), limpando erros e dados lidos.
  void reset() {
    FlutterNfcKit.finish().catchError((_) {});
    state = EstadoCadastroNFC();
  }
  
  @override
  void dispose() {
    // Garante que o NFC pare de buscar se a tela for fechada
    FlutterNfcKit.finish().catchError((e) {});
    super.dispose();
  }
}

/// O provedor global que a tela [TelaCadastroNFC] vai usar para escutar e agir.
final provedorCadastroNFC =
    StateNotifierProvider<NotificadorCadastroNFC, EstadoCadastroNFC>(
  (ref) => NotificadorCadastroNFC(ref),
);