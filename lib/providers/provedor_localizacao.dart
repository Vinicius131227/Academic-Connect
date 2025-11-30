// lib/providers/provedor_localizacao.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/servico_preferencias.dart'; // Importa o serviço de persistência

/// Gerencia o estado do idioma atual do aplicativo (Internacionalização).
///
/// Utiliza o [StateNotifier] para permitir que a UI reconstrua automaticamente
/// quando o idioma for alterado.
class LocalizacaoNotifier extends StateNotifier<Locale> {
  final ServicoPreferencias _servicoPreferencias;
  
  /// Construtor: Carrega o idioma salvo ou define 'pt' (Português) como padrão.
  LocalizacaoNotifier(this._servicoPreferencias) 
    : super(Locale(_servicoPreferencias.carregarLingua() == '' ? 'pt' : _servicoPreferencias.carregarLingua())); 

  /// Altera o idioma atual e salva a preferência no armazenamento local.
  ///
  /// [codigoLingua]: O código do idioma (ex: 'pt', 'en', 'es').
  void mudarLingua(String codigoLingua) {
    // Se o idioma já for o atual, não faz nada
    if (state.languageCode == codigoLingua) return;
    
    // Salva no SharedPreferences
    _servicoPreferencias.salvarLingua(codigoLingua);
    
    // Atualiza o estado do app
    state = Locale(codigoLingua);
  }
}

/// Provedor global para acessar o estado de localização.
final provedorLocalizacao = StateNotifierProvider<LocalizacaoNotifier, Locale>((ref) {
  // Observa o serviço de preferências para garantir que foi inicializado
  final prefs = ref.watch(provedorPreferencias);
  return LocalizacaoNotifier(prefs);
});