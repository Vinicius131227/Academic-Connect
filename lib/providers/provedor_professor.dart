import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Importações internas
import '../models/turma_professor.dart';
import '../models/aluno_chamada.dart';
import '../services/servico_firestore.dart';
import 'provedor_tts.dart';

// =============================================================================
// 1. STREAMS (Listas em Tempo Real)
// =============================================================================

final provedorStreamTurmasProfessor = StreamProvider.autoDispose<List<TurmaProfessor>>((ref) {
  return const Stream.empty(); 
});

// =============================================================================
// 2. LÓGICA DE PRÉ-CHAMADA
// =============================================================================

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
  
  void reset() {
    state = EstadoChamadaManual(alunos: [], totalAlunos: 0, status: StatusChamadaManual.ocioso);
  }
}

final provedorChamadaManual = StateNotifierProvider.autoDispose.family<
  NotificadorChamadaManual, EstadoChamadaManual, String
>(
  (ref, turmaId) {
    final servico = ref.watch(servicoFirestoreProvider);
    return NotificadorChamadaManual(servico, turmaId);
  }
);

// =============================================================================
// 4. CHAMADA NFC (STUB COMPATÍVEL)
// =============================================================================

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
  final String? ultimoAluno; // Adicionado para corrigir erro

  // Getter de compatibilidade: se a UI pede .erro, retornamos .ultimoErroScan
  String? get erro => ultimoErroScan;

  EstadoPresencaNFC({
    this.status = StatusNFC.pausado, 
    this.presentes = const [], 
    this.ultimoErroScan,
    this.ultimoAluno, // Adicionado
  });
  
  EstadoPresencaNFC copyWith({
    StatusNFC? status, 
    List<AlunoPresenteNFC>? presentes, 
    String? ultimoErroScan,
    String? ultimoAluno, // Adicionado
  }) {
    return EstadoPresencaNFC(
      status: status ?? this.status, 
      presentes: presentes ?? this.presentes, 
      ultimoErroScan: ultimoErroScan ?? this.ultimoErroScan,
      ultimoAluno: ultimoAluno ?? this.ultimoAluno, // Adicionado
    );
  }
}

class NotificadorPresencaNFC extends StateNotifier<EstadoPresencaNFC> {
  final Ref _ref;
  
  NotificadorPresencaNFC(this._ref) : super(EstadoPresencaNFC());
  
  Future<void> iniciarLeitura(String turmaId) async {
    // Mantém desativado para evitar crash
    state = state.copyWith(status: StatusNFC.indisponivel, ultimoErroScan: "NFC desativado temporariamente.");
  }

  void pausarLeitura() {
    state = state.copyWith(status: StatusNFC.pausado);
  }

  Future<void> salvarChamadaNFC(String turmaId, String tipoChamada, DateTime dataChamada) async {
    // Lógica vazia
  }
  
  void reset() {
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

// =============================================================================
// 6. CHAMADA DIÁRIA (Controle Simples)
// =============================================================================

class ChamadaDiariaNotifier extends StateNotifier<Set<String>> {
  ChamadaDiariaNotifier() : super({});
  bool contains(String id) => state.contains(id);
  void iniciarChamada(String id) => state = {...state, id};
}
final provedorChamadaDiaria = StateNotifierProvider<ChamadaDiariaNotifier, Set<String>>((ref) => ChamadaDiariaNotifier());