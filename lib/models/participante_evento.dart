/// Um modelo de *visualização* (View Model) usado apenas na tela
/// de registro de presença de evento (lib/telas/ca_projeto/tela_presenca_evento.dart).
/// **Este objeto não é salvo no Firebase.**
class ParticipanteEvento {
  final String id;
  final String nome;
  final String ra;
  final bool isPresente;

  ParticipanteEvento({
    required this.id,
    required this.nome,
    required this.ra,
    this.isPresente = false,
  });
}