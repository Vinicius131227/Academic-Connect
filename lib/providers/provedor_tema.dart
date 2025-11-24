import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../servico_preferencias.dart'; 

enum ModoSistemaTema { claro, escuro, sistema }

class NotificadorTema extends StateNotifier<ModoSistemaTema> {
  final ServicoPreferencias _servicoPreferencias;
  
  NotificadorTema(this._servicoPreferencias) 
    : super(_servicoPreferencias.carregarTema()); // Carrega o tema salvo

  void mudarTema(ModoSistemaTema novoTema) {
    if (state == novoTema) return;
    
    _servicoPreferencias.salvarTema(novoTema); // Salva a preferência
    state = novoTema;
  }
}

final provedorNotificadorTema =
    StateNotifierProvider<NotificadorTema, ModoSistemaTema>((ref) {
  final prefs = ref.watch(provedorPreferencias); 
  return NotificadorTema(prefs);
});

// Provedor para o Brightness
final provedorBrightness = Provider<ThemeMode>((ref) {
  final modoTema = ref.watch(provedorNotificadorTema);
  switch (modoTema) {
    case ModoSistemaTema.claro:
      return ThemeMode.light;
    case ModoSistemaTema.escuro:
      return ThemeMode.dark;
    case ModoSistemaTema.sistema:
      return ThemeMode.system;
  }
});