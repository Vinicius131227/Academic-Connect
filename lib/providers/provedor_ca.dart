// lib/providers/provedor_ca.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart'; // Hardware NFC

// Importações Locais
import '../models/evento_ca.dart';
import '../services/servico_firestore.dart';
import 'provedor_tts.dart'; // Feedback de voz
import 'provedor_autenticacao.dart'; // Usuário logado

// ===========================================================================
// 1. LISTA DE LINKS ÚTEIS
// ===========================================================================

/// Provedor estático que retorna uma lista de links importantes para os alunos.
/// Usado na tela inicial do C.A. e Aluno.
final provedorLinksUteis = Provider<List<Map<String, String>>>((ref) {
  return [
    {'titulo': 'Biblioteca (Pergamum)', 'url': 'https://pergamum.ufscar.br/'},
    {'titulo': 'Moodle (Plataforma de Aulas)', 'url': 'https://moodle.ufscar.br/'},
    {'titulo': 'Sistema de Matrícula (ProGrad)', 'url': 'https://www.prograd.ufscar.br/'},
  ];
});


// ===========================================================================
// 2. LÓGICA DE CRIAÇÃO DE EVENTOS
// ===========================================================================

/// Notificador responsável por criar novos eventos no banco de dados.
class EventosCaNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  
  EventosCaNotifier(this._ref) : super(const AsyncValue.data(null));

  /// Método para adicionar um novo evento.
  /// Recebe os dados da tela, cria o objeto e envia para o Firestore.
  Future<bool> adicionarEvento({
    required String nome,
    required DateTime data,
    required String local,
    required int totalParticipantes,
  }) async {
    // Inicia estado de carregamento
    state = const AsyncValue.loading();
    
    // Pega o ID do usuário logado (organizador)
    final uid = _ref.read(provedorNotificadorAutenticacao).usuario?.uid;
    
    if (uid == null) {
      state = AsyncValue.error('Usuário não autenticado', StackTrace.current);
      return false;
    }

    // Cria o objeto EventoCA
    final evento = EventoCA(
      id: '', // ID vazio, será gerado pelo Firestore
      nome: nome,
      data: data,
      local: local,
      totalParticipantes: totalParticipantes,
      organizadorId: uid,
      participantesInscritos: [], // Lista começa vazia
    );

    try {
      // Chama o serviço para salvar
      await _ref.read(servicoFirestoreProvider).adicionarEvento(evento);
      state = const AsyncValue.data(null); // Sucesso
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st); // Erro
      return false;
    }
  }
}

/// Provedor global para acessar a lógica de criação de eventos.
final provedorEventosCA =
    StateNotifierProvider<EventosCaNotifier, AsyncValue<void>>((ref) {
  return EventosCaNotifier(ref);
});


// ===========================================================================
// 3. LÓGICA DE PRESENÇA EM EVENTOS (NFC)
// ===========================================================================

enum StatusNFC { pausado, lendo, indisponivel, erro }

/// Modelo local para exibir na lista de presença em tempo real.
class AlunoPresenteNFC {
  final String uid; // ID do usuário no Firebase
  final String nome;
  final String hora; // Hora da leitura
  AlunoPresenteNFC({required this.uid, required this.nome, required this.hora});
}

/// Estado da tela de leitura NFC de Eventos.
class EstadoPresencaNFC {
  final StatusNFC status;
  final List<AlunoPresenteNFC> presentes; // Lista acumulada
  final String? ultimoAluno; // Nome do último lido (para feedback visual)
  final String? erro;
  final String? ultimoErroScan;
  
  EstadoPresencaNFC({
    this.status = StatusNFC.pausado, 
    this.presentes = const [], 
    this.ultimoAluno, 
    this.erro, 
    this.ultimoErroScan
  });
  
  EstadoPresencaNFC copyWith({
    StatusNFC? status, 
    List<AlunoPresenteNFC>? presentes, 
    String? ultimoAluno, 
    String? erro, 
    String? ultimoErroScan, 
    bool limparUltimoAluno = false, 
    bool limparErro = false, 
    bool limparUltimoErroScan = false
  }) {
    return EstadoPresencaNFC(
      status: status ?? this.status, 
      presentes: presentes ?? this.presentes, 
      ultimoAluno: limparUltimoAluno ? null : ultimoAluno ?? this.ultimoAluno, 
      erro: limparErro ? null : erro ?? this.erro, 
      ultimoErroScan: limparUltimoErroScan ? null : ultimoErroScan ?? this.ultimoErroScan
    );
  }
}

/// Gerencia a leitura NFC especificamente para Eventos.
class NotificadorPresencaEventoNFC extends StateNotifier<EstadoPresencaNFC> {
  final Ref _ref;
  bool _isPolling = false; // Controla se o hardware está ativo

  NotificadorPresencaEventoNFC(this._ref) : super(EstadoPresencaNFC());

  /// Inicia o loop de leitura do hardware.
  Future<void> iniciarLeitura(String eventoId) async {
    if (_isPolling || state.status == StatusNFC.lendo) return; 
    _isPolling = true;

    // 1. Verifica disponibilidade
    try {
      NFCAvailability availability = await FlutterNfcKit.nfcAvailability;
      if (availability != NFCAvailability.available) {
        state = state.copyWith(status: StatusNFC.indisponivel, erro: 'NFC não está disponível.');
        _isPolling = false;
        return;
      }
    } catch(e) {
        // Ignora em emulador
    }

    state = state.copyWith(status: StatusNFC.lendo, limparErro: true, limparUltimoAluno: true, limparUltimoErroScan: true);
    
    // Feedback de voz inicial
    _ref.read(ttsProvider).speak("Modo de leitura de evento iniciado.");

    // 2. Loop de leitura
    while (state.status == StatusNFC.lendo) {
      try {
        // Aguarda cartão (10s timeout)
        NFCTag tag = await FlutterNfcKit.poll(
          timeout: const Duration(seconds: 10),
          readIso14443A: true, readIso14443B: true, readIso15693: true,
        );
        
        // Vibração ao ler
        HapticFeedback.mediumImpact();
        
        // Formata ID
        String uidNfc = tag.id.replaceAll(' ', ':').toUpperCase();
        
        if (uidNfc.isEmpty) {
          _feedbackError("Erro na leitura.");
          continue;
        }
        
        // Busca aluno no banco
        final servico = _ref.read(servicoFirestoreProvider);
        final aluno = await servico.getAlunoPorNFC(uidNfc);
        final hora = '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';

        if (aluno != null && aluno.alunoInfo != null) {
          final nomeAluno = aluno.alunoInfo!.nomeCompleto;
          
          // Verifica duplicidade local
          if (state.presentes.any((a) => a.uid == aluno.uid)) {
            _feedbackError("$nomeAluno já registrou presença.");
          } else {
            _feedbackSucesso(aluno.uid, nomeAluno, hora);
          }
        } else {
          _feedbackError("Cartão não cadastrado.");
        }
        
      } catch (e) {
        // Tratamento de erros comuns de hardware
        if (e.toString().contains("timeout")) {
          debugPrint("Timeout do poll, continuando a ler...");
        } else if (e.toString().contains("unavailable")) {
          state = state.copyWith(status: StatusNFC.indisponivel, erro: 'NFC foi desligado.');
          break;
        } else {
          debugPrint("Leitura interrompida: $e");
          // break; // Opcional: parar ou continuar tentando
        }
      }
      // Pausa para não travar a UI
      await Future.delayed(const Duration(milliseconds: 500));
    }
    _isPolling = false;
    await FlutterNfcKit.finish();
    debugPrint("Sessão de leitura finalizada.");
  }
  
  // Feedback de erro (Voz + Estado)
  void _feedbackError(String mensagem) {
    _ref.read(ttsProvider).speak(mensagem);
    state = state.copyWith(ultimoErroScan: mensagem);
    _limparPopups();
  }
  
  // Feedback de sucesso (Voz + Adiciona na lista)
  void _feedbackSucesso(String uid, String nomeAluno, String hora) {
    _ref.read(ttsProvider).speak("Presença de $nomeAluno confirmada.");
    final novoPresente = AlunoPresenteNFC(uid: uid, nome: nomeAluno, hora: hora);
    state = state.copyWith(
      presentes: [...state.presentes, novoPresente],
      ultimoAluno: 'Presença de $nomeAluno confirmada',
      limparErro: true,
    );
    _limparPopups();
  }

  // Limpa mensagens da tela após 2s
  void _limparPopups() {
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (state.status == StatusNFC.lendo) {
        state = state.copyWith(limparUltimoAluno: true, limparUltimoErroScan: true);
      }
    });
  }
  
  void pausarLeitura() {
    state = state.copyWith(status: StatusNFC.pausado, limparErro: true, limparUltimoErroScan: true);
  }

  /// Salva a lista de UIDs de presença no documento do evento no Firebase.
  Future<void> salvarChamadaEvento(String eventoId) async {
    final presentesUids = state.presentes.map((a) => a.uid).toList();
    
    if (presentesUids.isEmpty) {
      throw Exception("Nenhum participante presente para salvar.");
    }

    await _ref.read(servicoFirestoreProvider).salvarPresencaEvento(
          eventoId,
          presentesUids,
        );
    
    reset(); // Limpa a tela
  }
  
  void reset() {
    pausarLeitura();
    state = EstadoPresencaNFC();
  }
  
  @override
  void dispose() {
    FlutterNfcKit.finish().catchError((e) {});
    super.dispose();
  }
}

/// Provedor global para a tela de Presença em Eventos.
final provedorPresencaEventoNFC =
    StateNotifierProvider.autoDispose<NotificadorPresencaEventoNFC, EstadoPresencaNFC>(
  (ref) => NotificadorPresencaEventoNFC(ref),
);