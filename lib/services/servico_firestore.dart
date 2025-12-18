// lib/services/servico_firestore.dart

import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/usuario.dart';
import '../models/aluno_info.dart';
import '../models/turma_professor.dart';
import '../models/solicitacao_aluno.dart';
import '../models/prova_agendada.dart';
import '../models/disciplina_notas.dart';
import '../models/aluno_chamada.dart';
import '../models/mensagem_chat.dart';
import '../models/material_aula.dart';
import '../models/dica_aluno.dart';
import '../models/pasta_drive.dart';

class ServicoFirestore {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===========================================================================
  // 1. MÉTODOS DE USUÁRIO / AUTENTICAÇÃO
  // ===========================================================================

  Future<UsuarioApp?> getUsuario(String uid) async {
    final doc = await _db.collection('usuarios').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UsuarioApp.fromSnapshot(doc as DocumentSnapshot<Map<String, dynamic>>);
  }

  Future<void> criarDocumentoUsuario(UsuarioApp usuario) async {
    await _db.collection('usuarios').doc(usuario.uid).set(usuario.toMap());
  }

  Future<void> selecionarPapel(String uid, String papel, {String? tipoIdentificacao}) async {
    await _db.collection('usuarios').doc(uid).update({
      'papel': papel,
      if (tipoIdentificacao != null) 'tipoIdentificacao': tipoIdentificacao,
    });
  }

  Future<void> salvarPerfilAluno(String uid, AlunoInfo info) async {
    await _db.collection('usuarios').doc(uid).update({
      'alunoInfo': info.toMap(),
    });
  }

  Future<void> salvarCartaoNFC(String uid, String nfcId) async {
    // 1. Verifica duplicidade
    final query = await _db
        .collection('usuarios')
        .where('nfcCardId', isEqualTo: nfcId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final usuarioExistente = query.docs.first;
      
      // Se o cartão já existe e o dono NÃO é o usuário atual (uid)
      if (usuarioExistente.id != uid) {
        String nomeDono = "outro usuário";
        try {
           final dados = usuarioExistente.data();
           if (dados.containsKey('alunoInfo') && dados['alunoInfo'] != null) {
             nomeDono = dados['alunoInfo']['nomeCompleto'] ?? "um aluno";
           } else if (dados.containsKey('professorInfo') && dados['professorInfo'] != null) {
             nomeDono = dados['professorInfo']['nome'] ?? "um professor";
           }
        } catch (_) {}

        throw Exception("Este cartão já está cadastrado para $nomeDono.");
      }
    }

    await _db.collection('usuarios').doc(uid).update({'nfcCardId': nfcId});
  }

  // ===========================================================================
  // 2. MÉTODOS DE CONSULTA (ALUNOS E TURMAS)
  // ===========================================================================

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

  // --- LEITURA DE ALUNOS ---
  Future<List<AlunoChamada>> getAlunosDaTurma(String turmaId) async {
    try {
      final turmaDoc = await _db.collection('turmas').doc(turmaId).get();
      if (!turmaDoc.exists) return [];

      final turmaData = turmaDoc.data() as Map<String, dynamic>;
      
      // 1. IDs dos alunos inscritos
      final List<String> alunoUids = List<String>.from(turmaData['alunosInscritos'] ?? []);
      
      // 2. Dados dos alunos pré-cadastrados (via CSV)
      final List<Map<String, dynamic>> preCadastrados = List<Map<String, dynamic>>.from(turmaData['alunosPreCadastrados'] ?? []);

      List<AlunoChamada> alunos = [];

      // OTIMIZAÇÃO: Busca alunos em lotes de 10 para evitar N leituras separadas
      if (alunoUids.isNotEmpty) {
        for (var i = 0; i < alunoUids.length; i += 10) {
          final fim = (i + 10 < alunoUids.length) ? i + 10 : alunoUids.length;
          final loteIds = alunoUids.sublist(i, fim);

          final querySnapshot = await _db
              .collection('usuarios')
              .where(FieldPath.documentId, whereIn: loteIds)
              .get();

          for (var doc in querySnapshot.docs) {
             final user = UsuarioApp.fromSnapshot(doc as DocumentSnapshot<Map<String, dynamic>>);
             
             // Tenta pegar nome do aluno, ou do professor (se for monitor/híbrido), ou fallback
             final nome = user.alunoInfo?.nomeCompleto ?? 
                          user.professorInfo?['nome'] ?? 
                          'Sem Nome';
                          
             final ra = user.alunoInfo?.ra ?? 'S/ RA';
             
             alunos.add(AlunoChamada(id: user.uid, nome: nome, ra: ra));
          }
        }
      }

      // Adiciona os pré-cadastrados (sem ID real ainda)
      for (var pre in preCadastrados) {
         alunos.add(AlunoChamada(
           id: 'pre_${pre['email']}', 
           nome: pre['nome'],
           ra: 'Pendente', 
         ));
      }

      // Ordena alfabeticamente
      alunos.sort((a, b) => a.nome.compareTo(b.nome));
      
      return alunos;
    } catch (e) {
      debugPrint("Erro ao carregar alunos: $e");
      return [];
    }
  }

  // ===========================================================================
  // 3. HISTÓRICO DE CHAMADAS E PRESENÇA (CORRIGIDO)
  // ===========================================================================

  /// Retorna Stream com IDs das datas (ex: "2023-10-25") ordenadas
  Future<List<String>> getDatasChamadas(String turmaId) async {
    final query = await _db
        .collection('turmas')
        .doc(turmaId)
        .collection('aulas') 
        .orderBy('data', descending: true)
        .get();
    return query.docs.map((d) => d.id).toList();
  }

  /// Busca detalhes de uma chamada (quem estava presente)
  Future<Map<String, dynamic>> getDadosChamada(String turmaId, String dataId) async {
    try {
      final doc = await _db
          .collection('turmas')
          .doc(turmaId)
          .collection('aulas')
          .doc(dataId)
          .get();
      return doc.data() ?? {};
    } catch (e) {
      debugPrint("Erro ao buscar dados da chamada: $e");
      return {};
    }
  }
  /// Atualiza manualmente o histórico (Incluir/Excluir alunos)
  /// Aceita listas separadas para início e fim.
  Future<void> atualizarChamadaHistorico(
    String turmaId, 
    String dataId, 
    List<String> presentesInicio, 
    List<String> presentesFim
  ) async {
    try {
      await _db
          .collection('turmas')
          .doc(turmaId)
          .collection('aulas')
          .doc(dataId)
          .update({
            'presentes_inicio': presentesInicio,
            'presentes_fim': presentesFim, 
            'ultima_atualizacao': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint("Erro ao atualizar histórico: $e");
      throw Exception("Erro ao atualizar histórico.");
    }
  }

  /// Salva a presença automática via NFC
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

  // ===========================================================================
  // 4. STREAMS E OUTROS MÉTODOS DO APP
  // ===========================================================================
  
  Stream<List<TurmaProfessor>> getTurmasProfessor(String professorUid) {
    return _db
        .collection('turmas')
        .where('professorId', isEqualTo: professorUid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TurmaProfessor.fromMap(doc.data()!, doc.id))
            .toList());
  }

  // Para o Professor ver solicitações
  Stream<List<SolicitacaoAluno>> getSolicitacoesProfessor(String professorUid) {
    return _db
        .collection('solicitacoes')
        .where('professorId', isEqualTo: professorUid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SolicitacaoAluno.fromMap(doc.data()!, doc.id))
            .toList());
  }

  // Para o Aluno filtrar as dele (Stream global)
  Stream<List<SolicitacaoAluno>> getTodasSolicitacoesStream() {
    return _db
        .collection('solicitacoes')
        .orderBy('data', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SolicitacaoAluno.fromMap(doc.data()!, doc.id))
            .toList());
  }

  Stream<List<SolicitacaoAluno>> getSolicitacoes(String professorUid) {
    return getSolicitacoesProfessor(professorUid);
  }
  
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
  
  // --- MÉTODOS DE PROVAS ---

  Stream<List<ProvaAgendada>> getTodasProvas() { // Para o Calendário
    return _db
        .collection('provas') 
        .orderBy('dataHora', descending: false) 
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProvaAgendada.fromMap(doc.data()!, doc.id))
            .toList());
  }

  Stream<List<ProvaAgendada>> getCalendarioDeProvas() { // Mantido
    return getTodasProvas();
  }
  
  // ===========================================================================
  // 5. HUB DA DISCIPLINA (Chat, Materiais, Dicas)
  // ===========================================================================

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
  
  Stream<List<MaterialAula>> getMateriaisPorNomeBase(String nomeBase) {
    return _db
        .collectionGroup('materiais') 
        .where('nomeBaseDisciplina', isEqualTo: nomeBase) 
        .orderBy('dataPostagem', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaterialAula.fromMap(doc.data()!, doc.id))
            .toList());
  }

  Stream<List<MaterialAula>> getTodosMateriaisTipoProva() {
    return _db.collectionGroup('materiais')
        .where('tipo', isEqualTo: 'prova') 
        .orderBy('dataPostagem', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => MaterialAula.fromMap(d.data(), d.id)).toList());
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
  
  Stream<List<DicaAluno>> getStreamDicas(String turmaId) {
    return _db
        .collection('turmas')
        .doc(turmaId)
        .collection('dicas')
        .orderBy('dataPostagem', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DicaAluno.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<DicaAluno>> getDicasPorNomeBase(String nomeBase) {
    return _db
        .collectionGroup('dicas') 
        .where('nomeBaseDisciplina', isEqualTo: nomeBase)
        .orderBy('dataPostagem', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DicaAluno.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<DicaAluno>> getTodasDicasGlobais() {
    return _db.collectionGroup('dicas')
        .orderBy('dataPostagem', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => DicaAluno.fromMap(d.data(), d.id)).toList());
  }

  Future<void> adicionarDica(String turmaId, DicaAluno dica) async {
    await _db
        .collection('turmas')
        .doc(turmaId)
        .collection('dicas')
        .add(dica.toMap());
  }

  Future<void> adicionarDicaComunidade(DicaAluno dica) async {
    await _db.collection('dicas').add(dica.toMap());
  }

  // ===========================================================================
  // 6. DRIVE E OUTROS (CSV, GESTÃO)
  // ===========================================================================

  Stream<List<PastaDrive>> getPastasDrive({String? parentId}) {
    return _db.collection('drive_pastas')
        .where('parentId', isEqualTo: parentId)
        .orderBy('nome')
        .snapshots()
        .map((s) => s.docs.map((d) => PastaDrive.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<MaterialAula>> getArquivosDrive(String pastaId) {
    return _db.collection('drive_arquivos')
        .where('nomeBaseDisciplina', isEqualTo: pastaId) 
        .orderBy('dataPostagem', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => MaterialAula.fromMap(d.data(), d.id)).toList());
  }

  Future<void> criarPastaDrive(String nome, String? parentId, String autorUid) async {
    await _db.collection('drive_pastas').add({
      'nome': nome,
      'parentId': parentId,
      'criadoPor': autorUid,
      'dataCriacao': FieldValue.serverTimestamp(),
    });
  }

  Future<void> uploadArquivoDrive(MaterialAula arquivo, String pastaId) async {
    final data = arquivo.toMap();
    data['nomeBaseDisciplina'] = pastaId;
    await _db.collection('drive_arquivos').add(data);
  }

  Future<void> enviarSugestao(String texto, String autorId) async {
    await _db.collection('sugestoes').add({
      'texto': texto,
      'autorId': autorId,
      'data': FieldValue.serverTimestamp(),
    });
  }

  // --- IMPORTAR ALUNOS VIA CSV ---
  Future<Map<String, int>> importarAlunosCSV(String turmaId, File arquivoCsv) async {
    final input = await arquivoCsv.readAsString();
    List<List<dynamic>> rows = const CsvToListConverter().convert(input);

    final turmaDocRef = _db.collection('turmas').doc(turmaId);
    
    int adicionadosComConta = 0;
    int adicionadosSemConta = 0;

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(turmaDocRef);
      if (!snapshot.exists) throw Exception("Turma não encontrada!");

      List<String> inscritosAtuais = List<String>.from(snapshot.data()!['alunosInscritos'] ?? []);
      List<Map<String, dynamic>> preCadastradosAtuais = List<Map<String, dynamic>>.from(snapshot.data()!['alunosPreCadastrados'] ?? []);

      for (var row in rows) {
        if (row.length < 2 || !row[1].toString().contains('@')) continue;

        String nome = row[0].toString().trim();
        String email = row[1].toString().trim();

        final userQuery = await _db.collection('usuarios').where('email', isEqualTo: email).limit(1).get();

        if (userQuery.docs.isNotEmpty) {
          String uid = userQuery.docs.first.id;
          if (!inscritosAtuais.contains(uid)) {
            inscritosAtuais.add(uid);
            adicionadosComConta++;
          }
        } else {
          bool jaExiste = preCadastradosAtuais.any((e) => e['email'] == email);
          if (!jaExiste) {
            preCadastradosAtuais.add({'nome': nome, 'email': email});
            adicionadosSemConta++;
          }
        }
      }

      transaction.update(turmaDocRef, {
        'alunosInscritos': inscritosAtuais,
        'alunosPreCadastrados': preCadastradosAtuais,
      });
    });

    return {'comConta': adicionadosComConta, 'semConta': adicionadosSemConta};
  }

  // --- COMPARTILHAR PLANILHA DE PRESENÇAS ---
  Future<void> compartilharPlanilhaTurma(String turmaId, String nomeDisciplina) async {
    try {
      // 1. Buscar Alunos (já ordenados)
      final alunosRefs = await getAlunosDaTurma(turmaId); 
      
      // 2. Buscar Histórico de Chamadas (Datas)
      final snapshot = await _db
          .collection('turmas')
          .doc(turmaId)
          .collection('aulas')
          .orderBy('data', descending: false)
          .get();

      List<List<dynamic>> rows = [];
      List<dynamic> header = ["Aluno / Data"];
      List<String> datasHeaders = [];
      Map<String, Set<String>> mapaPresencas = {};

      for (var doc in snapshot.docs) {
        final dataMap = doc.data();
        final timestamp = dataMap['data'] as Timestamp;
        final dateStr = DateFormat('dd/MM').format(timestamp.toDate());
        
        String headerDate = dateStr;
        int count = 1;
        while (datasHeaders.contains(headerDate)) {
          count++;
          headerDate = "$dateStr ($count)";
        }
        
        datasHeaders.add(headerDate);
        header.add(headerDate);

        final pInicio = List<String>.from(dataMap['presentes_inicio'] ?? []);
        final pFim = List<String>.from(dataMap['presentes_fim'] ?? []);
        mapaPresencas[headerDate] = {...pInicio, ...pFim};
      }
      
      header.add("Total Presencas");
      header.add("Total Faltas");
      rows.add(header);

      for (var aluno in alunosRefs) {
        List<dynamic> row = [];
        row.add(aluno.nome);

        int presencasCount = 0;
        int faltasCount = 0;

        for (var dataHeader in datasHeaders) {
          final presentesNesseDia = mapaPresencas[dataHeader] ?? {};
          
          if (presentesNesseDia.contains(aluno.id)) {
            row.add("P");
            presencasCount++;
          } else {
            row.add("F");
            faltasCount++;
          }
        }

        row.add(presencasCount);
        row.add(faltasCount);
        rows.add(row);
      }

      String csv = const ListToCsvConverter(fieldDelimiter: ';').convert(rows);
      
      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/Presenca_$nomeDisciplina.csv";
      final file = File(path);
      await file.writeAsBytes([0xEF, 0xBB, 0xBF] + csv.codeUnits);
      
      await Share.shareXFiles([XFile(path)], text: 'Planilha de Presença - $nomeDisciplina');

    } catch (e) {
      debugPrint("Erro ao gerar planilha: $e");
      throw Exception("Erro ao gerar planilha: $e");
    }
  }

  Future<void> atualizarSolicitacao(String solicitacaoId, StatusSolicitacao novoStatus, String resposta) async {
    await _db.collection('solicitacoes').doc(solicitacaoId).update({
      'status': novoStatus.name,
      'resposta': resposta,
    });
  }

  String _gerarCodigoAleatorio({int length = 6}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }
  
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
    dadosTurma['linkConvite'] = "academicconnect://entrar/$codigo";

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

  Future<void> adicionarSolicitacao(SolicitacaoAluno solicitacao) async {
    await _db.collection('solicitacoes').add(solicitacao.toMap());
  }
  
  Future<void> salvarPresencaEvento(String eventoId, List<String> presentesUids) async {
    final docRef = _db.collection('eventos').doc(eventoId);
    await docRef.update({
      'participantesPresentes': FieldValue.arrayUnion(presentesUids),
    });
  }

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

// --- Streams ---

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