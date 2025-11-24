import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import '../models/evento_ca.dart';
import '../models/participante_evento.dart';
import '../services/servico_firestore.dart';
import 'provedor_tts.dart';
import 'provedor_autenticacao.dart';

// --- Provedor para Links Úteis (Mantido) ---
final provedorLinksUteis = Provider<List<Map<String, String>>>((ref) {
  return [
    {'titulo': 'Biblioteca (Pergamum)', 'url': 'https://pergamum.ufscar.br/'},
    {'titulo': 'Moodle (Plataforma de Aulas)', 'url': 'https://moodle.ufscar.br/'},
    {'titulo': 'Sistema de Matrícula (ProGrad)', 'url': 'https://www.prograd.ufscar.br/'},
  ];
});

// --- NOTIFICADOR PARA CRIAR EVENTO ---
class EventosCaNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  EventosCaNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> adicionarEvento({
    required String nome,
    required DateTime data,
    required String local,
    required int totalParticipantes,
  }) async {
    state = const AsyncValue.loading();
    
    final uid = _ref.read(provedorNotificadorAutenticacao).usuario?.uid;
    if (uid == null) {
      state = AsyncValue.error('Usuário não autenticado', StackTrace.current);
      return false;
    }

    final evento = EventoCA(
      id: '', // Será gerado pelo Firestore
      nome: nome,
      data: data,
      local: local,
      totalParticipantes: totalParticipantes,
      organizadorId: uid,
      participantesInscritos: [], // Começa vazio
    );

    try {
      await _ref.read(servicoFirestoreProvider).adicionarEvento(evento);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Provedor para o Notifier (usado para ADICIONAR eventos)
final provedorEventosCA =
    StateNotifierProvider<EventosCaNotifier, AsyncValue<void>>((ref) {
  return EventosCaNotifier(ref);
});


// --- NOTIFICADOR DE PRESENÇA (C.A.) ---
enum StatusNFC { pausado, lendo, indisponivel, erro }

class AlunoPresenteNFC {
  final String uid; // Armazena o UID do Firebase
  final String nome;
  final String hora;
  AlunoPresenteNFC({required this.uid, required this.nome, required this.hora});
}

class EstadoPresencaNFC {
  final StatusNFC status;
  final List<AlunoPresenteNFC> presentes;
  final String? ultimoAluno;
  final String? erro;
  final String? ultimoErroScan;
  EstadoPresencaNFC({this.status = StatusNFC.pausado, this.presentes = const [], this.ultimoAluno, this.erro, this.ultimoErroScan});
  
  EstadoPresencaNFC copyWith({StatusNFC? status, List<AlunoPresenteNFC>? presentes, String? ultimoAluno, String? erro, String? ultimoErroScan, bool limparUltimoAluno = false, bool limparErro = false, bool limparUltimoErroScan = false}) {
    return EstadoPresencaNFC(status: status ?? this.status, presentes: presentes ?? this.presentes, ultimoAluno: limparUltimoAluno ? null : ultimoAluno ?? this.ultimoAluno, erro: limparErro ? null : erro ?? this.erro, ultimoErroScan: limparUltimoErroScan ? null : ultimoErroScan ?? this.ultimoErroScan);
  }
}

class NotificadorPresencaEventoNFC extends StateNotifier<EstadoPresencaNFC> {
  final Ref _ref;
  bool _isPolling = false; 

  NotificadorPresencaEventoNFC(this._ref) : super(EstadoPresencaNFC());

  Future<void> iniciarLeitura(String eventoId) async {
    if (_isPolling || state.status == StatusNFC.lendo) return; 
    _isPolling = true;

    NFCAvailability availability = await FlutterNfcKit.nfcAvailability;
    if (availability != NFCAvailability.available) {
      state = state.copyWith(status: StatusNFC.indisponivel, erro: 'NFC não está disponível.');
      _isPolling = false;
      return;
    }

    state = state.copyWith(status: StatusNFC.lendo, limparErro: true, limparUltimoAluno: true, limparUltimoErroScan: true);
    _ref.read(ttsProvider).speak("Modo de leitura de evento iniciado.");

    while (state.status == StatusNFC.lendo) {
      try {
        NFCTag tag = await FlutterNfcKit.poll(
          timeout: const Duration(seconds: 10),
          readIso14443A: true, readIso14443B: true, readIso15693: true,
        );
        HapticFeedback.mediumImpact();
        String uidNfc = tag.id.replaceAll(' ', ':').toUpperCase();
        if (uidNfc.isEmpty) {
          _feedbackError("Erro na leitura.");
          continue;
        }
        
        final servico = _ref.read(servicoFirestoreProvider);
        final aluno = await servico.getAlunoPorNFC(uidNfc);
        final hora = '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';

        if (aluno != null && aluno.alunoInfo != null) {
          final nomeAluno = aluno.alunoInfo!.nomeCompleto;
          if (state.presentes.any((a) => a.uid == aluno.uid)) {
            _feedbackError("$nomeAluno já registrou presença.");
          } else {
            _feedbackSucesso(aluno.uid, nomeAluno, hora);
          }
        } else {
          _feedbackError("Cartão não cadastrado.");
        }
        
      } catch (e) {
        if (e.toString().contains("timeout")) {
          debugPrint("Timeout do poll, continuando a ler...");
        } else if (e.toString().contains("unavailable")) {
          state = state.copyWith(status: StatusNFC.indisponivel, erro: 'NFC foi desligado.');
          break;
        } else {
          debugPrint("Leitura interrompida: $e");
          break;
        }
      }
    }
    _isPolling = false;
    await FlutterNfcKit.finish();
    debugPrint("Sessão de leitura finalizada.");
  }
  
  void _feedbackError(String mensagem) {
    _ref.read(ttsProvider).speak(mensagem);
    state = state.copyWith(ultimoErroScan: mensagem);
    _limparPopups();
  }
  
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

  /// Salva a lista de UIDs de presença no documento do evento
  Future<void> salvarChamadaEvento(String eventoId) async {
    final presentesUids = state.presentes.map((a) => a.uid).toList();
    
    if (presentesUids.isEmpty) {
      throw Exception("Nenhum participante presente para salvar.");
    }

    await _ref.read(servicoFirestoreProvider).salvarPresencaEvento(
          eventoId,
          presentesUids,
        );
    
    reset();
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

final provedorPresencaEventoNFC =
    StateNotifierProvider.autoDispose<NotificadorPresencaEventoNFC, EstadoPresencaNFC>(
  (ref) => NotificadorPresencaEventoNFC(ref),
);