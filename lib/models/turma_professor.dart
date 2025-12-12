class TurmaProfessor {
  final String id;
  final String nome;
  final String horario;
  final String local;
  final String professorId;
  final String turmaCode;
  final int creditos;
  final List<String> alunosInscritos; // UIDs de quem já tem conta
  
  // NOVO: Lista de mapas [{'nome': 'João', 'email': 'joao@email.com'}]
  final List<Map<String, dynamic>> alunosPreCadastrados; 

  TurmaProfessor({
    required this.id,
    required this.nome,
    required this.horario,
    required this.local,
    required this.professorId,
    required this.turmaCode,
    required this.creditos,
    required this.alunosInscritos,
    this.alunosPreCadastrados = const [], // Padrão vazio
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'horario': horario,
      'local': local,
      'professorId': professorId,
      'turmaCode': turmaCode,
      'creditos': creditos,
      'alunosInscritos': alunosInscritos,
      'alunosPreCadastrados': alunosPreCadastrados, // Salva no banco
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
      // Carrega a lista de pré-cadastrados
      alunosPreCadastrados: List<Map<String, dynamic>>.from(map['alunosPreCadastrados'] ?? []),
    );
  }
}