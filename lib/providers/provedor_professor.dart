// lib/providers/provedor_professor.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart'; 
import 'package:intl/intl.dart';

import '../models/turma_professor.dart';
import '../models/aluno_chamada.dart';
import '../services/servico_firestore.dart';
import 'provedor_tts.dart';

// --- LÓGICA DE PRÉ-CHAMADA ---

class EstadoPreChamada {
  final bool podeChamar;
  final String? bloqueioMensagem;
  final bool podeFazerSegundaChamada; 
  final int creditos;

  EstadoPreChamada({this.podeChamar = false, this.bloqueioMensagem, this.podeFazerSegundaChamada = false, this.creditos = 0});
}

final provedorPreChamada = FutureProvider.family<EstadoPreChamada, TurmaProfessor>((ref, turma) async {
  return EstadoPreChamada(podeChamar: true, creditos: turma.creditos);
});

// --- LÓGICA DE CHAMADA MANUAL (COM ENUM) ---

enum StatusChamadaManual { ocioso, carregando, pronto, erro }

class EstadoChamadaManual {
  final List<AlunoChamada> alunos;
  final int totalAlunos;
  final StatusChamadaManual status; // VOLTOU!
  
  EstadoChamadaManual({
    required this.alunos, 
    required this.totalAlunos,
    this.status = StatusChamadaManual.ocioso, // Padrão
  });

  int get presentesCount => alunos.where((a) => a.isPresente).length;
  
  // Getter auxiliar para compatibilidade se alguma tela usar .carregando
  bool get carregando => status == StatusChamadaManual.carregando;

  EstadoChamadaManual copyWith({List<AlunoChamada>? alunos, StatusChamadaManual? status}) {
    return EstadoChamadaManual(
      alunos: alunos ?? this.alunos,
      totalAlunos: totalAlunos,
      status: status ?? this.status,
    );
  }
}

class NotificadorChamadaManual extends StateNotifier<EstadoChamadaManual> {
  final Ref _ref;
  final String _turmaId;

  NotificadorChamadaManual(this._ref, this._turmaId) 
    : super(EstadoChamadaManual(alunos: [], totalAlunos: 0, status: StatusChamadaManual.ocioso)) {
      _carregarAlunos();
  }

  Future<void> _carregarAlunos() async {
    state = state.copyWith(status: StatusChamadaManual.carregando);
    try {
      final servico = _ref.read(servicoFirestoreProvider);
      final alunos = await servico.getAlunosDaTurma(_turmaId);
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

  void toggleAluno(String alunoId) { 
    state = state.copyWith(
      alunos: [
        for (final aluno in state.alunos) 
          if (aluno.id == alunoId) 
            aluno.copyWith(isPresente: !aluno.isPresente) 
          else 
            aluno
      ]
    ); 
  }
  
  void toggleTodos() { 
    bool todosPresentes = state.presentesCount == state.alunos.length; 
    state = state.copyWith(
      alunos: [for (final aluno in state.alunos) aluno.copyWith(isPresente: !todosPresentes)]
    );
  }
  
  void limparTodos() { 
    state = state.copyWith(
      alunos: [for (final aluno in state.alunos) aluno.copyWith(isPresente: false)]
    );
  }

  Future<void> salvarChamada(String tipoChamada, DateTime dataChamada) async {
    final presentesUids = state.alunos.where((a) => a.isPresente).map((a) => a.id).toList();
    await _ref.read(servicoFirestoreProvider).salvarPresenca(_turmaId, tipoChamada, presentesUids, dataChamada);
  }
}

final provedorChamadaManual = StateNotifierProvider.autoDispose.family<
  NotificadorChamadaManual, EstadoChamadaManual, String
>(
  (ref, turmaId) => NotificadorChamadaManual(ref, turmaId)
);


// --- CHAMADA NFC ---

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
  
  EstadoPresencaNFC({
    this.status = StatusNFC.pausado, 
    this.presentes = const [], 
    this.ultimoErroScan
  });
  
  EstadoPresencaNFC copyWith({StatusNFC? status, List<AlunoPresenteNFC>? presentes, String? ultimoErroScan}) {
    return EstadoPresencaNFC(
      status: status ?? this.status, 
      presentes: presentes ?? this.presentes, 
      ultimoErroScan: ultimoErroScan
    );
  }
}

class NotificadorPresencaNFC extends StateNotifier<EstadoPresencaNFC> {
  final Ref _ref;
  bool _isPolling = false; 
  
  NotificadorPresencaNFC(this._ref) : super(EstadoPresencaNFC());
  
  Future<void> iniciarLeitura(String turmaId) async {
    if (_isPolling || state.status == StatusNFC.lendo) return; 
    _isPolling = true;
    
    try {
        NFCAvailability availability = await FlutterNfcKit.nfcAvailability;
        if (availability != NFCAvailability.available) {
          state = state.copyWith(status: StatusNFC.indisponivel, ultimoErroScan: 'NFC não disponível.');
          _isPolling = false;
          return;
        }
    } catch(e) {
        // Ignora erro em emulador
    }
    
    state = state.copyWith(status: StatusNFC.lendo, ultimoErroScan: null);
    _ref.read(ttsProvider).speak("Leitura iniciada.");

    while (state.status == StatusNFC.lendo) {
      try {
        NFCTag tag = await FlutterNfcKit.poll(timeout: const Duration(seconds: 10));
        String uidNfc = tag.id.replaceAll(' ', ':').toUpperCase();
        
        final aluno = await _ref.read(servicoFirestoreProvider).getAlunoPorNFC(uidNfc);
        final hora = DateFormat('HH:mm').format(DateTime.now());

        if (aluno != null && aluno.alunoInfo != null) {
          final nome = aluno.alunoInfo!.nomeCompleto;
          if (state.presentes.any((a) => a.uid == aluno.uid)) {
            _ref.read(ttsProvider).speak("$nome já registrado.");
          } else {
            _ref.read(ttsProvider).speak("Presença de $nome confirmada.");
            state = state.copyWith(
              presentes: [...state.presentes, AlunoPresenteNFC(uid: aluno.uid, nome: nome, hora: hora)]
            );
          }
        } else {
          _ref.read(ttsProvider).speak("Cartão não cadastrado.");
          state = state.copyWith(ultimoErroScan: "Cartão não reconhecido");
        }
      } catch (e) {
        if (!e.toString().contains("timeout")) {
           // Erro real
        }
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    _isPolling = false;
    await FlutterNfcKit.finish();
  }

  void pausarLeitura() {
    state = state.copyWith(status: StatusNFC.pausado);
  }

  Future<void> salvarChamadaNFC(String turmaId, String tipoChamada, DateTime dataChamada) async {
    final presentesUids = state.presentes.map((a) => a.uid).toList();
    if (presentesUids.isEmpty) throw Exception("Nenhum aluno presente.");
    
    await _ref.read(servicoFirestoreProvider).salvarPresenca(turmaId, tipoChamada, presentesUids, dataChamada);
    pausarLeitura();
    state = EstadoPresencaNFC();
  }
}

final provedorPresencaNFC = StateNotifierProvider.autoDispose<NotificadorPresencaNFC, EstadoPresencaNFC>((ref) => NotificadorPresencaNFC(ref));

// --- NOTAS ---

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

// --- CHAMADA DIÁRIA ---

class ChamadaDiariaNotifier extends StateNotifier<Set<String>> {
  ChamadaDiariaNotifier() : super({});
  bool contains(String id) => state.contains(id);
  void iniciarChamada(String id) => state = {...state, id};
}
final provedorChamadaDiaria = StateNotifierProvider<ChamadaDiariaNotifier, Set<String>>((ref) => ChamadaDiariaNotifier());