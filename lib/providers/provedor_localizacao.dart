import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../servico_preferencias.dart';

class LocalizacaoNotifier extends StateNotifier<Locale> {
  final ServicoPreferencias _servicoPreferencias;
  
  LocalizacaoNotifier(this._servicoPreferencias) 
    : super(Locale(_servicoPreferencias.carregarLingua())); // Carrega a língua salva

  void mudarLingua(String codigoLingua) {
    if (state.languageCode == codigoLingua) return;
    
    _servicoPreferencias.salvarLingua(codigoLingua);
    state = Locale(codigoLingua);
  }
}

final provedorLocalizacao = StateNotifierProvider<LocalizacaoNotifier, Locale>((ref) {
  final prefs = ref.watch(provedorPreferencias);
  return LocalizacaoNotifier(prefs);
});