// lib/services/servico_firestore.dart

import 'dart:io'; 
import 'dart:math'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; 

// --- Importação dos Modelos de Dados ---
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
import '../models/atividade_evento.dart'; 

/// Classe responsável por toda a comunicação com o Firebase Firestore.
/// Centraliza as operações de leitura (GET), escrita (SET/UPDATE) e tempo real (STREAM).
class ServicoFirestore {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===========================================================================
  // 1. MÉTODOS DE USUÁRIO / AUTENTICAÇÃO
  // ===========================================================================

  /// Busca os dados completos de um usuário pelo seu UID.
  /// Retorna `null` se o usuário não existir no banco.
  Future<UsuarioApp?> getUsuario(String uid) async {
    final doc = await _db.collection('usuarios').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UsuarioApp.fromSnapshot(doc as DocumentSnapshot<Map<String, dynamic>>);
  }

  /// Cria o documento inicial de um usuário após o cadastro.
  Future<void> criarDocumentoUsuario(UsuarioApp usuario) async {
    await _db.collection('usuarios').doc(usuario.uid).set(usuario.toMap());
  }

  /// Atualiza o papel (Aluno/Prof/CA) e identificação (RA/SIAPE) do usuário.
  Future<void> selecionarPapel(String uid, String papel, {String? tipoIdentificacao}) async {
    await _db.collection('usuarios').doc(uid).update({
      'papel': papel,
      if (tipoIdentificacao != null) 'tipoIdentificacao': tipoIdentificacao,
    });
  }

  /// Atualiza os dados do perfil do aluno (Curso, Data Nasc, etc).
  Future<void> salvarPerfilAluno(String uid, AlunoInfo info) async {
    await _db.collection('usuarios').doc(uid).update({
      'alunoInfo': info.toMap(),
    });
  }

  /// Vincula o ID do cartão NFC ao perfil do usuário.
  Future<void> salvarCartaoNFC(String uid, String nfcId) async {
    await _db.collection('usuarios').doc(uid).update({'nfcCardId': nfcId});
  }

  // ===========================================================================
  // 2. MÉTODOS DE CONSULTA (AUXILIARES)
  // ===========================================================================

  /// Busca qual aluno é dono de um determinado cartão NFC.
  /// Usado pelo professor na hora da chamada presencial.
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

  /// Retorna a lista de alunos inscritos em uma turma específica.
  /// Útil para gerar a lista de chamada manual.
  Future<List<AlunoChamada>> getAlunosDaTurma(String turmaId) async {
    final turmaDoc = await _db.collection('turmas').doc(turmaId).get();
    if (!turmaDoc.exists) return [];

    final turmaData = turmaDoc.data() as Map<String, dynamic>;
    final List<String> alunoUids = List<String>.from(turmaData['alunosInscritos'] ?? []);

    if (alunoUids.isEmpty) return [];

    List<AlunoChamada> alunos = [];
    // Busca os dados de cada aluno inscrito (Nome, RA)
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
  
  /// Retorna os dados de aula (quem estava presente) de um dia específico.
  /// Usado para validar se a chamada já foi feita.
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
  // 3. STREAMS (DADOS EM TEMPO REAL)
  // ===========================================================================

  // --- PROFESSOR ---
  
  /// Lista todas as turmas criadas por um professor.
  Stream<List<TurmaProfessor>> getTurmasProfessor(String professorUid) {
    return _db
        .collection('turmas')
        .where('professorId', isEqualTo: professorUid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TurmaProfessor.fromMap(doc.data()!, doc.id))
            .toList());
  }
  
  /// Lista solicitações pendentes (abono, adaptação) para o professor.
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
  
  /// Lista as turmas onde o aluno está matriculado.
  Stream<List<TurmaProfessor>> getTurmasAluno(String alunoUid) {
    return _db
        .collection('turmas')
        .where('alunosInscritos', arrayContains: alunoUid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TurmaProfessor.fromMap(doc.data()!, doc.id))
            .toList());
  }

  /// Lista as notas lançadas para o aluno.
  Stream<List<DisciplinaNotas>> getNotasAluno(String alunoUid) {
    return _db
        .collection('notas') 
        .where('alunoId', isEqualTo: alunoUid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DisciplinaNotas.fromMap(doc.data()!, doc.id))
            .toList());
  }

  /// Lista o histórico de solicitações do aluno.
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
  
  /// Monitora as aulas de uma turma (para atualizar a frequência em tempo real).
  Stream<QuerySnapshot> getAulasStream(String turmaId) {
    return _db
        .collection('turmas')
        .doc(turmaId)
        .collection('aulas')
        .orderBy('data', descending: true)
        .snapshots();
  }
  
  // --- GERAIS (Calendário e Eventos) ---
  
  /// Retorna todas as provas agendadas no sistema.
  Stream<List<ProvaAgendada>> getCalendarioDeProvas() {
    return _db
        .collection('provas') 
        .orderBy('dataHora', descending: false) 
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProvaAgendada.fromMap(doc.data()!, doc.id))
            .toList());
  }
  
  /// Retorna todos os eventos do C.A.
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
  
  /// Materiais específicos de uma turma (postados pelo professor).
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
  
  /// Busca materiais antigos (provas, listas) de turmas passadas com o mesmo nome.
  /// Ex: Mostra provas de "Cálculo 1" de 2023 para a turma de 2024.
  Stream<List<MaterialAula>> getMateriaisPorNomeBase(String nomeBase) {
    return _db
        .collectionGroup('materiais') // Busca em TODAS as subcoleções 'materiais'
        .where('nomeBaseDisciplina', isEqualTo: nomeBase) 
        .orderBy('dataPostagem', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaterialAula.fromMap(doc.data()!, doc.id))
            .toList());
  }

  /// DRIVE GLOBAL: Busca TODAS as provas de TODAS as matérias.
  /// Usado na tela "Drive de Provas".
  Stream<List<MaterialAula>> getTodosMateriaisTipoProva() {
    return _db.collectionGroup('materiais')
        .where('tipo', isEqualTo: 'prova') // Filtra apenas arquivos tipo Prova
        .orderBy('dataPostagem', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => MaterialAula.fromMap(d.data(), d.id)).toList());
  }

  /// Professor adiciona material na turma.
  Future<void> adicionarMaterial(String turmaId, MaterialAula material, String nomeBaseDisciplina) async {
    final data = material.toMap();
    data['nomeBaseDisciplina'] = nomeBaseDisciplina; // Salva o nome base para indexação global
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
  
  /// Dicas postadas na turma atual.
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

  /// Dicas de turmas passadas com o mesmo nome.
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

  /// DICAS GERAIS: Busca todas as dicas do sistema (Mural da Comunidade).
  Stream<List<DicaAluno>> getTodasDicasGlobais() {
    return _db.collectionGroup('dicas')
        .orderBy('dataPostagem', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => DicaAluno.fromMap(d.data(), d.id)).toList());
  }

  /// Aluno posta uma dica na turma.
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
  // 5. GESTÃO, CSV E ESCRITA
  // ===========================================================================

  /// Envia feedback ou sugestão para o app.
  Future<void> enviarSugestao(String texto, String autorId) async {
    await _db.collection('sugestoes').add({
      'texto': texto,
      'autorId': autorId,
      'data': FieldValue.serverTimestamp(),
    });
  }

  // --- HISTÓRICO DE CHAMADAS ---
  
  /// Retorna a lista de dias em que houve aula registrada.
  Stream<List<String>> getDatasChamadas(String turmaId) {
    return _db
        .collection('turmas')
        .doc(turmaId)
        .collection('aulas')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  /// Retorna os detalhes de uma chamada específica (quem estava presente).
  Future<Map<String, dynamic>> getDadosChamada(String turmaId, String dataId) async {
    final doc = await _db.collection('turmas').doc(turmaId).collection('aulas').doc(dataId).get();
    return doc.data() ?? {};
  }

  /// Corrige uma chamada passada (Histórico).
  Future<void> atualizarChamadaHistorico(String turmaId, String dataId, List<String> presentesInicio, List<String> presentesFim) async {
    await _db.collection('turmas').doc(turmaId).collection('aulas').doc(dataId).update({
      'presentes_inicio': presentesInicio,
      'presentes_fim': presentesFim,
    });
  }

  /// GERAÇÃO DE PLANILHA (CSV) - TURMA
  /// Formato Matriz: Linhas = Alunos, Colunas = Dias.
  /// Valor: P (Presente) ou F (Falta).
  Future<String> gerarPlanilhaTurma(String turmaId) async {
    // 1. Pega alunos inscritos
    final alunosDoc = await _db.collection('turmas').doc(turmaId).get();
    final List<String> alunoUids = List<String>.from(alunosDoc.data()!['alunosInscritos'] ?? []);
    
    // Mapeia UID -> Nome
    Map<String, String> nomesAlunos = {};
    for (var uid in alunoUids) {
      final u = await getUsuario(uid);
      nomesAlunos[uid] = u?.alunoInfo?.nomeCompleto ?? 'Desconhecido';
    }

    // 2. Pega os dias de aula (coleção 'aulas')
    final aulasSnapshot = await _db.collection('turmas').doc(turmaId).collection('aulas').orderBy('data').get();
    
    // Cabeçalho CSV (com BOM para UTF-8 no Excel)
    String csv = "\uFEFFNome do Aluno"; 
    List<String> datas = [];
    
    for (var doc in aulasSnapshot.docs) {
       DateTime dataAula = (doc.data()['data'] as Timestamp).toDate();
       String dataFormatada = DateFormat('dd/MM').format(dataAula);
       datas.add(doc.id); // ID do documento é a data yyyy-MM-dd
       csv += ";$dataFormatada"; // Ponto e vírgula para separador
    }
    csv += "\n";

    // Linhas (Uma por aluno)
    for (var uid in alunoUids) {
      csv += "${nomesAlunos[uid]}";
      for (var data in datas) {
        final aulaDoc = aulasSnapshot.docs.firstWhere((d) => d.id == data);
        final dadosAula = aulaDoc.data();
        
        // Junta presença de início e fim
        final presentes = List<String>.from(dadosAula['presentes_inicio'] ?? []) + 
                          List<String>.from(dadosAula['presentes_fim'] ?? []);
        
        // Se o aluno estiver na lista, marca P
        csv += presentes.contains(uid) ? ";P" : ";F";
      }
      csv += "\n";
    }
    return csv;
  }

  // --- EVENTOS DO C.A. ---
  
  /// Lista as atividades (palestras) de um evento.
  Stream<List<AtividadeEvento>> getAtividadesEvento(String eventoId) {
    return _db.collection('eventos').doc(eventoId).collection('atividades')
      .orderBy('dataHora').snapshots()
      .map((s) => s.docs.map((d) => AtividadeEvento.fromMap(d.data(), d.id)).toList());
  }

  /// Cria uma nova atividade dentro do evento.
  Future<void> criarAtividadeEvento(String eventoId, String nome, DateTime data, String local) async {
    await _db.collection('eventos').doc(eventoId).collection('atividades').add({
      'nome': nome,
      'dataHora': Timestamp.fromDate(data),
      'local': local,
      'presentes': [],
    });
  }

  /// Registra quem participou da atividade (check-in).
  Future<void> registrarPresencaAtividade(String eventoId, String atividadeId, List<String> uids) async {
    await _db.collection('eventos').doc(eventoId).collection('atividades').doc(atividadeId).update({
      'presentes': FieldValue.arrayUnion(uids),
    });
  }

  /// GERAÇÃO DE PLANILHA (CSV) - EVENTO CA
  /// Formato Lista: Atividade | Participante | RA
  Future<String> gerarPlanilhaEvento(String eventoId) async {
    final atividades = await _db.collection('eventos').doc(eventoId).collection('atividades').get();
    
    String csv = "\uFEFFAtividade;Participante;RA\n";

    for (var ativ in atividades.docs) {
      final nomeAtiv = ativ.data()['nome'];
      final presentes = List<String>.from(ativ.data()['presentes'] ?? []);
      
      for (var uid in presentes) {
        final u = await getUsuario(uid);
        csv += "\"$nomeAtiv\";\"${u?.alunoInfo?.nomeCompleto}\";\"${u?.alunoInfo?.ra}\"\n";
      }
    }
    return csv;
  }

  // --- MÉTODOS GERAIS ---

  Future<void> atualizarSolicitacao(String solicitacaoId, StatusSolicitacao novoStatus, String resposta) async {
    await _db.collection('solicitacoes').doc(solicitacaoId).update({
      'status': novoStatus.name,
      'respostaProfessor': resposta,
    });
  }

  // Gera código aleatório para turma (ex: A1B2C3)
  String _gerarCodigoAleatorio({int length = 6}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }
  
  /// Cria uma nova turma e gera o código de convite.
  Future<String> criarTurma(TurmaProfessor turma) async {
    String codigo = '';
    bool codigoUnico = false;
    
    // Garante que o código seja único no banco
    while (!codigoUnico) {
      codigo = _gerarCodigoAleatorio();
      final snapshot = await _db.collection('turmas').where('turmaCode', isEqualTo: codigo).limit(1).get();
      if (snapshot.docs.isEmpty) {
        codigoUnico = true;
      }
    }
    
    final dadosTurma = turma.toMap();
    dadosTurma['turmaCode'] = codigo;
    dadosTurma['linkConvite'] = "academicconnect://entrar/$codigo"; // Link profundo

    final docRef = await _db.collection('turmas').add(dadosTurma);
    await docRef.update({'id': docRef.id}); 
    
    return codigo;
  }

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

  /// Inscreve o aluno na turma usando o código.
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

  /// Salva a lista de presença (NFC ou Manual) no histórico.
  Future<void> salvarPresenca(
      String turmaId, String tipoChamada, List<String> presentesUids, DateTime dataChamada) async {
    
    final dataString = DateFormat('yyyy-MM-dd').format(dataChamada);
    final docRef = _db
        .collection('turmas')
        .doc(turmaId)
        .collection('aulas') 
        .doc(dataString);

    final String campo = 'presentes_$tipoChamada'; // presentes_inicio ou presentes_fim

    await docRef.set(
      {
        'data': Timestamp.fromDate(dataChamada),
        campo: presentesUids,
      },
      SetOptions(merge: true), // Não apaga os dados da outra chamada se já existir
    );
  }
  
  Future<void> salvarPresencaEvento(String eventoId, List<String> presentesUids) async {
    final docRef = _db.collection('eventos').doc(eventoId);
    
    await docRef.update({
      'participantesPresentes': FieldValue.arrayUnion(presentesUids),
    });
  }

  /// Salva as notas de toda a turma.
  Future<void> salvarNotas(
      String turmaId, String avaliacaoNome, Map<String, double?> notas) async {
    final turmaDoc = await _db.collection('turmas').doc(turmaId).get();
    if (!turmaDoc.exists) throw Exception("Turma não encontrada");
    final turma = TurmaProfessor.fromMap(turmaDoc.data()!, turmaDoc.id);

    final batch = _db.batch();

    for (final entry in notas.entries) {
      final alunoId = entry.key;
      final nota = entry.value;
      
      // Verifica se já existe nota para este aluno nesta avaliação
      final query = await _db
          .collection('notas')
          .where('alunoId', isEqualTo: alunoId)
          .where('turmaId', isEqualTo: turmaId)
          .where('avaliacaoNome', isEqualTo: avaliacaoNome) 
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        // Atualiza
        final docRef = query.docs.first.reference;
        batch.update(docRef, {'nota': nota, 'dataLancamento': Timestamp.now()});
      } else {
        // Cria nova
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

/// Instância global do serviço de Firestore.
final servicoFirestoreProvider = Provider<ServicoFirestore>((ref) {
  return ServicoFirestore();
});

// --- Streams para atualizar a UI automaticamente ---

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

final driveProvasProvider = StreamProvider<List<MaterialAula>>((ref) {
  return ref.watch(servicoFirestoreProvider).getTodosMateriaisTipoProva();
});

final streamDicasPorNomeProvider =
    StreamProvider.family<List<DicaAluno>, String>((ref, nomeBase) {
  return ref.watch(servicoFirestoreProvider).getDicasPorNomeBase(nomeBase);
});

final dicasGeraisProvider = StreamProvider<List<DicaAluno>>((ref) {
  return ref.watch(servicoFirestoreProvider).getTodasDicasGlobais();
});