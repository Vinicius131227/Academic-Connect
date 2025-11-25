// lib/providers/provedor_localizacao.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../servico_preferencias.dart';

class LocalizacaoNotifier extends StateNotifier<Locale> {
  final ServicoPreferencias _servicoPreferencias;
  
  // CORREÇÃO: Inicia com 'pt' se não houver salvo
  LocalizacaoNotifier(this._servicoPreferencias) 
    : super(Locale(_servicoPreferencias.carregarLingua() == '' ? 'pt' : _servicoPreferencias.carregarLingua())); 

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