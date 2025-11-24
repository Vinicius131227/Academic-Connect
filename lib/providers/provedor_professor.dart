// lib/providers/provedor_professor.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart'; 
import '../models/turma_professor.dart';
import '../models/solicitacao_aluno.dart';
import '../models/aluno_chamada.dart';
import '../services/servico_firestore.dart';
import 'provedor_tts.dart';
import 'package:intl/intl.dart';

// --- LÓGICA DE CHAMADA ---

int _calcularCreditos(String horario) {
  int duracaoTotalMinutos = 0;
  final encontros = horario.split(',').map((e) => e.trim());

  for (final encontro in encontros) {
    try {
      final partes = encontro.split(RegExp(r'[^0-9:]')).where((s) => s.isNotEmpty).toList();
      if (partes.length >= 2) {
          final horaMinInicio = partes[0].split(':').map(int.parse).toList();
          final horaMinFim = partes[1].split(':').map(int.parse).toList();
          
          final totalMinInicio = horaMinInicio[0] * 60 + horaMinInicio[1];
          final totalMinFim = horaMinFim[0] * 60 + horaMinFim[1];
          
          duracaoTotalMinutos += (totalMinFim - totalMinInicio);
      }
    } catch (_) {}
  }
  return (duracaoTotalMinutos / 60).round(); 
}

String _getDiaSemanaConsulta(DateTime data) {
    return DateFormat('EEE').format(data).toLowerCase().substring(0, 3);
}

class EstadoPreChamada {
  final bool podeChamar;
  final String? bloqueioMensagem;
  final bool podeFazerSegundaChamada; 
  final int creditos;

  EstadoPreChamada({this.podeChamar = false, this.bloqueioMensagem, this.podeFazerSegundaChamada = false, this.creditos = 0});
}

final provedorPreChamada = FutureProvider.family<EstadoPreChamada, TurmaProfessor>((ref, turma) async {
  final servico = ref.watch(servicoFirestoreProvider);
  final agora = DateTime.now();
  final dataChamada = agora; 
  
  final creditos = turma.creditos;
  final diaConsulta = _getDiaSemanaConsulta(dataChamada);
  final horaMinutoAtual = agora.hour * 60 + agora.minute;
  
  final dadosAula = await servico.getAulaPorDia(turma.id, dataChamada);
  final chamadaInicio = dadosAula?['presentes_inicio'] as List<dynamic>?;
  final chamadaFim = dadosAula?['presentes_fim'] as List<dynamic>?;
  final chamadasFeitas = (chamadaInicio != null ? 1 : 0) + (chamadaFim != null ? 1 : 0);

  // 1. VERIFICAÇÃO DE HORÁRIO/DIA DE AULA
  final encontrosHoje = turma.horario.split(',').where((h) => h.toLowerCase().contains(diaConsulta)).toList();

  if (encontrosHoje.isEmpty) {
    if (dataChamada.isBefore(agora.copyWith(hour: 0, minute: 0, second: 0)) && chamadasFeitas == 0) {
      return EstadoPreChamada(podeChamar: true, bloqueioMensagem: 'Chamada em modo retroativo.', creditos: creditos);
    }
    return EstadoPreChamada(bloqueioMensagem: 'Não há aula desta turma hoje.', creditos: creditos);
  }

  // 2. VERIFICAÇÃO DE JANELA DE TEMPO
  bool aulaEmAndamento = false;
  for (final encontro in encontrosHoje) {
      final partes = encontro.split(RegExp(r'[^0-9:]')).where((s) => s.isNotEmpty).toList();
      if (partes.length >= 2) {
          final inicio = partes[0].split(':').map(int.parse).toList();
          final fim = partes[1].split(':').map(int.parse).toList();
          
          final totalMinInicio = inicio[0] * 60 + inicio[1];
          final totalMinFim = fim[0] * 60 + fim[1];
          
          if (horaMinutoAtual >= totalMinInicio - 15 && horaMinutoAtual <= totalMinFim + 15) {
              aulaEmAndamento = true;
              break;
          }
      }
  }

  if (!aulaEmAndamento) {
    return EstadoPreChamada(bloqueioMensagem: 'Fora do horário de aula.', creditos: creditos);
  }

  // 3. LÓGICA DE CRÉDITOS
  if (creditos <= 2) {
    if (chamadasFeitas >= 1) {
      return EstadoPreChamada(bloqueioMensagem: 'Chamada única já realizada.', creditos: creditos);
    }
  } else { 
    if (chamadasFeitas == 2) {
      return EstadoPreChamada(bloqueioMensagem: 'Chamadas (Início e Fim) já realizadas.', creditos: creditos);
    }
    if (chamadasFeitas == 1 && chamadaInicio != null) {
      return EstadoPreChamada(podeChamar: true, podeFazerSegundaChamada: true, creditos: creditos);
    }
  }
  
  return EstadoPreChamada(podeChamar: true, creditos: creditos);
});


// --- NOTIFICADORES EXISTENTES ---

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

  int get presentesCount => alunos.where((a) => a.isPresente).length;

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
    final presentesUids = state.alunos
        .where((a) => a.isPresente)
        .map((a) => a.id)
        .toList();

    await _ref.read(servicoFirestoreProvider).salvarPresenca(
          _turmaId,
          tipoChamada,
          presentesUids,
          dataChamada,
        );
  }
}

final provedorChamadaManual = StateNotifierProvider.autoDispose.family<
  NotificadorChamadaManual, EstadoChamadaManual, String
>(
  (ref, turmaId) => NotificadorChamadaManual(ref, turmaId)
);

// --- NFC ---
enum StatusNFC { pausado, lendo, indisponivel, erro }

// --- CORREÇÃO: CLASSE RE-ADICIONADA ---
class AlunoPresenteNFC {
  final String uid; 
  final String nome;
  final String hora;
  AlunoPresenteNFC({required this.uid, required this.nome, required this.hora});
}
// --- FIM CORREÇÃO ---

class EstadoPresencaNFC {
  final StatusNFC status;
  final List<AlunoPresenteNFC> presentes; // Agora reconhece o tipo
  final String? ultimoAluno;
  final String? erro;
  final String? ultimoErroScan;
  EstadoPresencaNFC({this.status = StatusNFC.pausado, this.presentes = const [], this.ultimoAluno, this.erro, this.ultimoErroScan});
  
  EstadoPresencaNFC copyWith({StatusNFC? status, List<AlunoPresenteNFC>? presentes, String? ultimoAluno, String? erro, String? ultimoErroScan, bool limparUltimoAluno = false, bool limparErro = false, bool limparUltimoErroScan = false}) {
    return EstadoPresencaNFC(status: status ?? this.status, presentes: presentes ?? this.presentes, ultimoAluno: limparUltimoAluno ? null : ultimoAluno ?? this.ultimoAluno, erro: limparErro ? null : erro ?? this.erro, ultimoErroScan: limparUltimoErroScan ? null : ultimoErroScan ?? this.ultimoErroScan);
  }
}

class NotificadorPresencaNFC extends StateNotifier<EstadoPresencaNFC> {
  final Ref _ref;
  bool _isPolling = false; 
  NotificadorPresencaNFC(this._ref) : super(EstadoPresencaNFC());
  
  Future<void> iniciarLeitura(String turmaId) async {
    if (_isPolling || state.status == StatusNFC.lendo) return; 
    _isPolling = true;
    NFCAvailability availability = await FlutterNfcKit.nfcAvailability;
    if (availability != NFCAvailability.available) {
      state = state.copyWith(status: StatusNFC.indisponivel, erro: 'NFC não está disponível.');
      _isPolling = false;
      return;
    }
    state = state.copyWith(status: StatusNFC.lendo, limparErro: true, limparUltimoAluno: true, limparUltimoErroScan: true);
    _ref.read(ttsProvider).speak("Modo de leitura iniciado.");

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
            _feedbackError("$nomeAluno já marcou presença.");
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
    // Agora o construtor de AlunoPresenteNFC é reconhecido
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

  Future<void> salvarChamadaNFC(String turmaId, String tipoChamada, DateTime dataChamada) async {
    // Converte a lista explicitamente para List<String>
    final presentesUids = state.presentes.map((a) => a.uid).toList().cast<String>();
    
    if (presentesUids.isEmpty) {
      throw Exception("Nenhum aluno presente para salvar.");
    }
    
    await _ref.read(servicoFirestoreProvider).salvarPresenca(
          turmaId,
          tipoChamada,
          presentesUids,
          dataChamada,
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

final provedorPresencaNFC =
    StateNotifierProvider.autoDispose<NotificadorPresencaNFC, EstadoPresencaNFC>(
  (ref) => NotificadorPresencaNFC(ref),
);

class ChamadaDiariaNotifier extends StateNotifier<Set<String>> {
  ChamadaDiariaNotifier() : super({});
  bool chamadaJaIniciada(String turmaId) {
    return state.contains(turmaId);
  }
  void iniciarChamada(String turmaId) {
    if (!state.contains(turmaId)) {
      state = {...state, turmaId};
    }
  }
  void resetarTodasChamadas() {
    state = {};
  }
}
final provedorChamadaDiaria = StateNotifierProvider<ChamadaDiariaNotifier, Set<String>>((ref) {
  return ChamadaDiariaNotifier();
});

class NotasNotifier extends StateNotifier<Map<String, double?>> {
  final Ref _ref;
  NotasNotifier(this._ref) : super({}); 

  Future<void> carregarNotas(String turmaId, String avaliacao) async {
    try {
      final notasExistentes = await _ref.read(servicoFirestoreProvider)
                            .getNotasDaAvaliacao(turmaId, avaliacao);
      state = notasExistentes;
    } catch (e) {
      state = {};
      debugPrint("Erro ao carregar notas: $e");
    }
  }
  
  void atualizarNota(String alunoId, double? nota) {
    state = {...state, alunoId: nota};
  }
  
  Future<void> salvarNotas(String turmaId, String avaliacaoNome) async {
    await _ref.read(servicoFirestoreProvider).salvarNotas(
          turmaId,
          avaliacaoNome,
          state,
        );
  }
}

final provedorNotas = StateNotifierProvider<NotasNotifier, Map<String, double?>>((ref) {
  return NotasNotifier(ref);
});