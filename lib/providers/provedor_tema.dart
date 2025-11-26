// lib/providers/provedor_tema.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../servico_preferencias.dart';

enum ModoSistemaTema { claro, escuro, sistema }

class TemaNotifier extends StateNotifier<ModoSistemaTema> {
  final ServicoPreferencias _prefs;

  // Inicializa já lendo do disco
  TemaNotifier(this._prefs) : super(_prefs.carregarTema());

  void mudarTema(ModoSistemaTema novoModo) {
    state = novoModo;
    _prefs.salvarTema(novoModo);
  }
}

final provedorNotificadorTema = StateNotifierProvider<TemaNotifier, ModoSistemaTema>((ref) {
  final prefs = ref.watch(provedorPreferencias);
  return TemaNotifier(prefs);
});