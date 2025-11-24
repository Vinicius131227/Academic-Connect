// lib/services/servico_firestore.dart
import 'dart:io'; 
import 'dart:math'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; 

// Importe todos os modelos
import '../models/usuario.dart';
import '../models/aluno_info.dart';
import '../models/turma_professor.dart';
import '../models/solicitacao_aluno.dart';
import '../models/prova_agendada.dart';
import '../models/disciplina_notas.dart';
import '../models/aluno_chamada.dart';
import '../models/evento_ca.dart';
import '../models/mensagem_chat.dart';
import '../models/material_aula.dart';
import '../models/dica_aluno.dart';

class ServicoFirestore {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===========================================================================
  // 1. MÉTODOS DE USUÁRIO / AUTENTICAÇÃO
  // ===========================================================================

  /// Busca um documento de usuário pelo UID.
  Future<UsuarioApp?> getUsuario(String uid) async {
    final doc = await _db.collection('usuarios').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UsuarioApp.fromSnapshot(doc as DocumentSnapshot<Map<String, dynamic>>);
  }

  /// Cria o documento inicial para um novo usuário.
  Future<void> criarDocumentoUsuario(UsuarioApp usuario) async {
    await _db.collection('usuarios').doc(usuario.uid).set(usuario.toMap());
  }

  /// Atualiza o 'papel' e identificação do usuário.
  Future<void> selecionarPapel(String uid, String papel, {String? tipoIdentificacao}) async {
    await _db.collection('usuarios').doc(uid).update({
      'papel': papel,
      if (tipoIdentificacao != null) 'tipoIdentificacao': tipoIdentificacao,
    });
  }

  /// Salva os dados do perfil do aluno.
  Future<void> salvarPerfilAluno(String uid, AlunoInfo info) async {
    await _db.collection('usuarios').doc(uid).update({
      'alunoInfo': info.toMap(),
    });
  }

  /// Salva o cartão NFC de um aluno.
  Future<void> salvarCartaoNFC(String uid, String nfcId) async {
    await _db.collection('usuarios').doc(uid).update({'nfcCardId': nfcId});
  }

  // ===========================================================================
  // 2. MÉTODOS DE CONSULTA E LEITURA (Auxiliares)
  // ===========================================================================

  /// Busca um aluno pelo ID do cartão NFC.
  Future<UsuarioApp?> getAlunoPorNFC(String nfcId) async {
    final query = await _db
        .collection('usuarios')
        .where('nfcCardId', isEqualTo: nfcId)
        .where('papel', isEqualTo: 'aluno') 
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return UsuarioApp.fromSnapshot(query.docs.first as DocumentSnapshot<Map<String, dynamic>>);
  }

  /// Busca a lista de alunos de uma turma específica.
  Future<List<AlunoChamada>> getAlunosDaTurma(String turmaId) async {
    final turmaDoc = await _db.collection('turmas').doc(turmaId).get();
    if (!turmaDoc.exists) return [];

    final turmaData = turmaDoc.data() as Map<String, dynamic>;
    final List<String> alunoUids = List<String>.from(turmaData['alunosInscritos'] ?? []);

    if (alunoUids.isEmpty) return [];

    List<AlunoChamada> alunos = [];
    // Nota: Para listas muito grandes (>10), idealmente usaríamos paginação ou whereIn em lotes.
    for (String uid in alunoUids) {
        final doc = await _db.collection('usuarios').doc(uid).get();
        if (doc.exists) {
          final user = UsuarioApp.fromSnapshot(doc as DocumentSnapshot<Map<String, dynamic>>);
          if (user.alunoInfo != null) {
            alunos.add(AlunoChamada(
              id: user.uid, 
              nome: user.alunoInfo!.nomeCompleto,
              ra: user.alunoInfo!.ra,
            ));
          }
        }
    }
    return alunos;
  }
  
  /// Retorna os dados de aula para um dia específico (usado na validação de presença).
  Future<Map<String, dynamic>?> getAulaPorDia(String turmaId, DateTime data) async {
    final dataString = DateFormat('yyyy-MM-dd').format(data);
    final doc = await _db
        .collection('turmas')
        .doc(turmaId)
        .collection('aulas')
        .doc(dataString)
        .get();
        
    return doc.data();
  }

  // ===========================================================================
  // 3. STREAMS (Fluxos de Dados em Tempo Real)
  // ===========================================================================

  // --- PROFESSOR ---
  Stream<List<TurmaProfessor>> getTurmasProfessor(String professorUid) {
    return _db
        .collection('turmas')
        .where('professorId', isEqualTo: professorUid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TurmaProfessor.fromMap(doc.data()!, doc.id))
            .toList());
  }
  
  Stream<List<SolicitacaoAluno>> getSolicitacoes(String professorUid) {
    return _db
        .collection('solicitacoes')
        .where('professorId', isEqualTo: professorUid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SolicitacaoAluno.fromMap(doc.data()!, doc.id))
            .toList());
  }
  
  // --- ALUNO ---
  Stream<List<TurmaProfessor>> getTurmasAluno(String alunoUid) {
    return _db
        .collection('turmas')
        .where('alunosInscritos', arrayContains: alunoUid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TurmaProfessor.fromMap(doc.data()!, doc.id))
            .toList());
  }

  Stream<List<DisciplinaNotas>> getNotasAluno(String alunoUid) {
    return _db
        .collection('notas') 
        .where('alunoId', isEqualTo: alunoUid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DisciplinaNotas.fromMap(doc.data()!, doc.id))
            .toList());
  }

  Stream<List<SolicitacaoAluno>> getSolicitacoesAluno(String alunoUid) {
    return _db
        .collection('solicitacoes')
        .where('alunoId', isEqualTo: alunoUid)
        .orderBy('data', descending: true) 
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SolicitacaoAluno.fromMap(doc.data()!, doc.id))
            .toList());
  }
  
  Stream<QuerySnapshot> getAulasStream(String turmaId) {
    return _db
        .collection('turmas')
        .doc(turmaId)
        .collection('aulas')
        .orderBy('data', descending: true)
        .snapshots();
  }
  
  // --- GERAIS (Calendário e Eventos) ---
  Stream<List<ProvaAgendada>> getCalendarioDeProvas() {
    return _db
        .collection('provas') 
        .orderBy('dataHora', descending: false) 
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProvaAgendada.fromMap(doc.data()!, doc.id))
            .toList());
  }
  
  Stream<List<EventoCA>> getEventos() {
    return _db
        .collection('eventos')
        .orderBy('data', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventoCA.fromMap(doc.data()!, doc.id))
            .toList());
  }

  // ===========================================================================
  // 4. HUB DA DISCIPLINA (Chat, Materiais, Dicas)
  // ===========================================================================

  // --- CHAT ---
  Stream<List<MensagemChat>> getStreamMensagens(String turmaId) {
    return _db
        .collection('turmas')
        .doc(turmaId)
        .collection('mensagens')
        .orderBy('dataHora', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MensagemChat.fromMap(doc.data()!, doc.id))
            .toList());
  }

  Future<void> enviarMensagem(String turmaId, MensagemChat mensagem) async {
    await _db
        .collection('turmas')
        .doc(turmaId)
        .collection('mensagens')
        .add(mensagem.toMap());
  }

  // --- MATERIAIS ---
  // Materiais da turma específica
  Stream<List<MaterialAula>> getStreamMateriais(String turmaId) {
    return _db
        .collection('turmas')
        .doc(turmaId)
        .collection('materiais')
        .orderBy('dataPostagem', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaterialAula.fromMap(doc.data()!, doc.id))
            .toList());
  }
  
  // Materiais de turmas com nome similar (Global Search - Provas Anteriores)
  Stream<List<MaterialAula>> getMateriaisPorNomeBase(String nomeBase) {
    return _db
        .collectionGroup('materiais') // Collection Group Query
        .where('nomeBaseDisciplina', isEqualTo: nomeBase) 
        .orderBy('dataPostagem', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaterialAula.fromMap(doc.data()!, doc.id))
            .toList());
  }

  Future<void> adicionarMaterial(String turmaId, MaterialAula material, String nomeBaseDisciplina) async {
    final data = material.toMap();
    data['nomeBaseDisciplina'] = nomeBaseDisciplina; 
    await _db
        .collection('turmas')
        .doc(turmaId)
        .collection('materiais')
        .add(data);
  }

  Future<void> removerMaterial(String turmaId, String materialId) async {
    await _db
        .collection('turmas')
        .doc(turmaId)
        .collection('materiais')
        .doc(materialId)
        .delete();
  }

  // --- DICAS ---
  // Dicas da turma específica
  Stream<List<DicaAluno>> getStreamDicas(String turmaId) {
    return _db
        .collection('turmas')
        .doc(turmaId)
        .collection('dicas')
        .orderBy('dataPostagem', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DicaAluno.fromMap(doc.data()!, doc.id))
            .toList());
  }

  // Dicas de turmas com nome similar (Para alunos verem dicas passadas)
  Stream<List<DicaAluno>> getDicasPorNomeBase(String nomeBase) {
    return _db
        .collectionGroup('dicas') 
        .where('nomeBaseDisciplina', isEqualTo: nomeBase)
        .orderBy('dataPostagem', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DicaAluno.fromMap(doc.data()!, doc.id))
            .toList());
  }

  Future<void> adicionarDica(String turmaId, DicaAluno dica, String nomeBaseDisciplina) async {
    final data = dica.toMap();
    data['nomeBaseDisciplina'] = nomeBaseDisciplina;
    await _db
        .collection('turmas')
        .doc(turmaId)
        .collection('dicas')
        .add(data);
  }

  // ===========================================================================
  // 5. GESTÃO E ESCRITA
  // ===========================================================================

  // SUGESTÕES
  Future<void> enviarSugestao(String texto, String autorId) async {
    await _db.collection('sugestoes').add({
      'texto': texto,
      'autorId': autorId,
      'data': FieldValue.serverTimestamp(),
    });
  }

  // HISTÓRICO DE CHAMADAS
  Stream<List<String>> getDatasChamadas(String turmaId) {
    return _db
        .collection('turmas')
        .doc(turmaId)
        .collection('aulas')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  Future<Map<String, dynamic>> getDadosChamada(String turmaId, String dataId) async {
    final doc = await _db.collection('turmas').doc(turmaId).collection('aulas').doc(dataId).get();
    return doc.data() ?? {};
  }

  Future<void> atualizarChamadaHistorico(String turmaId, String dataId, List<String> presentesInicio, List<String> presentesFim) async {
    await _db.collection('turmas').doc(turmaId).collection('aulas').doc(dataId).update({
      'presentes_inicio': presentesInicio,
      'presentes_fim': presentesFim,
    });
  }

  // GESTÃO DE TURMAS E ALUNOS
  Future<void> atualizarTurma(TurmaProfessor turma) async {
    await _db.collection('turmas').doc(turma.id).update({
      'nome': turma.nome,
      'horario': turma.horario,
      'local': turma.local,
      'creditos': turma.creditos,
    });
  }

  Future<void> removerAlunoDaTurma(String turmaId, String alunoUid) async {
     await _db.collection('turmas').doc(turmaId).update({
      'alunosInscritos': FieldValue.arrayRemove([alunoUid]),
    });
  }

  Future<void> atualizarSolicitacao(String solicitacaoId, StatusSolicitacao novoStatus, String resposta) async {
    await _db.collection('solicitacoes').doc(solicitacaoId).update({
      'status': novoStatus.name,
      'respostaProfessor': resposta,
    });
  }

  // UTILITÁRIO
  String _gerarCodigoAleatorio({int length = 6}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }
  
  // CRIAÇÃO E ENTRADA
  Future<String> criarTurma(TurmaProfessor turma) async {
    String codigo = '';
    bool codigoUnico = false;
    while (!codigoUnico) {
      codigo = _gerarCodigoAleatorio();
      final snapshot = await _db.collection('turmas').where('turmaCode', isEqualTo: codigo).limit(1).get();
      if (snapshot.docs.isEmpty) {
        codigoUnico = true;
      }
    }
    
    final dadosTurma = turma.toMap();
    dadosTurma['turmaCode'] = codigo;

    final docRef = await _db.collection('turmas').add(dadosTurma);
    await docRef.update({'id': docRef.id}); 
    
    return codigo;
  }

  Future<void> entrarNaTurma(String turmaCode, String alunoUid) async {
    final query = await _db
        .collection('turmas')
        .where('turmaCode', isEqualTo: turmaCode.toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('Código da turma não encontrado.');
    }

    final turmaDoc = query.docs.first;
    final turma = TurmaProfessor.fromMap(turmaDoc.data(), turmaDoc.id);

    if (turma.alunosInscritos.contains(alunoUid)) {
      throw Exception('Você já está inscrito nesta turma.');
    }

    await turmaDoc.reference.update({
      'alunosInscritos': FieldValue.arrayUnion([alunoUid]),
    });
  }

  Future<void> adicionarProva(ProvaAgendada prova) async {
    await _db.collection('provas').add(prova.toMap());
  }
  
  Future<void> adicionarEvento(EventoCA evento) async {
    await _db.collection('eventos').add(evento.toMap());
  }

  Future<void> adicionarSolicitacao(SolicitacaoAluno solicitacao) async {
    await _db.collection('solicitacoes').add(solicitacao.toMap());
  }

  // PRESENÇA
  Future<void> salvarPresenca(
      String turmaId, String tipoChamada, List<String> presentesUids, DateTime dataChamada) async {
    
    final dataString = DateFormat('yyyy-MM-dd').format(dataChamada);
    final docRef = _db
        .collection('turmas')
        .doc(turmaId)
        .collection('aulas') 
        .doc(dataString);

    final String campo = 'presentes_$tipoChamada';

    await docRef.set(
      {
        'data': Timestamp.fromDate(dataChamada),
        campo: presentesUids,
      },
      SetOptions(merge: true), 
    );
  }
  
  Future<void> salvarPresencaEvento(String eventoId, List<String> presentesUids) async {
    final docRef = _db.collection('eventos').doc(eventoId);
    
    await docRef.update({
      'participantesPresentes': FieldValue.arrayUnion(presentesUids),
    });
  }

  // NOTAS
  Future<void> salvarNotas(
      String turmaId, String avaliacaoNome, Map<String, double?> notas) async {
    final turmaDoc = await _db.collection('turmas').doc(turmaId).get();
    if (!turmaDoc.exists) throw Exception("Turma não encontrada");
    final turma = TurmaProfessor.fromMap(turmaDoc.data()!, turmaDoc.id);

    final batch = _db.batch();

    for (final entry in notas.entries) {
      final alunoId = entry.key;
      final nota = entry.value;
      
      final query = await _db
          .collection('notas')
          .where('alunoId', isEqualTo: alunoId)
          .where('turmaId', isEqualTo: turmaId)
          .where('avaliacaoNome', isEqualTo: avaliacaoNome) 
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final docRef = query.docs.first.reference;
        batch.update(docRef, {'nota': nota, 'dataLancamento': Timestamp.now()});
      } else {
        final docRef = _db.collection('notas').doc(); 
        batch.set(docRef, {
          'alunoId': alunoId,
          'turmaId': turmaId,
          'professorId': turma.professorId,
          'disciplinaNome': turma.nome,
          'avaliacaoNome': avaliacaoNome,
          'nota': nota,
          'dataLancamento': Timestamp.now(),
        });
      }
    }
    
    await batch.commit();
  }
  
  Future<Map<String, double?>> getNotasDaAvaliacao(String turmaId, String avaliacaoNome) async {
    final query = await _db
        .collection('notas')
        .where('turmaId', isEqualTo: turmaId)
        .where('avaliacaoNome', isEqualTo: avaliacaoNome)
        .get();

    if (query.docs.isEmpty) {
      return {}; 
    }

    final Map<String, double?> notas = {};
    for (final doc in query.docs) {
      final data = doc.data();
      final alunoId = data['alunoId'] as String?;
      final nota = (data['nota'] as num?)?.toDouble(); 
      
      if (alunoId != null) {
        notas[alunoId] = nota;
      }
    }
    return notas;
  }
  
  Future<String> uploadArquivoSolicitacao(File arquivo, String alunoUid) async {
    final nomeArquivo = arquivo.path.split(Platform.pathSeparator).last;
    return nomeArquivo;
  }
}

// ===========================================================================
// 6. PROVEDORES (Riverpod)
// ===========================================================================

final servicoFirestoreProvider = Provider<ServicoFirestore>((ref) {
  return ServicoFirestore();
});

// Hub
final streamMensagensProvider =
    StreamProvider.family<List<MensagemChat>, String>((ref, turmaId) {
  return ref.watch(servicoFirestoreProvider).getStreamMensagens(turmaId);
});

final streamMateriaisProvider =
    StreamProvider.family<List<MaterialAula>, String>((ref, turmaId) {
  return ref.watch(servicoFirestoreProvider).getStreamMateriais(turmaId);
});

final streamDicasProvider =
    StreamProvider.family<List<DicaAluno>, String>((ref, turmaId) {
  return ref.watch(servicoFirestoreProvider).getStreamDicas(turmaId);
});

final streamMateriaisAntigosProvider =
    StreamProvider.family<List<MaterialAula>, String>((ref, nomeBase) {
  return ref.watch(servicoFirestoreProvider).getMateriaisPorNomeBase(nomeBase);
});

final streamDicasPorNomeProvider =
    StreamProvider.family<List<DicaAluno>, String>((ref, nomeBase) {
  return ref.watch(servicoFirestoreProvider).getDicasPorNomeBase(nomeBase);
});