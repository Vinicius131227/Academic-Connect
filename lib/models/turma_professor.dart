// lib/models/turma_professor.dart

class TurmaProfessor {
  final String id;
  final String nome;
  final String horario;
  final String local;
  final String professorId;
  final String turmaCode;
  final int creditos;
  final List<String> alunosInscritos; 
  final List<Map<String, dynamic>> alunosPreCadastrados;
  final int diaSemana; // 1=Segunda, ..., 7=Domingo
  final String horaInicio; // Formato "HH:mm" (ex: "19:00")
  final String horaFim;    // Formato "HH:mm" (ex: "22:00")

  TurmaProfessor({
    required this.id,
    required this.nome,
    required this.horario,
    required this.local,
    required this.professorId,
    required this.turmaCode,
    required this.creditos,
    required this.alunosInscritos,
    this.alunosPreCadastrados = const [],
    // Valores padrão
    this.diaSemana = 1, 
    this.horaInicio = "00:00",
    this.horaFim = "23:59",
  });

  /// Verifica se AGORA é o momento da aula
  bool estaNoHorarioDeAula() {
    final agora = DateTime.now();
    
    // 1. Verifica Dia
    if (agora.weekday != diaSemana) return false;

    // 2. Converte para minutos para comparar
    int minutosAgora = agora.hour * 60 + agora.minute;
    
    int minutosInicio = _converterParaMinutos(horaInicio);
    int minutosFim = _converterParaMinutos(horaFim);

    // Margem de tolerância: Professor pode abrir 15min antes e 15min depois
    // CORRIGIDO AQUI: minutosAgora
    return minutosAgora >= (minutosInicio - 15) && minutosAgora <= (minutosFim + 15);
  }

  /// Verifica se a aula JÁ ACABOU hoje
  bool aulaJaAcabou() {
    final agora = DateTime.now();
    if (agora.weekday != diaSemana) return true; // Se não é hoje, tecnicamente "não é hora"

    int minutosAgora = agora.hour * 60 + agora.minute;
    int minutosFim = _converterParaMinutos(horaFim);

    // CORRIGIDO AQUI: minutosAgora
    return minutosAgora > minutosFim;
  }

  int _converterParaMinutos(String horarioHHMM) {
    try {
      final partes = horarioHHMM.split(':');
      return int.parse(partes[0]) * 60 + int.parse(partes[1]);
    } catch (e) {
      return 0;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'horario': horario,
      'local': local,
      'professorId': professorId,
      'turmaCode': turmaCode,
      'creditos': creditos,
      'alunosInscritos': alunosInscritos,
      'alunosPreCadastrados': alunosPreCadastrados,
      'diaSemana': diaSemana,
      'horaInicio': horaInicio,
      'horaFim': horaFim,
    };
  }

  factory TurmaProfessor.fromMap(Map<String, dynamic> map, String id) {
    return TurmaProfessor(
      id: id,
      nome: map['nome'] ?? '',
      horario: map['horario'] ?? '',
      local: map['local'] ?? '',
      professorId: map['professorId'] ?? '',
      turmaCode: map['turmaCode'] ?? '',
      creditos: map['creditos'] ?? 4,
      alunosInscritos: List<String>.from(map['alunosInscritos'] ?? []),
      alunosPreCadastrados: List<Map<String, dynamic>>.from(map['alunosPreCadastrados'] ?? []),
      diaSemana: map['diaSemana'] ?? 1,
      horaInicio: map['horaInicio'] ?? '00:00',
      horaFim: map['horaFim'] ?? '23:59',
    );
  }
}