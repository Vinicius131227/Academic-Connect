// lib/providers/provedor_onboarding.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../servico_preferencias.dart';

class OnboardingNotifier extends StateNotifier<bool> {
  final ServicoPreferencias _prefs;

  // Inicializa lendo do disco
  OnboardingNotifier(this._prefs) : super(_prefs.carregarStatusOnboarding());

  Future<void> completeOnboarding() async {
    await _prefs.salvarOnboardingCompleto();
    state = true; // Atualiza o estado para que o PortaoAutenticacao saiba
  }
}

final provedorOnboarding = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  final prefs = ref.watch(provedorPreferencias);
  return OnboardingNotifier(prefs);
});