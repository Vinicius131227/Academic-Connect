// lib/providers/provedor_tema.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/servico_preferencias.dart';

/// Opções de tema disponíveis no aplicativo.
enum ModoSistemaTema { 
  claro,   // Força modo claro (Light)
  escuro,  // Força modo escuro (Dark)
  sistema  // Segue a configuração do Android/iOS
}

/// Gerencia o tema visual do aplicativo e sua persistência.
class TemaNotifier extends StateNotifier<ModoSistemaTema> {
  final ServicoPreferencias _prefs;

  /// Construtor: Carrega o tema salvo anteriormente.
  TemaNotifier(this._prefs) : super(_prefs.carregarTema());

  /// Altera o modo de tema e salva a escolha.
  ///
  /// [novoModo]: O novo modo desejado (Claro, Escuro ou Sistema).
  void mudarTema(ModoSistemaTema novoModo) {
    state = novoModo; // Atualiza a UI instantaneamente
    _prefs.salvarTema(novoModo); // Persiste a escolha
  }
}

/// Provedor global que a `MaterialApp` escuta para trocar as cores do app.
final provedorNotificadorTema = StateNotifierProvider<TemaNotifier, ModoSistemaTema>((ref) {
  final prefs = ref.watch(provedorPreferencias);
  return TemaNotifier(prefs);
});