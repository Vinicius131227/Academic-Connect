// lib/providers/provedor_professor.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart'; 

// Importações internas
import '../models/turma_professor.dart';
import '../models/aluno_chamada.dart';
import '../services/servico_firestore.dart';
import 'provedor_tts.dart';

// =============================================================================
// 1. STREAMS (Listas em Tempo Real)
// =============================================================================

final provedorStreamTurmasProfessor = StreamProvider.autoDispose<List<TurmaProfessor>>((ref) {
  // Placeholder caso precise localmente
  return const Stream.empty(); 
});

// =============================================================================
// 2. LÓGICA DE PRÉ-CHAMADA (COM BLOQUEIO DE HORÁRIO)
// =============================================================================

class EstadoPreChamada {
  final bool podeChamar;
  final String? bloqueioMensagem;
  final bool podeFazerSegundaChamada; 
  final int creditos;

  EstadoPreChamada({this.podeChamar = false, this.bloqueioMensagem, this.podeFazerSegundaChamada = false, this.creditos = 0});
}

final provedorPreChamada = FutureProvider.family<EstadoPreChamada, TurmaProfessor>((ref, turma) async {
  // --- MODO LIVRE ATIVADO PARA TESTES ---
  return EstadoPreChamada(podeChamar: true, creditos: turma.creditos);

  /* LÓGICA ORIGINAL (COMENTADA PARA TESTE):
  if (!turma.estaNoHorarioDeAula()) {
    return EstadoPreChamada(
      podeChamar: false,
      bloqueioMensagem: "Fora do horário de aula.\n(${turma.horaInicio} - ${turma.horaFim})",
      creditos: turma.creditos
    );
  }
  return EstadoPreChamada(podeChamar: true, creditos: turma.creditos);
  */
});

// =============================================================================
// 3. CHAMADA MANUAL
// =============================================================================

enum StatusChamadaManual { ocioso, carregando, pronto, erro }

class EstadoChamadaManual {
  final List<AlunoChamada> alunos;
  final int totalAlunos;
  final StatusChamadaManual status; 
  
  EstadoChamadaManual({
    required this.alunos, 
    required this.totalAlunos,
    this.status = StatusChamadaManual.ocioso,
  });

  EstadoChamadaManual copyWith({List<AlunoChamada>? alunos, StatusChamadaManual? status}) {
    return EstadoChamadaManual(
      alunos: alunos ?? this.alunos,
      totalAlunos: alunos != null ? alunos.length : totalAlunos,
      status: status ?? this.status,
    );
  }
}

class NotificadorChamadaManual extends StateNotifier<EstadoChamadaManual> {
  final ServicoFirestore _servico;
  final String _turmaId;

  NotificadorChamadaManual(this._servico, this._turmaId) 
    : super(EstadoChamadaManual(alunos: [], totalAlunos: 0, status: StatusChamadaManual.ocioso)) {
      carregarAlunos();
  }

  Future<void> carregarAlunos() async {
    state = state.copyWith(status: StatusChamadaManual.carregando);
    try {
      final alunos = await _servico.getAlunosDaTurma(_turmaId);
      state = EstadoChamadaManual(
        alunos: alunos,
        totalAlunos: alunos.length,
        status: StatusChamadaManual.pronto,
      );
    } catch (e) {
      state = state.copyWith(status: StatusChamadaManual.erro);
      debugPrint("Erro ao carregar alunos: $e");
    }
  }
}

final provedorChamadaManual = StateNotifierProvider.autoDispose.family<NotificadorChamadaManual, EstadoChamadaManual, String>((ref, turmaId) {
    final servico = ref.watch(servicoFirestoreProvider);
    return NotificadorChamadaManual(servico, turmaId);
});

// =============================================================================
// 4. CHAMADA NFC (COM VALIDAÇÃO E TTS)
// =============================================================================
enum StatusCadastroNFC { idle, scanning, success, error }

class EstadoCadastroNFC {
  final StatusCadastroNFC status;
  final String? uid;
  final String? erro;
  
  EstadoCadastroNFC({this.status = StatusCadastroNFC.idle, this.uid, this.erro});

  EstadoCadastroNFC copyWith({StatusCadastroNFC? status, String? uid, String? erro}) {
    return EstadoCadastroNFC(
      status: status ?? this.status,
      uid: uid ?? this.uid,
      erro: erro ?? this.erro,
    );
  }
}

// Notificador Simples para Cadastro (usado na tela de cadastro manual)
class NotificadorCadastroNFC extends StateNotifier<EstadoCadastroNFC> {
  NotificadorCadastroNFC() : super(EstadoCadastroNFC());

  Future<void> iniciarLeitura() async {
    state = state.copyWith(status: StatusCadastroNFC.scanning, erro: null);
    try {
      NFCTag tag = await FlutterNfcKit.poll(timeout: const Duration(seconds: 10));
      String id = tag.id.replaceAll(' ', ':').toUpperCase();
      state = state.copyWith(status: StatusCadastroNFC.success, uid: id);
    } catch (e) {
      state = state.copyWith(status: StatusCadastroNFC.error, erro: e.toString());
    } finally {
      try { await FlutterNfcKit.finish(); } catch(_){}
    }
  }

  void pausarLeitura() {
    try { FlutterNfcKit.finish(); } catch(_){}
    state = state.copyWith(status: StatusCadastroNFC.idle);
  }

  void reset() => state = EstadoCadastroNFC();
}

final provedorCadastroNFC = StateNotifierProvider<NotificadorCadastroNFC, EstadoCadastroNFC>((ref) {
  return NotificadorCadastroNFC();
});

enum StatusNFC { pausado, lendo, indisponivel, erro }

class AlunoPresenteNFC {
  final String uid; 
  final String nome;
  final String hora;
  AlunoPresenteNFC({required this.uid, required this.nome, required this.hora});
}

class EstadoPresencaNFC {
  final StatusNFC status;
  final List<AlunoPresenteNFC> presentes;
  final String? ultimoErroScan;
  final String? ultimoAluno; 

  EstadoPresencaNFC({
    this.status = StatusNFC.pausado, 
    this.presentes = const [], 
    this.ultimoErroScan,
    this.ultimoAluno,
  });
  
  EstadoPresencaNFC copyWith({
    StatusNFC? status, 
    List<AlunoPresenteNFC>? presentes, 
    String? ultimoErroScan,
    String? ultimoAluno,
  }) {
    return EstadoPresencaNFC(
      status: status ?? this.status, 
      presentes: presentes ?? this.presentes, 
      ultimoErroScan: ultimoErroScan, 
      ultimoAluno: ultimoAluno ?? this.ultimoAluno,
    );
  }
}

class NotificadorPresencaNFC extends StateNotifier<EstadoPresencaNFC> {
  final Ref _ref;
  bool _isPolling = false;
  
  NotificadorPresencaNFC(this._ref) : super(EstadoPresencaNFC());
  
  Future<void> iniciarLeitura(String turmaId, List<String> alunosInscritosIds) async {
    if (_isPolling || state.status == StatusNFC.lendo) return; 
    _isPolling = true;
    
    try {
      NFCAvailability availability = await FlutterNfcKit.nfcAvailability;
      if (availability != NFCAvailability.available) {
        state = state.copyWith(status: StatusNFC.indisponivel, ultimoErroScan: 'NFC Desativado');
        _isPolling = false;
        return;
      }
    } catch(e) {
      state = state.copyWith(status: StatusNFC.indisponivel, ultimoErroScan: 'Erro: $e');
      _isPolling = false;
      return;
    }
    
    state = state.copyWith(status: StatusNFC.lendo, ultimoErroScan: null);
    _ref.read(ttsProvider).speak("Leitura iniciada.");

    while (state.status == StatusNFC.lendo) {
      try {
        NFCTag tag = await FlutterNfcKit.poll(timeout: const Duration(seconds: 5));
        String uidNfc = tag.id.replaceAll(' ', ':').toUpperCase();
        
        final servico = _ref.read(servicoFirestoreProvider);
        final aluno = await servico.getAlunoPorNFC(uidNfc);
        final hora = DateFormat('HH:mm').format(DateTime.now());

        if (aluno != null && aluno.alunoInfo != null) {
          final nome = aluno.alunoInfo!.nomeCompleto;
          
          if (!alunosInscritosIds.contains(aluno.uid)) {
             _ref.read(ttsProvider).speak("Erro. Aluno de outra turma.");
             state = state.copyWith(ultimoErroScan: "Aluno de outra turma: $nome");
          } 
          else if (state.presentes.any((a) => a.uid == aluno.uid)) {
             // Já leu, ignora
          } 
          else {
            _ref.read(ttsProvider).speak("Presença de $nome");
            
            // Salva no banco assim que lê
            await servico.salvarPresenca(
              turmaId, 
              'inicio', 
              [...state.presentes.map((a)=>a.uid), aluno.uid], // Lista atual + novo
              DateTime.now()
            );

            state = state.copyWith(
              presentes: [...state.presentes, AlunoPresenteNFC(uid: aluno.uid, nome: nome, hora: hora)],
              ultimoAluno: "$nome registrado!",
              ultimoErroScan: null 
            );
          }
        } else {
          _ref.read(ttsProvider).speak("Cartão não reconhecido.");
          state = state.copyWith(ultimoErroScan: "Cartão desconhecido ($uidNfc)");
        }
      } catch (e) {
        if (!e.toString().contains("timeout")) {
           debugPrint("Erro leitura NFC: $e");
        }
      }
      await Future.delayed(const Duration(milliseconds: 1000));
    }
    _isPolling = false;
    try { await FlutterNfcKit.finish(); } catch(_){}
  }

  void pausarLeitura() {
    state = state.copyWith(status: StatusNFC.pausado);
    try { FlutterNfcKit.finish(); } catch(_){}
  }

  Future<void> salvarChamadaNFC(String turmaId, String tipoChamada, DateTime dataChamada) async {
    final presentesUids = state.presentes.map((a) => a.uid).toList();
    await _ref.read(servicoFirestoreProvider).salvarPresenca(turmaId, tipoChamada, presentesUids, dataChamada);
    pausarLeitura();
    state = EstadoPresencaNFC();
  }
  
  void reset() {
    pausarLeitura();
    state = EstadoPresencaNFC();
  }
}

final provedorPresencaNFC = StateNotifierProvider.autoDispose<NotificadorPresencaNFC, EstadoPresencaNFC>((ref) => NotificadorPresencaNFC(ref));


// =============================================================================
// 5. LANÇAMENTO DE NOTAS
// =============================================================================

class NotasNotifier extends StateNotifier<Map<String, double?>> {
  final Ref _ref;
  NotasNotifier(this._ref) : super({}); 

  Future<void> carregarNotas(String turmaId, String avaliacao) async {
    try {
      final notasExistentes = await _ref.read(servicoFirestoreProvider).getNotasDaAvaliacao(turmaId, avaliacao);
      state = notasExistentes;
    } catch (e) {
      state = {};
      debugPrint("Erro notas: $e");
    }
  }
  
  void atualizarNota(String alunoId, double? nota) {
    state = {...state, alunoId: nota};
  }
  
  Future<void> salvarNotas(String turmaId, String avaliacaoNome) async {
    await _ref.read(servicoFirestoreProvider).salvarNotas(turmaId, avaliacaoNome, state);
  }
}

final provedorNotas = StateNotifierProvider<NotasNotifier, Map<String, double?>>((ref) {
  return NotasNotifier(ref);
});