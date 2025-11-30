// lib/providers/provedor_onboarding.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/servico_preferencias.dart';

/// Gerencia o estado de visualização da tela de boas-vindas (Onboarding).
/// O estado é um [bool]: `true` se já viu, `false` se é a primeira vez.
class OnboardingNotifier extends StateNotifier<bool> {
  final ServicoPreferencias _prefs;

  /// Construtor: Inicializa lendo o valor salvo no disco.
  OnboardingNotifier(this._prefs) : super(_prefs.carregarStatusOnboarding());

  /// Marca o onboarding como concluído.
  /// Chamado quando o usuário clica em "Começar" ou "Pular".
  Future<void> completeOnboarding() async {
    // Salva permanentemente no dispositivo
    await _prefs.salvarOnboardingCompleto();
    // Atualiza o estado em memória para redirecionar o usuário
    state = true; 
  }
}

/// Provedor global para verificar se deve mostrar o Onboarding ou o Login.
final provedorOnboarding = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  final prefs = ref.watch(provedorPreferencias);
  return OnboardingNotifier(prefs);
});